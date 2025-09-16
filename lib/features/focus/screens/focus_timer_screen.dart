import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/focus_session_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/focus_session_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/app_button.dart';
import 'focus_lock_screen.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  late FocusSessionService _sessionService;
  late UserService _userService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Timer settings
  int _focusDuration = 25;
  int _breakDuration = 5;
  int _longBreakDuration = 15;

  @override
  void initState() {
    super.initState();
    _sessionService = Provider.of<FocusSessionService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);

    // Load user preferences
    _loadUserPreferences();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = Provider.of<FocusSessionService>(context);
    final currentSession = sessionService.currentSession;
    final screenPadding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Focus Timer', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: screenPadding,
        child: Column(
          children: [
            SizedBox(height: 20.h),

            // Timer Display Section
            _buildTimerSection(currentSession),

            SizedBox(height: 40.h),

            // Timer Settings (only show when no active session)
            if (currentSession == null) ...[
              _buildTimerSettings(),
              SizedBox(height: 30.h),
            ],

            // Control Buttons
            _buildControlButtons(sessionService, currentSession),

            SizedBox(height: 30.h),

            // Session Stats
            if (currentSession == null) _buildSessionStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection(FocusSession? currentSession) {
    if (currentSession != null) {
      // Active session display
      return Container(
        width: 280.w,
        height: 280.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              _getSessionColor(currentSession.type).withValues(alpha: 0.1),
              _getSessionColor(currentSession.type).withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: _getSessionColor(currentSession.type),
            width: 4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSessionIcon(currentSession.type),
              size: 48.sp,
              color: _getSessionColor(currentSession.type),
            ),
            SizedBox(height: 16.h),
            Text(
              _formatTime(currentSession.remainingSeconds),
              style: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
                color: _getSessionColor(currentSession.type),
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _getSessionLabel(currentSession.type),
              style: AppTextStyles.body.copyWith(
                color: _getSessionColor(currentSession.type),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            // Progress indicator
            Container(
              width: 200.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor:
                    1 -
                    (currentSession.remainingSeconds /
                        (currentSession.duration * 60)),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getSessionColor(currentSession.type),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Ready to start display
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primaryLight.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 64.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _formatTime(_focusDuration * 60),
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Ready to Focus',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildTimerSettings() {
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
          Text('Timer Settings', style: AppTextStyles.heading3),
          SizedBox(height: 20.h),

          // Focus Duration
          _buildDurationSetting(
            'Focus Duration',
            _focusDuration,
            Icons.timer,
            AppColors.primary,
            (value) {
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
            (value) {
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
            (value) {
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
    Function(int) onChanged,
  ) {
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
              onPressed: value > 5 ? () => onChanged(value - 5) : null,
              icon: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      value > 5
                          ? color.withValues(alpha: 0.1)
                          : AppColors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.remove,
                  size: 16.sp,
                  color: value > 5 ? color : AppColors.textHint,
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
              onPressed: value < 60 ? () => onChanged(value + 5) : null,
              icon: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      value < 60
                          ? color.withValues(alpha: 0.1)
                          : AppColors.divider,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.add,
                  size: 16.sp,
                  color: value < 60 ? color : AppColors.textHint,
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
          if (mounted && sessionService.currentSession != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FocusLockScreen()),
            );
          }
        },
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
      );
    } else {
      // Session active buttons
      return Column(
        children: [
          Row(
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
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppButton(
                  text: 'Stop',
                  onPressed: () => _showStopConfirmation(sessionService),
                  color: AppColors.error,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppButton(
            text: 'View Full Screen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FocusLockScreen()),
              );
            },
            color: AppColors.primary,
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ],
      );
    }
  }

  Widget _buildSessionStats() {
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
          Text('Today\'s Progress', style: AppTextStyles.heading3),
          SizedBox(height: 16.h),
          FutureBuilder<int>(
            future: _sessionService.getTodaySessionCount(
              Provider.of<AuthService>(context, listen: false).user?.uid ?? '',
            ),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              final minutes = count * _focusDuration;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.today,
                    value: count.toString(),
                    label: 'Sessions',
                    color: AppColors.primary,
                  ),
                  _buildStatItem(
                    icon: Icons.timer,
                    value: minutes.toString(),
                    label: 'Minutes',
                    color: AppColors.success,
                  ),
                  _buildStatItem(
                    icon: Icons.local_fire_department,
                    value: count > 0 ? '🔥' : '💤',
                    label: 'Streak',
                    color: AppColors.warning,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24.sp, color: color),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(fontSize: 18.sp, color: color),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Color _getSessionColor(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppColors.primary;
      case SessionType.shortBreak:
        return AppColors.warning;
      case SessionType.longBreak:
        return AppColors.success;
    }
  }

  IconData _getSessionIcon(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return Icons.psychology;
      case SessionType.shortBreak:
        return Icons.coffee;
      case SessionType.longBreak:
        return Icons.weekend;
    }
  }

  String _getSessionLabel(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return 'Focus Time';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
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
}
