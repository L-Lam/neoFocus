import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/focus_session_service.dart';
import '../../../core/models/focus_session_model.dart';
import '../../../widgets/app_button.dart';

class FocusLockScreen extends StatefulWidget {
  const FocusLockScreen({super.key});

  @override
  State<FocusLockScreen> createState() => _FocusLockScreenState();
}

class _FocusLockScreenState extends State<FocusLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _floatingController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = Provider.of<FocusSessionService>(context);
    final session = sessionService.currentSession;

    if (session == null) {
      Navigator.pop(context);
      return const SizedBox.shrink();
    }

    final progress =
        session.duration > 0
            ? (session.duration * 60 - session.remainingSeconds) /
                (session.duration * 60)
            : 0.0;

    return WillPopScope(
      onWillPop: () async {
        _showExitDialog();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(session.type),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Floating decorative elements
                ..._buildFloatingElements(),

                // Main content
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getSessionTitle(session.type),
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                            onPressed: _showExitDialog,
                          ),
                        ],
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Breathing circle timer
                            AnimatedBuilder(
                              animation: _breathingAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _breathingAnimation.value,
                                  child: Container(
                                    width: 280.w,
                                    height: 280.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Progress circle
                                        SizedBox(
                                          width: 260.w,
                                          height: 260.w,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 8.w,
                                            backgroundColor: Colors.white
                                                .withOpacity(0.2),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Colors.white),
                                          ),
                                        ),

                                        // Timer display
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatTime(
                                                session.remainingSeconds,
                                              ),
                                              style: TextStyle(
                                                fontSize: 56.sp,
                                                fontWeight: FontWeight.w300,
                                                color: Colors.white,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              'remaining',
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 60.h),

                            // Motivational message
                            AnimatedBuilder(
                              animation: _floatingAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatingAnimation.value),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                      vertical: 16.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      _getMotivationalMessage(session.type),
                                      style: AppTextStyles.body.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 40.h),

                            // Control buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (session.status == SessionStatus.inProgress)
                                  _buildControlButton(
                                    icon: Icons.pause,
                                    onPressed:
                                        () => sessionService.pauseSession(),
                                  )
                                else
                                  _buildControlButton(
                                    icon: Icons.play_arrow,
                                    onPressed:
                                        () => sessionService.resumeSession(),
                                  ),
                                SizedBox(width: 24.w),
                                _buildControlButton(
                                  icon: Icons.stop,
                                  onPressed: _showStopConfirmation,
                                  isDestructive: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bottom info
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              icon: Icons.block,
                              label: 'Apps Blocked',
                              value: '12',
                            ),
                            Container(
                              width: 1,
                              height: 30.h,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildInfoItem(
                              icon: Icons.do_not_disturb,
                              label: 'Focus Mode',
                              value: 'ON',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingElements() {
    return List.generate(6, (index) {
      final random = math.Random(index);
      final size = random.nextDouble() * 100 + 50;
      final top = random.nextDouble() * 600;
      final left = random.nextDouble() * 300;

      return Positioned(
        top: top.h,
        left: left.w,
        child: AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _floatingAnimation.value * (index.isEven ? 1 : -1),
                _floatingAnimation.value * (index.isEven ? -1 : 1),
              ),
              child: Container(
                width: size.w,
                height: size.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color:
              isDestructive
                  ? Colors.red.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isDestructive
                    ? Colors.red.withOpacity(0.4)
                    : Colors.white.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 28.sp),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return [const Color(0xFF5B86E5), const Color(0xFF36D1DC)];
      case SessionType.shortBreak:
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case SessionType.longBreak:
        return [const Color(0xFFFC466B), const Color(0xFF3F5EFB)];
    }
  }

  String _getSessionTitle(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return 'Focus Mode Active';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String _getMotivationalMessage(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return 'Stay focused, you\'re doing great!';
      case SessionType.shortBreak:
        return 'Take a moment to relax';
      case SessionType.longBreak:
        return 'Rest and recharge your energy';
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Exit Focus Mode?', style: AppTextStyles.heading3),
            content: Text(
              'Your session is still running. You can return to the home screen and the timer will continue in the background.',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Exit'),
              ),
            ],
          ),
    );
  }

  void _showStopConfirmation() {
    final sessionService = Provider.of<FocusSessionService>(
      context,
      listen: false,
    );

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
                child: const Text('Continue'),
              ),
              TextButton(
                onPressed: () {
                  sessionService.stopSession();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Stop'),
              ),
            ],
          ),
    );
  }
}
