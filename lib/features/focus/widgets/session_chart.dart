import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SessionChart extends StatelessWidget {
  final int weekFocusMinutes;

  const SessionChart({super.key, required this.weekFocusMinutes});

  @override
  Widget build(BuildContext context) {
    // Simple placeholder chart - in a real app, use charts_flutter or fl_chart
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [30, 45, 25, 60, 40, 20, 35]; // Sample data
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              final height =
                  maxValue > 0 ? (values[index] / maxValue) * 120.h : 0.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${values[index]}m',
                    style: AppTextStyles.caption.copyWith(fontSize: 10.sp),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 30.w,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(days[index], style: AppTextStyles.caption),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
