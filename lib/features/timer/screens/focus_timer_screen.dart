import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/reward_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/app_button.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = AppConstants.defaultFocusDuration * 60;
  bool _isRunning = false;
  String _sessionType = 'focus';
  int _sessionsCompleted = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _completeSession();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
    _pulseController.stop();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _remainingSeconds = _getSessionDuration() * 60;
    });
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
  }

  void _completeSession() async {
    _timer?.cancel();
    _pulseController.stop();

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId != null && _sessionType == 'focus') {
      // Save completed session
      await RewardService.completeSession(
        userId: userId,
        duration: _getSessionDuration(),
        sessionType: _sessionType,
      );

      setState(() {
        _sessionsCompleted++;
      });
    }

    // Determine next session type
    if (_sessionType == 'focus') {
      if (_sessionsCompleted % AppConstants.sessionsUntilLongBreak == 0) {
        _sessionType = 'longBreak';
        _remainingSeconds = AppConstants.defaultLongBreakDuration * 60;
      } else {
        _sessionType = 'break';
        _remainingSeconds = AppConstants.defaultBreakDuration * 60;
      }
    } else {
      _sessionType = 'focus';
      _remainingSeconds = AppConstants.defaultFocusDuration * 60;
    }

    setState(() => _isRunning = false);

    // Show completion dialog
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.largeRadius),
            ),
            title: Text(
              _sessionType == 'focus' ? 'Break Time!' : 'Ready to Focus?',
              style: AppTextStyles.heading2,
            ),
            content: Text(
              _sessionType == 'focus'
                  ? 'Great work! Take a ${_getSessionDuration()} minute break.'
                  : 'Break\'s over! Ready for another focus session?',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetTimer();
                },
                child: Text(
                  'Skip',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultRadius,
                    ),
                  ),
                ),
                child: Text(
                  'Start ${_sessionType == 'focus' ? 'Break' : 'Focus'}',
                  style: AppTextStyles.button,
                ),
              ),
            ],
          ),
    );
  }

  int _getSessionDuration() {
    switch (_sessionType) {
      case 'break':
        return AppConstants.defaultBreakDuration;
      case 'longBreak':
        return AppConstants.defaultLongBreakDuration;
      default:
        return AppConstants.defaultFocusDuration;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getSessionColor() {
    switch (_sessionType) {
      case 'break':
      case 'longBreak':
        return AppColors.focusBreak;
      default:
        return AppColors.focusActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenPadding = ResponsiveHelper.getScreenPadding(context);
    final progress = 1 - (_remainingSeconds / (_getSessionDuration() * 60));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _sessionType == 'focus' ? 'Focus Time' : 'Break Time',
          style: AppTextStyles.heading3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () {
            if (_isRunning) {
              _pauseTimer();
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: screenPadding,
            child: Container(
              width: ResponsiveHelper.getContentWidth(context),
              constraints: BoxConstraints(maxWidth: 600.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer display
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRunning ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 280.w,
                          height: 280.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getSessionColor().withOpacity(0.1),
                            border: Border.all(
                              color: _getSessionColor(),
                              width: 4,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress indicator
                              SizedBox(
                                width: 280.w,
                                height: 280.w,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getSessionColor(),
                                  ),
                                ),
                              ),
                              // Timer text
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: AppTextStyles.heading1.copyWith(
                                      fontSize: 48.sp,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    _sessionType == 'focus'
                                        ? 'Stay focused!'
                                        : 'Take a break',
                                    style: AppTextStyles.body,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 64.h),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset button
                      IconButton(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh),
                        iconSize: 32.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 32.w),
                      // Play/Pause button
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getSessionColor(),
                          boxShadow: [
                            BoxShadow(
                              color: _getSessionColor().withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            size: 40.sp,
                          ),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 32.w),
                      // Skip button
                      IconButton(
                        onPressed: () {
                          _resetTimer();
                          _completeSession();
                        },
                        icon: const Icon(Icons.skip_next),
                        iconSize: 32.sp,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: 48.h),

                  // Session info
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                        AppConstants.largeRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Session', style: AppTextStyles.caption),
                            SizedBox(height: 4.h),
                            Text(
                              '${_sessionsCompleted + 1}',
                              style: AppTextStyles.heading3,
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40.h,
                          color: AppColors.divider,
                        ),
                        Column(
                          children: [
                            Text('Type', style: AppTextStyles.caption),
                            SizedBox(height: 4.h),
                            Text(
                              _sessionType == 'focus' ? 'Focus' : 'Break',
                              style: AppTextStyles.heading3,
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40.h,
                          color: AppColors.divider,
                        ),
                        Column(
                          children: [
                            Text('Duration', style: AppTextStyles.caption),
                            SizedBox(height: 4.h),
                            Text(
                              '${_getSessionDuration()}m',
                              style: AppTextStyles.heading3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
