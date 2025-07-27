import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/focus_session.dart';

class CircularTimer extends StatelessWidget {
  final int duration; // in minutes
  final int elapsedSeconds;
  final SessionStatus status;
  final SessionType type;

  const CircularTimer({
    super.key,
    required this.duration,
    required this.elapsedSeconds,
    required this.status,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final totalSeconds = duration * 60;
    final progress = elapsedSeconds / totalSeconds;
    final remainingSeconds = totalSeconds - elapsedSeconds;
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    final color = _getColorForType(type);

    return Container(
      width: 280.w,
      height: 280.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(280.w, 280.w),
            painter: CircleProgressPainter(
              progress: 1.0,
              color: color.withOpacity(0.1),
              strokeWidth: 12.w,
            ),
          ),

          // Progress circle
          CustomPaint(
            size: Size(280.w, 280.w),
            painter: CircleProgressPainter(
              progress: progress,
              color: color,
              strokeWidth: 12.w,
            ),
          ),

          // Timer text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.w300,
                  color: color,
                ),
              ),
              SizedBox(height: 8.h),
              if (status == SessionStatus.paused)
                Text(
                  'PAUSED',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppColors.primary;
      case SessionType.shortBreak:
        return AppColors.success;
      case SessionType.longBreak:
        return AppColors.focusBreak;
    }
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Draw arc from top (-90 degrees)
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
