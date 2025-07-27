import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

class PomodoroProgress extends StatelessWidget {
  final int currentPomodoro;
  final int totalPomodoros;

  const PomodoroProgress({
    super.key,
    required this.currentPomodoro,
    required this.totalPomodoros,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPomodoros, (index) {
        final isCompleted = index < currentPomodoro;
        final isCurrent = index == currentPomodoro - 1;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: 40.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
            border:
                isCurrent
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
          ),
        );
      }),
    );
  }
}
