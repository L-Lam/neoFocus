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
              clipBehavior: Clip.hardEdge,
              child: Transform.translate(
                offset: const Offset(0, 25),
                child: Image.asset(
                  buddy.image,
                  fit: BoxFit.contain,
                  height: 480.w,
                ),
              ),
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

            // Where to Find
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
                    'Where to Find',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      if (buddy.source.contains(BuddySource.gacha))
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: buddy.getRarityColor().withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: buddy.getRarityColor().withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Text(
                                'Gacha',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: buddy.getRarityColor(),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      if (buddy.source.contains(BuddySource.gacha) &&
                          buddy.source.contains(BuddySource.shop))
                        SizedBox(width: 8.w),
                      if (buddy.source.contains(BuddySource.shop))
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: buddy.getRarityColor().withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: buddy.getRarityColor().withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child:                               Text(
                            'Store',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: buddy.getRarityColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
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

            // How many times found?
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            const TextSpan(text: 'You found me '),
                            TextSpan(
                              text: '${buddy.duplicate}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: buddy.getRarityColor(),
                              ),
                            ),
                            const TextSpan(text: ' time(s)!'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Aura Points Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aura Points',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                  SizedBox(height: 8.h),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: buddy.auraPoints / buddy.getMaxPossibleAura(),
                      backgroundColor: AppColors.divider,
                      color: buddy.getRarityColor(),
                      minHeight: 8.h,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'My aura points might increase everytime you find me again!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
