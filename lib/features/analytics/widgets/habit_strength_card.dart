import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

class HabitStrengthCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final double consistency;
  final int totalDays;

  const HabitStrengthCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.consistency,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final habitStrength = _calculateHabitStrength();
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Container(
      padding: EdgeInsets.all(16.w),
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
      child:
          isSmallScreen
              ? Column(
                children: [
                  _buildCircularProgress(habitStrength),
                  SizedBox(height: 16.h),
                  _buildStats(),
                ],
              )
              : Row(
                children: [
                  _buildCircularProgress(habitStrength),
                  SizedBox(width: 20.w),
                  Expanded(child: _buildStats()),
                ],
              ),
    );
  }

  Widget _buildCircularProgress(double habitStrength) {
    return CircularPercentIndicator(
      radius: 50.w,
      lineWidth: 6.w,
      percent: (habitStrength / 100).clamp(0.0, 1.0),
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${habitStrength.toInt()}%',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: _getStrengthColor(habitStrength),
              ),
            ),
          ),
          Text(
            'Strength',
            style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
      progressColor: _getStrengthColor(habitStrength),
      backgroundColor: AppColors.divider,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatRow(
          'Current Streak',
          '$currentStreak days',
          Icons.local_fire_department,
          AppColors.error,
        ),
        SizedBox(height: 10.h),
        _buildStatRow(
          'Longest Streak',
          '$longestStreak days',
          Icons.emoji_events,
          AppColors.warning,
        ),
        SizedBox(height: 10.h),
        _buildStatRow(
          'Consistency',
          '${consistency.toStringAsFixed(0)}%',
          Icons.calendar_month,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 2,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateHabitStrength() {
    // Calculate habit strength based on multiple factors
    final streakScore = (currentStreak / 30).clamp(0.0, 1.0) * 30;
    final consistencyScore = (consistency / 100) * 40;
    final longestStreakScore = (longestStreak / 60).clamp(0.0, 1.0) * 30;

    return streakScore + consistencyScore + longestStreakScore;
  }

  Color _getStrengthColor(double strength) {
    if (strength >= 80) return AppColors.success;
    if (strength >= 60) return AppColors.primary;
    if (strength >= 40) return AppColors.warning;
    return AppColors.error;
  }
}
