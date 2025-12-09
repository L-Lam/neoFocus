import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../services/gacha_service.dart';
import '../../buddy/models/buddy.dart';
import '../../buddy/widgets/buddy_card_widget.dart';
import '../../buddy/screens/inventory_screen.dart';
import '../../buddy/screens/buddy_detail_screen.dart';
import 'droprates_screen.dart';
import 'store_screen.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  bool _isPulling = false;

  Future<void> _handleSinglePull() async {
    if (_isPulling) return;

    setState(() => _isPulling = true);

    try {
      final buddy = await GachaService.singlePull();
      if (mounted) {
        _showPullResult([buddy]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPulling = false);
      }
    }
  }

  Future<void> _handleSixPull() async {
    if (_isPulling) return;

    setState(() => _isPulling = true);

    try {
      final buddies = await GachaService.sixPull();
      if (mounted) {
        _showPullResult(buddies);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPulling = false);
      }
    }
  }

  void _showPullResult(List<Buddy> buddies) {
    // Calculate total refund
    int totalRefund = 0;
    for (var buddy in buddies) {
      totalRefund += GachaService.getRefund(buddy);
    }

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
                  Text('You got!', style: AppTextStyles.heading2),
                  ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '💰 +$totalRefund coins refunded',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: buddies.length == 1 ? 200.w : 400.w,
                    height: buddies.length == 1 ? 250.h : 430.h,
                    child:
                        buddies.length == 1
                            ? _buildSingleResult(buddies.first)
                            : _buildMultipleResults(buddies),
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

  Widget _buildSingleResult(Buddy buddy) {
    return Center(
      child: SizedBox(
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
    );
  }

  Widget _buildMultipleResults(List<Buddy> buddies) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.75,
      ),
      itemCount: buddies.length,
      itemBuilder: (context, index) {
        final buddy = buddies[index];
        return BuddyCardWidget(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Buddy Gacha', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DropRatesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Pity Counter Bar
            FutureBuilder<int>(
              future: GachaService.getPityCounter(),
              builder: (context, snapshot) {
                final pityCounter = snapshot.data ?? 0;
                final progress = pityCounter / 72.0;

                return Container(
                  padding: EdgeInsets.all(16.w),
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultRadius,
                    ),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '✨ Legendary Pity',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$pityCounter / 72',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.warning,
                        ),
                        minHeight: 8.h,
                      ),
                    ],
                  ),
                );
              },
            ),
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/legacy/GachaBanner.png',
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20.h),
            // Pull Buttons Row
            Row(
              children: [
                // Single Pull Button
                Expanded(
                  child: GestureDetector(
                    onTap: _isPulling ? null : _handleSinglePull,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: _isPulling ? Colors.grey : AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                        boxShadow:
                            _isPulling
                                ? []
                                : [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.star, size: 28.sp, color: Colors.white),
                          SizedBox(height: 8.h),
                          Text(
                            '1x Search',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '100 Coins',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // 6 Pull Button
                Expanded(
                  child: GestureDetector(
                    onTap: _isPulling ? null : _handleSixPull,
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: _isPulling ? Colors.grey : AppColors.warning,
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                        boxShadow:
                            _isPulling
                                ? []
                                : [
                                  BoxShadow(
                                    color: AppColors.warning.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 28.sp,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '6x Search',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '600 Coins',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isPulling) ...[
              SizedBox(height: 20.h),
              const CircularProgressIndicator(),
              SizedBox(height: 8.h),
              Text(
                'Pulling...',
                style: AppTextStyles.body.copyWith(color: AppColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
