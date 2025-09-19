import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gacha_item.dart';
import 'firebase_service.dart';

class GachaService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final Random _random = Random();

  final Map<String, List<GachaItem>> _rarityItems = {
    'common': [],
    'rare': [],
    'epic': [],
    'legendary': [],
  };

  List<GachaItem> _userItems = [];
  bool _isLoading = false;

  List<GachaItem> _availableItems = [];

  List<GachaItem> get userItems => _userItems;
  bool get isLoading => _isLoading;

  GachaService() {
    _initializeGachaItems();
  }

  // Initialize with buddy placeholders
  void _initializeGachaItems() {
    _rarityItems['common'] = [
      // Common buddies
      GachaItem(
        id: '1',
        name: 'Suki',
        description:
        'Utterly heartbroken his owners misspelled his name. Eats '
            'excessively in order to cope with the pain.',
        imageUrl: 'assets/images/pocket_watch.png',
        rarity: GachaRarity.common,
        species: 'Tabby cat',
      ),
      GachaItem(
        id: '2',
        name: 'Kurow',
        description:
        'She is a super intelligent, but lazy, RAVEN. Yes, her '
            'owners misclassified her. Cool name though.',
        imageUrl: 'assets/images/brass_compass.png',
        rarity: GachaRarity.common,
        species: 'Chihuahuan raven',
      ),
      GachaItem(
        id: '3',
        name: 'Little Bell',
        description:
        'Despite her name, she is actually huge! She is also a '
            'great hugger when she is cleaned.',
        imageUrl: 'assets/images/music_box.png',
        rarity: GachaRarity.common,
        species: 'Angora rabbit',
      ),
    ];

    // Rare antiques
    _rarityItems['rare'] = [
      GachaItem(
        id: '4',
        name: 'Queen',
        description:
        'Just to clarify, it is a male... He used to be a killer, '
            'but became a changed cat after losing a life. Now, he passes his '
            'days sleeping.',
        imageUrl: '',
        rarity: GachaRarity.rare,
        species: 'Sphynx cat',
      ),
      GachaItem(
        id: '5',
        name: 'Torri',
        description:
        'Well known in her community as \'Torri the Torrent\' for '
            'her rapid and destructive insults. Nobody knows this, but she '
            'is also a great cook!',
        imageUrl: 'assets/images/music_box.png',
        rarity: GachaRarity.rare,
        species: 'Eclectus parrot',
      ),
      GachaItem(
        id: '6',
        name: 'Ultimate Supreme Annihilation',
        description:
        'Holds parties every night in his nest, though they always '
            'end up badly due to his short temper. He is also addicted to Diet '
            '"Bird" Coke.',
        imageUrl: '',
        rarity: GachaRarity.rare,
        species: 'Bald eagle',
      ),
    ];

    // Epic antiques
    _rarityItems['epic'] = [
      GachaItem(
        id: '7',
        name: 'Love Dream',
        description:
        'He is very much in love. Secretly takes dance classes in '
            'hopes of attract his crush one day.',
        imageUrl: '',
        rarity: GachaRarity.epic,
        species: 'American flamingo',
      ),
      GachaItem(
        id: '8',
        name: 'Moonlight',
        description:
        'A social recluse. He doesn\'t like humans because they '
            'don\'t taste good... and also because they have guns...',
        imageUrl: '',
        rarity: GachaRarity.epic,
        species: 'Grey wolf',
      ),
    ];

    // Legendary antiques
    _rarityItems['legendary'] = [
      GachaItem(
        id: '9',
        name: 'Winter Wind',
        description:
        'She is the princess of the snow, wielding a bone-chilling '
            'gaze and an ice-cold demeanor. She is totally not just awkward!',
        imageUrl: '',
        rarity: GachaRarity.legendary,
        species: 'Arctic fox',
      ),
      GachaItem(
        id: '10',
        name: 'Big Brother',
        description:
        'Perched on the highest branch in the darkest night, he '
            'analyzes everything with utmost clarity. Hunts multiple times every '
            'night for his 7 baby siblings.',
        imageUrl: '',
        rarity: GachaRarity.legendary,
        species: 'Great horned owl',
      ),
    ];
    _availableItems =
        _rarityItems['common']! +
            _rarityItems['rare']! +
            _rarityItems['epic']! +
            _rarityItems['legendary']!;
  }

  // Perform a single gacha pull (free)
  Future<GachaItem?> performSinglePull() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) {
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Perform gacha roll
      final item = _rollGacha();

      if (item != null) {
        await _addItemToUser(item);
      }

      _isLoading = false;
      notifyListeners();
      return item;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Perform a 10-pull (free)
  Future<List<GachaItem>> performMultiPull() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return [];

    _isLoading = true;
    notifyListeners();

    try {
      final items = <GachaItem>[];
      final futures = <Future>[];

      for (int i = 0; i < 10; i++) {
        final item = _rollGacha();
        if (item != null) {
          items.add(item);
          futures.add(_addItemToUser(item)); // collect the future
        }
      }

      // Wait for all Firestore writes to complete at once
      await Future.wait(futures);

      _isLoading = false;
      notifyListeners();
      return items;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Roll gacha based on rarity rates
  GachaItem? _rollGacha() {
    final roll = _random.nextDouble();
    double cumulativeRate = 0.0;

    final sortedItems = List<GachaItem>.from(_availableItems);
    sortedItems.sort((a, b) => b.dropRate.compareTo(a.dropRate));

    print(_availableItems);
    for (final item in _availableItems) {
      cumulativeRate +=
          item.dropRate / _rarityItems[item.rarityDisplayName]!.length;
      if (roll <= cumulativeRate) {
        return item;
      }
    }

    // Fallback to first common item
    return _availableItems.firstWhere(
          (item) => item.rarity == GachaRarity.common,
      orElse: () => _availableItems.first,
    );
  }

  // Add item to user's collection
  Future<void> _addItemToUser(GachaItem item) async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    final ownedItem = item.copyWith(isOwned: true, obtainedAt: DateTime.now());

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gacha_items')
        .doc(item.id)
        .set(ownedItem.toMap());

    // Update local list
    final existingIndex = _userItems.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _userItems[existingIndex] = ownedItem;
    } else {
      _userItems.add(ownedItem);
    }
  }

  // Load user's gacha items
  Future<void> loadUserItems() async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return;

    try {
      final snapshot =
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gacha_items')
          .get();

      _userItems =
          snapshot.docs
              .map((doc) => GachaItem.fromMap(doc.data(), doc.id))
              .toList();

      notifyListeners();
    } catch (e) {
      print('Error loading user gacha items: $e');
    }
  }

  // Check if user can pull (always true since it's free)
  bool canAffordSinglePull() {
    final user = FirebaseService.auth.currentUser;
    return user != null;
  }

  bool canAffordMultiPull() {
    final user = FirebaseService.auth.currentUser;
    return user != null;
  }

  // Get items by rarity
  List<GachaItem> getItemsByRarity(GachaRarity rarity) {
    return _userItems.where((item) => item.rarity == rarity).toList();
  }
}