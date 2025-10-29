import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/buddy.dart';

class BuddyDetailScreen extends StatelessWidget {
  final Buddy buddy;

  const BuddyDetailScreen({super.key, required this.buddy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(buddy.name, style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Buddy Image
            Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    buddy.getRarityColor().withValues(alpha: 0.3),
                    buddy.getRarityColor().withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: buddy.getRarityColor(), width: 3),
              ),
              child: Center(child: Image.asset(buddy.image)),
            ),
            SizedBox(height: 24.h),

            // Name
            Text(
              buddy.name,
              style: AppTextStyles.heading1,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            // Rarity Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: buddy.getRarityColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: buddy.getRarityColor(), width: 2),
              ),
              child: Text(
                buddy.rarity.name.toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: buddy.getRarityColor(),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Species
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Species', style: AppTextStyles.bodySmall.copyWith()),
                  SizedBox(height: 4.h),
                  Text(buddy.species, style: AppTextStyles.body.copyWith()),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Description
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: AppTextStyles.bodySmall.copyWith(),
                  ),
                  SizedBox(height: 8.h),
                  Text(buddy.description, style: AppTextStyles.body),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aura Points: ',
                        style: AppTextStyles.bodySmall.copyWith(),
                      ),
                      Text(
                        '${buddy.auraPoints}/${buddy.getMaxPossibleAura()}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: buddy.getRarityColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Finding the same buddy again has a chance to increase '
                    'this score.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuraStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
