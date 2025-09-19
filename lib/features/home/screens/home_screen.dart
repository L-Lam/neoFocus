import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/active_session_card.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/elo_rating_card.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../focus/screens/focus_timer_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../social/screens/challenges_screen.dart';
import '../../gacha/screens/gacha_screen.dart';
import '../../social/screens/social_hub_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenPadding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Focus Hero', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.textPrimary,
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.currentUserDoc?.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('Error loading user data', style: AppTextStyles.body),
            );
          }

          return SingleChildScrollView(
            padding: screenPadding,
            child: Center(
              child: Container(
                width: ResponsiveHelper.getContentWidth(context),
                constraints: BoxConstraints(maxWidth: 800.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ELO Rating Card
                    const EloRatingCard(),
                    SizedBox(height: 16.h),

                    // Reward Progress Section with Dynamic Data
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseService.currentUserDoc
                              ?.collection('sessions')
                              .where(
                                'startedAt',
                                isGreaterThanOrEqualTo: Timestamp.fromDate(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                  ),
                                ),
                              )
                              .where(
                                'startedAt',
                                isLessThan: Timestamp.fromDate(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day + 1,
                                  ),
                                ),
                              )
                              .snapshots(),
                      builder: (context, todaySessionsSnapshot) {
                        int todaySessionsCount = 0;
                        int todayFocusMinutes = 0;
                        int todayAchievements = 0;

                        if (todaySessionsSnapshot.hasData) {
                          todaySessionsCount =
                              todaySessionsSnapshot.data!.docs.length;

                          for (var doc in todaySessionsSnapshot.data!.docs) {
                            final sessionData =
                                doc.data() as Map<String, dynamic>;
                            // Handle both 'duration' and 'actualDuration' fields
                            final duration =
                                sessionData['actualDuration'] ??
                                sessionData['duration'] ??
                                25;
                            todayFocusMinutes += duration as int;
                          }
                        }

                        // Calculate achievements
                        if (todaySessionsCount >= 3) todayAchievements++;
                        if (todayFocusMinutes >= 90) todayAchievements++;
                        if (todaySessionsCount > 0) todayAchievements++;

                        return Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppConstants.largeRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ActiveSessionCard(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Today\'s Progress',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$todayAchievements achieved',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              // Daily Goals - NOW DYNAMIC
                              _buildDailyGoal(
                                'Complete 3 Sessions',
                                todaySessionsCount,
                                3,
                                Icons.check_circle,
                              ),
                              SizedBox(height: 10.h),
                              _buildDailyGoal(
                                'Focus 90 Minutes',
                                todayFocusMinutes,
                                90,
                                Icons.timer,
                              ),
                              SizedBox(height: 10.h),
                              _buildDailyGoal(
                                'Keep Streak',
                                todaySessionsCount > 0 ? 1 : 0,
                                1,
                                Icons.local_fire_department,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Quick Actions
                    Text('Quick Actions', style: AppTextStyles.heading3),
                    SizedBox(height: 16.h),

                    // Start Focus Session - Hero Style
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FocusTimerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.focusActive,
                              AppColors.focusActive.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.largeRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.focusActive.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              size: 64.sp,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Start Focus Quest',
                              style: AppTextStyles.heading3.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Begin your journey to productivity',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Action Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Analytics',
                            'View Progress',
                            Icons.analytics,
                            AppColors.success,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AnalyticsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildActionCard(
                            'Challenges',
                            'Daily Quests',
                            Icons.flag,
                            AppColors.warning,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChallengesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Social Hub',
                            'Join the community! Interact with others!',
                            Icons.people,
                            AppColors.primary,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SocialHubScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildActionCard(
                            'Companion Collector',
                            'Acquire companions to aid your focus journey!',
                            Icons.auto_awesome,
                            AppColors.error,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GachaScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // Debug button for generating sample data (remove in production)
                    if (true) // Set to false in production
                      Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: Center(
                          child: TextButton(
                            onPressed: () => _generateSampleData(),
                            child: Text(
                              'Generate Sample Data (Debug)',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyGoal(String title, int current, int total, IconData icon) {
    final progress = (current / total).clamp(0.0, 1.0);
    final isCompleted = current >= total;

    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? AppColors.success : AppColors.textHint,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Container(
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isCompleted ? AppColors.success : AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          '$current/$total',
          style: TextStyle(
            fontSize: 11.sp,
            color: isCompleted ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Generate sample data for testing
  Future<void> _generateSampleData() async {
    // Generate sessions for the past 30 days
    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final sessionsPerDay = random.nextInt(4) + 1;

      for (int j = 0; j < sessionsPerDay; j++) {
        final hour = random.nextInt(14) + 7; // 7 AM to 9 PM
        final startTime = DateTime(date.year, date.month, date.day, hour);
        final duration = [25, 25, 25, 50, 90][random.nextInt(5)];

        await FirebaseService.firestore
            .collection('users')
            .doc(FirebaseService.auth.currentUser!.uid)
            .collection('sessions')
            .add({
              'startedAt': Timestamp.fromDate(startTime),
              'completedAt': Timestamp.fromDate(
                startTime.add(Duration(minutes: duration)),
              ),
              'duration': duration,
              'category': ['Work', 'Study', 'Personal'][random.nextInt(3)],
              'type': 'pomodoro',
            });
      }
    }

    // Update user stats
    await FirebaseService.currentUserDoc!.update({
      'eloRating': 1200,
      'totalFocusMinutes': 2850,
      'currentStreak': 7,
      'longestStreak': 15,
      'achievements': ['first_session', 'week_streak'],
    });
  }
}
