import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/focus_session_model.dart';
import '../../../core/services/focus_session_service.dart';
import '../../../widgets/app_button.dart';
import 'dart:async';

class SessionCompleteDialog extends StatefulWidget {
  final SessionType completedType;
  final int xpEarned;

  const SessionCompleteDialog({
    super.key,
    required this.completedType,
    this.xpEarned = 0,
  });

  static void show(
    BuildContext context,
    SessionType completedType, {
    int xpEarned = 0,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => SessionCompleteDialog(
            completedType: completedType,
            xpEarned: xpEarned,
          ),
    );
  }

  @override
  State<SessionCompleteDialog> createState() => _SessionCompleteDialogState();
}

class _SessionCompleteDialogState extends State<SessionCompleteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _autoCloseTimer;
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();

    // Auto close dialog after 10 seconds
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = Provider.of<FocusSessionService>(context);
    final nextSessionType = sessionService.getNextSessionType();
    final shouldTakeLongBreak = sessionService.shouldTakeLongBreak();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 48.sp,
                        color: AppColors.success,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),

              // Title
              Text(
                _getTitle(widget.completedType),
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Message
              Text(
                _getMessage(widget.completedType, nextSessionType),
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),

              // XP Earned (for focus sessions)
              if (widget.completedType == SessionType.focus &&
                  widget.xpEarned > 0) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 20.sp, color: AppColors.warning),
                      SizedBox(width: 8.w),
                      Text(
                        '+${widget.xpEarned} XP',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Auto-start countdown
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 20.sp, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'Next session starts in $_secondsRemaining seconds',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Action Buttons
              if (widget.completedType == SessionType.focus) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Skip Break',
                        onPressed: () {
                          Navigator.pop(context);
                          sessionService.startFocusSession();
                        },
                        isOutlined: true,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        text:
                            shouldTakeLongBreak ? 'Long Break' : 'Short Break',
                        onPressed: () {
                          Navigator.pop(context);
                          // Session will auto-start
                        },
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Take Another Break',
                        onPressed: () {
                          Navigator.pop(context);
                          sessionService.stopSession(); // Stop auto-start
                          sessionService.startBreakSession(
                            isLongBreak:
                                widget.completedType == SessionType.longBreak,
                          );
                        },
                        isOutlined: true,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppButton(
                        text: 'Start Focus',
                        onPressed: () {
                          Navigator.pop(context);
                          // Session will auto-start
                        },
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  sessionService.stopSession(); // Stop auto-start
                },
                child: Text(
                  'Done for now',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return '🎉 Great Focus Session!';
      case SessionType.shortBreak:
        return '☕ Break Complete!';
      case SessionType.longBreak:
        return '🌟 Long Break Complete!';
    }
  }

  String _getMessage(SessionType completedType, SessionType nextType) {
    if (completedType == SessionType.focus) {
      return 'You\'ve completed a 25-minute focus session. Time for a well-deserved break!';
    } else {
      return 'Ready to get back to work? Let\'s start your next focus session.';
    }
  }
}
