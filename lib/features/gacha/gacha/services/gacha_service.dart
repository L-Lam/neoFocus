import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../buddy/models/buddy.dart';
import '../../buddy/data/buddies_data.dart';

class GachaService {
  static final _random = Random();

  // Pull rates
  static const double commonRate = 0.65;
  static const double rareRate = 0.25;
  static const double epicRate = 0.08;
  static const double legendaryRate = 0.02;

  // Coin refunds (0 for now, can be changed later)
  static const int commonRefund = 0;
  static const int rareRefund = 0;

  // Single pull
  static Future<Buddy> singlePull() async {
    final buddy = _performPull();
    await _addToInventory(buddy);
    return buddy;
  }

  // 6 pull
  static Future<List<Buddy>> sixPull() async {
    final List<Buddy> results = [];
    for (int i = 0; i < 6; i++) {
      final buddy = _performPull();
      results.add(buddy);
      await _addToInventory(buddy);
    }
    return results;
  }

  // Perform a single pull based on rates
  static Buddy _performPull() {
    final roll = _random.nextDouble();

    BuddyRarity rarity;
    if (roll < legendaryRate) {
      rarity = BuddyRarity.legendary;
    } else if (roll < legendaryRate + epicRate) {
      rarity = BuddyRarity.epic;
    } else if (roll < legendaryRate + epicRate + rareRate) {
      rarity = BuddyRarity.rare;
    } else {
      rarity = BuddyRarity.common;
    }

    // Get all buddies of this rarity
    final buddiesOfRarity =
        allBuddies.where((b) => b.rarity == rarity).toList();

    // Pick a random one
    final buddy = buddiesOfRarity[_random.nextInt(buddiesOfRarity.length)];

    // Generate aura points based on rarity
    final auraPoints = _generateAuraPoints(rarity);

    // Return buddy with aura points
    return buddy.copyWith(auraPoints: auraPoints);
  }

  // Generate random aura points based on rarity (only Epic and Legendary)
  static int _generateAuraPoints(BuddyRarity rarity) {
    switch (rarity) {
      case BuddyRarity.common:
        return _random.nextInt(101);
      case BuddyRarity.rare:
        return _random.nextInt(501);
      case BuddyRarity.epic:
        return _random.nextInt(2001);
      case BuddyRarity.legendary:
        return _random.nextInt(10001);
    }
  }

  // Add buddy to user's inventory (update aura if duplicate)
  static Future<void> _addToInventory(Buddy buddy) async {
    final userDoc = FirebaseService.currentUserDoc;
    if (userDoc == null) return;

    // Check if buddy already exists in inventory
    final existingBuddy =
        await userDoc
            .collection('inventory')
            .where('id', isEqualTo: buddy.id)
            .limit(1)
            .get();

    if (existingBuddy.docs.isEmpty) {
      // First time getting this buddy
      await userDoc.collection('inventory').add({
        ...buddy.toJson(),
        'pulledAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Buddy already exists - update aura points
      final doc = existingBuddy.docs.first;
      final existingData = doc.data();
      final existingBuddyObj = Buddy.fromJson(existingData);

      final aura =
          existingBuddyObj.auraPoints > buddy.auraPoints
              ? existingBuddyObj.auraPoints
              : buddy.auraPoints;

      await doc.reference.update({'auraPoints': aura});
    }
  }

  // Get user's inventory (sorted common to legendary)
  static Stream<List<Buddy>> getInventory() {
    final userDoc = FirebaseService.currentUserDoc;
    if (userDoc == null) {
      return Stream.value([]);
    }

    return userDoc.collection('inventory').snapshots().map((snapshot) {
      final buddies =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Buddy.fromJson(data);
          }).toList();

      // Sort by ID (handle both numeric and old string IDs)
      buddies.sort((a, b) {
        final aId = int.tryParse(a.id) ?? 999;
        final bId = int.tryParse(b.id) ?? 999;
        return aId.compareTo(bId);
      });
      return buddies;
    });
  }

  // Get coin refund for a buddy
  static int getRefund(Buddy buddy) {
    switch (buddy.rarity) {
      case BuddyRarity.common:
        return commonRefund;
      case BuddyRarity.rare:
        return rareRefund;
      case BuddyRarity.epic:
      case BuddyRarity.legendary:
        return 0;
    }
  }
}
