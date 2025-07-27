import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class StreakIndicator extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakIndicator({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStreakCard(
          icon: Icons.local_fire_department,
          label: 'Current',
          value: currentStreak,
          color: AppColors.error,
          isActive: currentStreak > 0,
        ),
        SizedBox(width: 16.w),
        _buildStreakCard(
          icon: Icons.emoji_events,
          label: 'Longest',
          value: longestStreak,
          color: AppColors.warning,
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildStreakCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? color : AppColors.textHint, size: 24.sp),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value days',
                style: AppTextStyles.heading3.copyWith(
                  color: isActive ? color : AppColors.textSecondary,
                ),
              ),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
