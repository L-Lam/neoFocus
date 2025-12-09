import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../buddy/models/buddy.dart';
import '../../buddy/data/buddies_data.dart';
import '../../buddy/widgets/buddy_card_widget.dart';
import '../../buddy/screens/buddy_detail_screen.dart';
import '../services/gacha_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Buddy? _featuredBuddy;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedBuddy();
  }

  Future<void> _loadFeaturedBuddy() async {
    setState(() => _isLoading = true);

    final todayUtc = DateTime.now().toUtc();
    final dateStr =
        '${todayUtc.year}-${todayUtc.month.toString().padLeft(2, '0')}-${todayUtc.day.toString().padLeft(2, '0')}';

    try {
      final docRef = FirebaseService.firestore
          .collection('app_data')
          .doc('featured_buddy');
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        final savedDate = data['date'] as String?;
        final savedBuddyId = data['buddyId'] as String?;

        // Check if we have a saved buddy for today (UTC)
        if (savedDate == dateStr && savedBuddyId != null) {
          try {
            final buddy = allBuddies.firstWhere((b) => b.id == savedBuddyId);
            setState(() {
              _featuredBuddy = buddy;
              _isLoading = false;
            });
            return;
          } catch (e) {
            print('Buddy with id $savedBuddyId not found, regenerating');
          }
        }
      }

      // Generate new featured buddy for today (UTC)
      await _generateFeaturedBuddy(dateStr);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateFeaturedBuddy(String dateStr) async {
    // Get epic and legendary buddies that are available in shop
    final exoticBuddies =
        allBuddies
            .where(
              (b) =>
                  b.rarity == BuddyRarity.exotic &&
                  b.source.contains(BuddySource.shop),
            )
            .toList();
    final uniqueBuddies =
        allBuddies
            .where(
              (b) =>
                  b.rarity == BuddyRarity.unique &&
                  b.source.contains(BuddySource.shop),
            )
            .toList();

    // Create weighted list (epics appear twice as often)
    final weightedList = <Buddy>[
      ...exoticBuddies,
      ...exoticBuddies, // Add epics twice for double weight
      ...uniqueBuddies,
    ];

    if (weightedList.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Select random buddy using date as seed for consistency
    final dateSeed = dateStr.hashCode;
    final selectedBuddy = weightedList[dateSeed.abs() % weightedList.length];

    // Save to Firestore (update the single document)
    final docRef = FirebaseService.firestore
        .collection('app_data')
        .doc('featured_buddy');
    await docRef.set({
      'date': dateStr,
      'buddyId': selectedBuddy.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _featuredBuddy = selectedBuddy;
      _isLoading = false;
    });
  }

  Future<void> _purchaseBuddy(Buddy buddy, int cost) async {
    final userDoc = FirebaseService.currentUserDoc;
    if (userDoc == null) {
      _showMessage('Please log in to purchase');
      return;
    }

    try {
      // Check if user has enough coins
      final userSnapshot = await userDoc.get();
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final currentCoins = userData?['coins'] ?? 0;

      if (currentCoins < cost) {
        _showMessage('Not enough coins! You need $cost coins.');
        return;
      }

      // Deduct coins first
      await userDoc.update({'coins': FieldValue.increment(-cost)});

      // Generate new aura points and add to inventory
      final newAuraPoints = GachaService.generateAuraPoints(buddy.rarity);
      final buddyWithAura = buddy.copyWith(auraPoints: newAuraPoints);

      // Use the shared method to add/update buddy
      await GachaService.addBuddyToInventory(buddyWithAura);

      // Show purchase result popup
      if (mounted) {
        _showPurchaseResult(buddyWithAura);
      }
    } catch (e) {
      _showMessage('Purchase failed: $e');
    }
  }

  void _showPurchaseResult(Buddy buddy) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Purchased!', style: AppTextStyles.heading2),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: 200.w,
                    height: 250.h,
                    child: Center(
                      child: BuddyCardWidget(
                        buddy: buddy,
                        isUnlocked: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuddyDetailScreen(buddy: buddy),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  int _getBuddyCost(Buddy buddy) {
    switch (buddy.rarity) {
      case BuddyRarity.common:
        return 0;
      case BuddyRarity.rare:
        return 1000;
      case BuddyRarity.exotic:
        return 5000;
      case BuddyRarity.unique:
        return 20000;
    }
  }

  @override
  Widget build(BuildContext context) {
    final commonBuddies =
        allBuddies
            .where(
              (b) =>
                  b.rarity == BuddyRarity.common &&
                  b.source.contains(BuddySource.shop),
            )
            .toList();
    final rareBuddies =
        allBuddies
            .where(
              (b) =>
                  b.rarity == BuddyRarity.rare &&
                  b.source.contains(BuddySource.shop),
            )
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Buddy Store', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Common Buddies Section
            Text('Common Buddies', style: AppTextStyles.heading3),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.65,
              ),
              itemCount: commonBuddies.length,
              itemBuilder: (context, index) {
                return _buildBuddyCard(commonBuddies[index]);
              },
            ),

            SizedBox(height: 32.h),

            // Rare Buddies Section
            Text('Rare Buddies', style: AppTextStyles.heading3),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.65,
              ),
              itemCount: rareBuddies.length,
              itemBuilder: (context, index) {
                return _buildBuddyCard(rareBuddies[index]);
              },
            ),

            SizedBox(height: 32.h),

            // Featured Buddy Section (at bottom)
            Row(
              children: [
                Text('Featured Buddy For Today', style: AppTextStyles.heading3),
                SizedBox(width: 8.w),
                if (_featuredBuddy != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40.h),
                  child: const CircularProgressIndicator(),
                ),
              )
            else if (_featuredBuddy != null)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.65,
                ),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return _buildBuddyCard(_featuredBuddy!);
                },
              )
            else
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20.h),
                  child: Text(
                    'No featured buddy today',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddyCard(Buddy buddy) {
    final cost = _getBuddyCost(buddy);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (context) => Dialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 250.h,
                        child: BuddyCardWidget(buddy: buddy, isUnlocked: true),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        buddy.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _purchaseBuddy(buddy, cost);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buddy.getRarityColor(),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.defaultRadius,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Buy $cost',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: BuddyCardWidget(
              buddy: buddy,
              isUnlocked: true,
              onTap: () {
                // Tap handled by GestureDetector above
              },
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$cost Coins',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 4.w),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
