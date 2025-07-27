import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/focus_session.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/focus_session.dart';

class FocusStatsCard extends StatelessWidget {
  final FocusSessionType sessionType;
  final int elapsedTime;
  final double focusScore;

  const FocusStatsCard({
    super.key,
    required this.sessionType,
    required this.elapsedTime,
    required this.focusScore,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = elapsedTime ~/ 60;
    final seconds = elapsedTime % 60;

    return Container(
      padding: EdgeInsets.all(20.w),
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
      child: Column(
        children: [
          Text(
            'Session Stats',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.timer_outlined,
                  label: 'Elapsed',
                  value: '${minutes}m ${seconds}s',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatItem(
                  icon: Icons.psychology_outlined,
                  label: 'Focus',
                  value: '${(focusScore * 100).toInt()}%',
                  color: _getFocusScoreColor(focusScore),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatItem(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  value: _getSessionTypeShort(),
                  color: _getSessionTypeColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getFocusScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  String _getSessionTypeShort() {
    switch (sessionType) {
      case FocusSessionType.work:
        return 'Work';
      case FocusSessionType.shortBreak:
        return 'Break';
      case FocusSessionType.longBreak:
        return 'Long';
    }
  }

  Color _getSessionTypeColor() {
    switch (sessionType) {
      case FocusSessionType.work:
        return AppColors.primary;
      case FocusSessionType.shortBreak:
        return AppColors.success;
      case FocusSessionType.longBreak:
        return AppColors.warning;
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14.sp,
            ),
            maxLines: 1,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 11.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
