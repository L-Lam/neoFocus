import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/app_button.dart';
import '../models/friend_model.dart';
import 'create_friend_challenge_dialog.dart';

class FriendCard extends StatelessWidget {
  final Friend friend;

  const FriendCard({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                friend.displayName[0].toUpperCase(),
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.bolt, size: 16.sp, color: AppColors.warning),
                    SizedBox(width: 4.w),
                    Text('Level ${friend.level}', style: AppTextStyles.caption),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.local_fire_department,
                      size: 16.sp,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${friend.currentStreak} days',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          AppButton(
            text: 'Challenge',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CreateFriendChallengeDialog(friend: friend),
              );
            },
            width: 80.w,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          ),
        ],
      ),
    );
  }
}
