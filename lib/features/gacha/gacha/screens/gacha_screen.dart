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
                  Text(
                    'You got!',
                    style: AppTextStyles.heading2,
                  ),
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
            Navigator.pop(context);
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
            Navigator.pop(context);
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
            // Simple banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text('🎲', style: TextStyle(fontSize: 48.sp)),
                  SizedBox(height: 12.h),
                  Text('Collect Buddies', style: AppTextStyles.heading3),
                  SizedBox(height: 4.h),
                  Text(
                    'Pull to get companions',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // View Available Buddies Button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DropRatesScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'View Available Buddies',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Single Pull Button
            GestureDetector(
              onTap: _isPulling ? null : _handleSinglePull,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 28.sp, color: Colors.white),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Single Pull',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '0 Coins',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // 6 Pull Button
            GestureDetector(
              onTap: _isPulling ? null : _handleSixPull,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, size: 28.sp, color: Colors.white),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '6x Pull',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '0 Coins',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
