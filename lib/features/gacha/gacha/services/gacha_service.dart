import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../buddy/models/buddy.dart';
import '../../buddy/data/buddies_data.dart';

class GachaService {
  static final _random = Random();

  // Pull rates
  static const double commonRate = 0.645;
  static const double rareRate = 0.13;
  static const double exoticRate = 0.02;
  static const double uniqueRate = 0.005;

  // Coin refunds (0 for now, can be changed later)
  static const int commonRefund = 0;
  static const int rareRefund = 0;

  // Costs
  static const int singlePullCost = 100;
  static const int sixPullCost = 600;

  // Pity system
  static const int legendaryPityCount = 72;

  // Single pull
  static Future<Buddy> singlePull() async {
    final userDoc = FirebaseService.currentUserDoc;
    if (userDoc == null) throw Exception('User not logged in');

    // Check coins
    final userSnapshot = await userDoc.get();
    final userData = userSnapshot.data() as Map<String, dynamic>?;
    final currentCoins = userData?['coins'] ?? 0;

    if (currentCoins < singlePullCost) {
      throw Exception('Not enough coins! You need $singlePullCost coins.');
    }

    // Get pity counter
    final pityCounter = userData?['gachaPityCounter'] ?? 0;

    // Deduct coins
    await userDoc.update({'coins': FieldValue.increment(-singlePullCost)});

    // Perform pull (without aura - will be rolled in addBuddyToInventory)
    final buddy = await _performPullWithPity(pityCounter);
    await addBuddyToInventory(buddy);

    // Update pity counter
    if (buddy.rarity == BuddyRarity.exotic) {
      await userDoc.update({'gachaPityCounter': 0});
    } else {
      await userDoc.update({'gachaPityCounter': pityCounter + 1});
    }

    return buddy;
  }

  // 6 pull
  static Future<List<Buddy>> sixPull() async {
    final userDoc = FirebaseService.currentUserDoc;
    if (userDoc == null) throw Exception('User not logged in');

    // Check coins
    final userSnapshot = await userDoc.get();
    final userData = userSnapshot.data() as Map<String, dynamic>?;
    final currentCoins = userData?['coins'] ?? 0;

    if (currentCoins < sixPullCost) {
      throw Exception('Not enough coins! You need $sixPullCost coins.');
    }

    // Get pity counter
    int pityCounter = userData?['gachaPityCounter'] ?? 0;

    // Deduct coins
    await userDoc.update({'coins': FieldValue.increment(-sixPullCost)});

    final List<Buddy> results = [];
    for (int i = 0; i < 6; i++) {
      // Perform pull (without aura - will be rolled in addBuddyToInventory)
      final buddy = await _performPullWithPity(pityCounter);
      results.add(buddy);
      await addBuddyToInventory(buddy);

      // Update pity counter
      if (buddy.rarity == BuddyRarity.exotic ||
          buddy.rarity == BuddyRarity.unique) {
        pityCounter = 0;
      } else {
        pityCounter++;
      }
    }

    // Save final pity counter
    await userDoc.update({'gachaPityCounter': pityCounter});

    return results;
  }

  // Perform a single pull with pity system
  static Future<Buddy> _performPullWithPity(int pityCounter) async {
    BuddyRarity rarity;

    // Check if pity triggers (70 pulls without legendary)
    if (pityCounter >= legendaryPityCount - 1) {
      rarity = BuddyRarity.exotic;
    } else {
      // Normal pull rates
      final roll = _random.nextDouble();

      if (roll < uniqueRate) {
        rarity = BuddyRarity.unique;
      } else if (roll < uniqueRate + exoticRate) {
        rarity = BuddyRarity.exotic;
      } else if (roll < uniqueRate + exoticRate + rareRate) {
        rarity = BuddyRarity.rare;
      } else {
        rarity = BuddyRarity.common;
      }
    }

    final buddiesOfRarity =
        allBuddies
            .where(
              (b) =>
                  b.rarity == rarity && b.source.contains(BuddySource.gacha),
            )
            .toList();

    final buddy = buddiesOfRarity[_random.nextInt(buddiesOfRarity.length)];

    final auraPoints = generateAuraPoints(rarity);

    return buddy.copyWith(auraPoints: auraPoints);
  }

  // Get current pity counter
  static Future<int> getPityCounter() async {
    final userDoc = FirebaseService.currentUserDoc;
    if (userDoc == null) return 0;

    final snapshot = await userDoc.get();
    final userData = snapshot.data() as Map<String, dynamic>?;
    return userData?['gachaPityCounter'] ?? 0;
  }

  // Generate random aura points based on rarity
  static int generateAuraPoints(BuddyRarity rarity) {
    switch (rarity) {
      case BuddyRarity.exotic || BuddyRarity.unique:
        return _random.nextInt(10001);
      default:
        return _random.nextInt(1001);
    }
  }

  // CORE METHOD: Add buddy to inventory (used by both gacha and store)
  // Handles new buddies and aura rerolls for duplicates
  static Future<void> addBuddyToInventory(Buddy buddy) async {
    final userDoc = FirebaseService.currentUserDoc;
    if (userDoc == null) return;

    try {
      final existingBuddy =
          await userDoc
              .collection('inventory')
              .where('id', isEqualTo: buddy.id)
              .limit(1)
              .get();

      if (existingBuddy.docs.isEmpty) {
        await userDoc.collection('inventory').add({
          ...buddy.toJson(),
          'acquiredAt': FieldValue.serverTimestamp(),
          'duplicateCount': 1,
        });
        return;
      }

      // Buddy already exists - increment duplicate count
      final currentData = existingBuddy.docs.first.data();
      final currentAura = currentData['auraPoints'] as int;
      final currentDuplicates = currentData['duplicateCount'] as int? ?? 1;
      final newAura = generateAuraPoints(buddy.rarity);

      final updates = <String, dynamic>{
        'duplicateCount': currentDuplicates + 1,
      };

      if (newAura > currentAura) {
        updates['auraPoints'] = newAura;

        // Update total aura points
        final auraDiff = newAura - currentAura;
        await userDoc.update({
          'totalAuraPoints': FieldValue.increment(auraDiff),
        });
      }

      await existingBuddy.docs.first.reference.update(updates);
    } catch (e) {
      //
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
      case BuddyRarity.exotic:
      case BuddyRarity.unique:
        return 0;
    }
  }
}
