import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/focus_session_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/focus_session_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/app_button.dart';
import '../widgets/timer_display.dart';
import '../widgets/session_type_indicator.dart';
import '../widgets/pomodoro_progress.dart';
import 'session_complete_dialog.dart';
import 'focus_lock_screen.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late FocusSessionService _sessionService;
  bool _wasSessionActive = false;
  SessionType _lastSessionType = SessionType.focus;
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionService = Provider.of<FocusSessionService>(context, listen: false);

    // Listen for session completion
    _sessionService.addListener(_checkSessionCompletion);

    // Initialize animations
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _sessionService.removeListener(_checkSessionCompletion);
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle to pause timer when app goes to background
    if (state == AppLifecycleState.paused) {
      if (_sessionService.isTimerRunning) {
        _sessionService.pauseSession();
      }
    }
  }

  void _checkSessionCompletion() {
    final session = _sessionService.currentSession;
    if (session == null && _wasSessionActive) {
      // Session just completed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SessionCompleteDialog.show(
            context,
            _lastSessionType,
            xpEarned: _lastSessionType == SessionType.focus ? 20 : 0,
          );
        }
      });
    }
    _wasSessionActive = session != null;
    if (session != null) {
      _lastSessionType = session.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = Provider.of<FocusSessionService>(context);
    final authService = Provider.of<AuthService>(context);
    final currentSession = sessionService.currentSession;
    final screenPadding = ResponsiveHelper.getScreenPadding(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated Background (only when no session)
          if (currentSession == null)
            AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        _backgroundAnimationController.value * 2 - 1,
                        -1,
                      ),
                      end: Alignment(
                        -_backgroundAnimationController.value * 2 + 1,
                        1,
                      ),
                      colors: [
                        AppColors.primary.withOpacity(0.05),
                        AppColors.primaryLight.withOpacity(0.05),
                      ],
                    ),
                  ),
                );
              },
            ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Theme.of(context).iconTheme.color,
                            size: 20.sp,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Focus Timer',
                        style: AppTextStyles.heading3.copyWith(
                          color:
                              Theme.of(context).textTheme.headlineSmall?.color,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history,
                            color: Theme.of(context).iconTheme.color,
                            size: 20.sp,
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Focus history coming soon!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: screenPadding,
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),

                        // Show message if session is active
                        if (currentSession != null) ...[
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    'Session is running in the background',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
                        ],

                        // Pomodoro Progress Indicator
                        PomodoroProgress(
                          currentPomodoro: currentSession?.pomodoroCount ?? 0,
                          totalPomodoros: 4,
                        ),
                        SizedBox(height: 30.h),

                        // Session Type Indicator with animation
                        AnimatedScale(
                          scale: currentSession != null ? 0.9 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: SessionTypeIndicator(
                            sessionType: currentSession?.type,
                            isActive: currentSession != null,
                          ),
                        ),

                        // Timer Display or Start Prompt
                        Expanded(
                          child: Center(
                            child:
                                currentSession != null
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Mini timer display - FIXED OVERFLOW
                                        Container(
                                          width: 220.w, // Increased from 180.w
                                          height: 220.w, // Increased from 180.w
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            border: Border.all(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              width: 3,
                                            ),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.timer,
                                                  size:
                                                      36.sp, // Reduced from 40.sp
                                                  color: AppColors.primary,
                                                ),
                                                SizedBox(
                                                  height: 12.h,
                                                ), // Increased from 8.h
                                                Text(
                                                  _formatTime(
                                                    currentSession
                                                        .remainingSeconds,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize:
                                                        36.sp, // Adjusted for better fit
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primary,
                                                    fontFamily: 'monospace',
                                                    letterSpacing:
                                                        2.0, // Added letter spacing
                                                  ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  'remaining',
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            width: 220.w,
                                            height: 220.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.primary.withOpacity(
                                                    0.1,
                                                  ),
                                                  AppColors.primaryLight
                                                      .withOpacity(0.1),
                                                ],
                                              ),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.3),
                                                width: 3,
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.play_circle_outline,
                                                    size: 60.sp,
                                                    color: AppColors.primary,
                                                  ),
                                                  SizedBox(height: 12.h),
                                                  Text(
                                                    'Ready to Focus',
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                          color:
                                                              AppColors.primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ),

                        // Stats Cards
                        if (currentSession == null)
                          FutureBuilder<int>(
                            future: sessionService.getTodaySessionCount(
                              authService.user?.uid ?? '',
                            ),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 16.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.1),
                                      AppColors.primaryLight.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      icon: Icons.today,
                                      value: count.toString(),
                                      label: 'Today',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40.h,
                                      color: AppColors.divider,
                                    ),
                                    _buildStatItem(
                                      icon: Icons.local_fire_department,
                                      value: '${count * 25}',
                                      label: 'Minutes',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40.h,
                                      color: AppColors.divider,
                                    ),
                                    _buildStatItem(
                                      icon: Icons.star,
                                      value: '${count * 20}',
                                      label: 'XP Earned',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        if (currentSession == null) SizedBox(height: 30.h),

                        // Control Buttons with better styling
                        _buildControlButtons(
                          sessionService,
                          currentSession,
                          authService.user?.uid ?? '',
                        ),
                        SizedBox(height: 30.h),

                        // Tips Section with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: _buildTipsSection(currentSession?.type),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24.sp, color: AppColors.primary),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            fontSize: 18.sp,
            color: AppColors.primary,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildControlButtons(
    FocusSessionService sessionService,
    FocusSession? currentSession,
    String userId,
  ) {
    if (currentSession == null) {
      // No active session - Beautiful start button
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AppButton(
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
          width: 220.w,
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 18.h),
        ),
      );
    }

    // If session is active, show "View Session" button
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FocusLockScreen()),
            );
          },
          child: Text(
            'View Active Session',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(SessionType? sessionType) {
    String tip;
    IconData icon;
    Color color;

    if (sessionType == null) {
      tip = 'Ready to focus? Start a 25-minute session!';
      icon = Icons.lightbulb_outline;
      color = AppColors.primary;
    } else {
      tip =
          'Your session continues in the background. Tap "View Active Session" to see the timer.';
      icon = Icons.info_outline;
      color = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              tip,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
              'Are you sure you want to stop this session? Your progress will be lost.',
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
