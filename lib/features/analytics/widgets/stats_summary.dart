import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../models/analytics_data.dart';

class StatsSummary extends StatelessWidget {
  final AnalyticsData analytics;

  const StatsSummary({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: AppTextStyles.heading3),
          SizedBox(height: 20.h),
          Row(
            children: [
              _StatCard(
                label: 'Total Focus',
                value: _formatMinutes(analytics.totalFocusMinutes),
                icon: Icons.timer,
                color: AppColors.primary,
              ),
              SizedBox(width: 16.w),
              _StatCard(
                label: 'Sessions',
                value: analytics.totalSessions.toString(),
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _StatCard(
                label: 'Avg Daily',
                value: '${analytics.averageDailyFocus.toStringAsFixed(0)}m',
                icon: Icons.trending_up,
                color: AppColors.warning,
              ),
              SizedBox(width: 16.w),
              _StatCard(
                label: 'Best Day',
                value: '${analytics.bestDay}m',
                icon: Icons.emoji_events,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.heading3.copyWith(color: color),
                  ),
                  Text(label, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
