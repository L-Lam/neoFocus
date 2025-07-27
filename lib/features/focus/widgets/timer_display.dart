import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class TimerDisplay extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;

  const TimerDisplay({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final progress =
        totalSeconds > 0
            ? (totalSeconds - remainingSeconds) / totalSeconds
            : 0.0;

    return Container(
      width: 250.w,
      height: 250.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress Circle
          SizedBox(
            width: 250.w,
            height: 250.w,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8.w,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isRunning ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),

          // Timer Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: 8.h),
              if (!isRunning && remainingSeconds == 0)
                Text(
                  'Session Complete!',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
