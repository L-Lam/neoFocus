import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/focus_session_model.dart';

class SessionTypeIndicator extends StatelessWidget {
  final SessionType? sessionType;
  final bool isActive;

  const SessionTypeIndicator({
    super.key,
    required this.sessionType,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData icon;

    switch (sessionType) {
      case SessionType.focus:
        text = 'Focus Time';
        color = AppColors.primary;
        icon = Icons.work;
        break;
      case SessionType.shortBreak:
        text = 'Short Break';
        color = AppColors.success;
        icon = Icons.coffee;
        break;
      case SessionType.longBreak:
        text = 'Long Break';
        color = AppColors.warning;
        icon = Icons.weekend;
        break;
      default:
        text = 'Ready to Start';
        color = AppColors.textSecondary;
        icon = Icons.play_circle_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : AppColors.divider,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: isActive ? color : AppColors.textSecondary,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: isActive ? color : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
