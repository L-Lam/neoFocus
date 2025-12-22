import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/focus_session_model.dart';
import '../../../core/services/focus_session_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/app_button.dart';
import '../widgets/pomodoro_animation_widget.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late UserService _userService;

  // Timer settings
  int _focusDuration = 25;
  int _breakDuration = 5;
  int _longBreakDuration = 15;

  @override
  void initState() {
    super.initState();
    _userService = Provider.of<UserService>(context, listen: false);

    // Load user preferences
    _loadUserPreferences();
  }

  // void _handleSessionUpdate() async {
  //   // Check if a session just completed
  //   if (_sessionService.currentSession == null && _sessionService.lastCompletedSession != null) {
  //     final completedSession = _sessionService.lastCompletedSession!;
  //     if (completedSession.type == SessionType.focus) {
  //       // Update ELO rating for focus sessions only
  //       await EloService.updateSessionFocus(completedSession.duration);
  //     }
  //   }
  // }

  void _loadUserPreferences() {
    final prefs = _userService.currentUser?.preferences;
    if (prefs != null) {
      setState(() {
        _focusDuration = prefs.focusDuration;
        _breakDuration = prefs.breakDuration;
        _longBreakDuration = prefs.longBreakDuration;
      });
    }
  }

  Future<void> _updateUserPreferences() async {
    final user = _userService.currentUser;
    if (user != null) {
      final updatedPrefs = user.preferences.copyWith(
        focusDuration: _focusDuration,
        breakDuration: _breakDuration,
        longBreakDuration: _longBreakDuration,
      );

      await _userService.updatePreferences(
        uid: user.uid,
        preferences: updatedPrefs,
      );
    }
  }

  // @override
  // void dispose() {
  //   _sessionService.removeListener(_handleSessionUpdate);
  //   _pulseController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final sessionService = Provider.of<FocusSessionService>(context);
    final currentSession = sessionService.currentSession;
    final screenPadding = ResponsiveHelper.getScreenPadding(context);

    return PopScope(
      canPop: currentSession == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && currentSession != null) {
          _showExitConfirmation(context, sessionService);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('Focus Timer', style: AppTextStyles.heading3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (currentSession != null) {
                _showExitConfirmation(context, sessionService);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: screenPadding,
          child: Column(
            children: [
              _buildTimerText(currentSession),
              SizedBox(height: 8.h),
              _buildBobbyArea(currentSession),
              SizedBox(height: 16.h),
              _buildTimerSettings(currentSession),
              SizedBox(height: 16.h),
              _buildControlButtons(sessionService, currentSession),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerText(FocusSession? currentSession) {
    final timeToDisplay =
        currentSession != null
            ? currentSession.remainingSeconds
            : _focusDuration * 60;

    return Column(
      children: [
        Text(
          _formatTime(timeToDisplay),
          style: AppTextStyles.heading1.copyWith(fontSize: 48.sp),
        ),
        Text(
          currentSession != null ? "Time to focus!" : "Are you ready to focus?",
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildBobbyArea(FocusSession? currentSession) {
    final containerHeight = 180.h;
    return SizedBox(
      width: double.infinity,
      height: containerHeight,
      child: PomodoroAnimationWidget(
        isSessionActive:
            Provider.of<FocusSessionService>(
              context,
              listen: false,
            ).isTimerRunning,
      ),
    );
  }

  Widget _buildTimerSettings(FocusSession? currentSession) {
    final isActive = currentSession != null;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isActive ? 'Session Active' : 'Timer Settings',
            style: AppTextStyles.heading3,
          ),
          SizedBox(height: 20.h),

          // Focus Duration
          _buildDurationSetting(
            'Focus Duration',
            _focusDuration,
            Icons.timer,
            AppColors.primary,
            isActive
                ? null
                : (value) {
                  setState(() => _focusDuration = value);
                  _updateUserPreferences();
                },
          ),

          SizedBox(height: 16.h),

          // Break Duration
          _buildDurationSetting(
            'Short Break',
            _breakDuration,
            Icons.coffee,
            AppColors.warning,
            isActive
                ? null
                : (value) {
                  setState(() => _breakDuration = value);
                  _updateUserPreferences();
                },
          ),

          SizedBox(height: 16.h),

          // Long Break Duration
          _buildDurationSetting(
            'Long Break',
            _longBreakDuration,
            Icons.weekend,
            AppColors.success,
            isActive
                ? null
                : (value) {
                  setState(() => _longBreakDuration = value);
                  _updateUserPreferences();
                },
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSetting(
    String title,
    int value,
    IconData icon,
    Color color,
    Function(int)? onChanged,
  ) {
    final isDisabled = onChanged == null;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$value minutes',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed:
                  !isDisabled && value > 5 ? () => onChanged(value - 5) : null,
              icon: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      !isDisabled && value > 5
                          ? color.withValues(alpha: 0.1)
                          : AppColors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.remove,
                  size: 16.sp,
                  color: !isDisabled && value > 5 ? color : AppColors.textHint,
                ),
              ),
            ),
            Container(
              width: 40.w,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            IconButton(
              onPressed:
                  !isDisabled && value < 60 ? () => onChanged(value + 5) : null,
              icon: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      !isDisabled && value < 60
                          ? color.withValues(alpha: 0.1)
                          : AppColors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.add,
                  size: 16.sp,
                  color: !isDisabled && value < 60 ? color : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    FocusSessionService sessionService,
    FocusSession? currentSession,
  ) {
    if (currentSession == null) {
      // Start button
      return AppButton(
        text: 'Start Focus Session',
        onPressed: () async {
          await sessionService.startFocusSession();
        },
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
      );
    } else {
      // Pause/Resume and Stop buttons
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: sessionService.isTimerRunning ? 'Pause' : 'Resume',
              onPressed: () {
                if (sessionService.isTimerRunning) {
                  sessionService.pauseSession();
                } else {
                  sessionService.resumeSession();
                }
              },
              color: AppColors.warning,
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppButton(
              text: 'Stop',
              onPressed: () => _showStopConfirmation(sessionService),
              color: AppColors.error,
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ],
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showStopConfirmation(FocusSessionService sessionService) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Stop Session?', style: AppTextStyles.heading3),
            content: Text(
              'Are you sure you want to stop this session? Your progress will be saved.',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Continue',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  sessionService.stopSession();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Stop'),
              ),
            ],
          ),
    );
  }

  void _showExitConfirmation(
    BuildContext context,
    FocusSessionService sessionService,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Cancel Session?', style: AppTextStyles.heading3),
            content: Text(
              'Leaving will cancel your current focus session. Your progress will not be saved.',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Stay', style: TextStyle(color: AppColors.primary)),
              ),
              TextButton(
                onPressed: () {
                  sessionService.stopSession();
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close focus screen
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Leave'),
              ),
            ],
          ),
    );
  }
}
