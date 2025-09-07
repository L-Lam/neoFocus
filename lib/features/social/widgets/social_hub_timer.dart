import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialHubTimer extends StatefulWidget {
  final int dailyLimitMinutes;

  const SocialHubTimer({
    super.key,
    this.dailyLimitMinutes = 30, // 30 minutes daily limit
  });

  @override
  State<SocialHubTimer> createState() => _SocialHubTimerState();
}

class _SocialHubTimerState extends State<SocialHubTimer> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerActive = false;
  DateTime? _sessionStartTime;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _checkDailyUsage();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _endTracking();
    super.dispose();
  }

  Future<void> _checkDailyUsage() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final snapshot = await FirebaseService.currentUserDoc!
        .collection('social_sessions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    int totalSecondsToday = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalSecondsToday += (data['duration'] as int? ?? 0);
    }

    setState(() {
      _remainingSeconds = (widget.dailyLimitMinutes * 60) - totalSecondsToday;
      if (_remainingSeconds < 0) _remainingSeconds = 0;
    });
  }

  void _startTracking() async {
    if (_remainingSeconds <= 0) return;

    _sessionStartTime = DateTime.now();
    final session = await FirebaseService.currentUserDoc!
        .collection('social_sessions')
        .add({
      'date': Timestamp.fromDate(_sessionStartTime!),
      'startTime': Timestamp.fromDate(_sessionStartTime!),
      'duration': 0,
      'isActive': true,
    });

    _currentSessionId = session.id;
    _isTimerActive = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Update duration every 10 seconds
        if (_remainingSeconds % 10 == 0) {
          _updateSessionDuration();
        }
      } else {
        _handleTimeUp();
      }
    });
  }

  void _updateSessionDuration() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;

    await FirebaseService.currentUserDoc!
        .collection('social_sessions')
        .doc(_currentSessionId)
        .update({
      'duration': duration,
    });
  }

  void _endTracking() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;

    await FirebaseService.currentUserDoc!
        .collection('social_sessions')
        .doc(_currentSessionId)
        .update({
      'duration': duration,
      'endTime': FieldValue.serverTimestamp(),
      'isActive': false,
    });
  }

  void _handleTimeUp() {
    _timer?.cancel();
    _endTracking();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.timer_off,
              color: AppColors.error,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Time\'s Up!',
              style: AppTextStyles.heading3,
            ),
          ],
        ),
        content: Text(
          'You\'ve reached your daily social hub limit. Come back tomorrow to continue chatting!',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit social hub
            },
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
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

  @override
  Widget build(BuildContext context) {
    final isLowTime = _remainingSeconds < 300; // Less than 5 minutes
    final timerColor = isLowTime ? AppColors.error : AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: timerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: timerColor,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            _formatTime(_remainingSeconds),
            style: AppTextStyles.body.copyWith(
              color: timerColor,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          if (isLowTime) ...[
            SizedBox(width: 8.w),
            Icon(
              Icons.warning,
              color: AppColors.warning,
              size: 16.sp,
            ),
          ],
        ],
      ),
    );
  }
}


class SocialHubTimerWidget extends StatelessWidget {
  const SocialHubTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SocialHubTimer(
      dailyLimitMinutes: 30, // 30 minutes daily limit
    );
  }
}


