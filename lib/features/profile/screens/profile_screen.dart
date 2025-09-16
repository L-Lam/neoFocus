import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/task_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../../focus/widgets/stats_card.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/widgets/achievement_badge.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = Provider.of<UserService>(context, listen: false);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId != null) {
      await _userService.loadUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context);
    final user = userService.currentUser;
    final userId = authService.user?.uid;

    if (userId == null || user == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    final screenPadding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile Picture
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child:
                            user.photoUrl != null
                                ? ClipOval(
                                  child: Image.network(
                                    user.photoUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Icon(
                                  Icons.person,
                                  size: 40.sp,
                                  color: AppColors.primary,
                                ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Hello, ${user.displayName}!',
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Welcome to your profile',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),

          // Profile Content
          SliverPadding(
            padding: screenPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Bio Section
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultRadius,
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
                        Text(
                          'About',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(user.bio!, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Stats Section
                Text('Statistics', style: AppTextStyles.heading3),
                SizedBox(height: 16.h),

                StreamBuilder<Map<String, dynamic>>(
                  stream: _userService.getUserStats(userId),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? {};

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                title: 'ELO Rating',
                                value: '${user.eloRating}',
                                icon: Icons.trending_up,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: StatsCard(
                                title: 'Focus Time',
                                value: _formatFocusTime(
                                  stats['totalFocusMinutes'] ?? 0,
                                ),
                                icon: Icons.timer,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                title: 'Current Streak',
                                value: '${stats['currentStreak'] ?? 0} days',
                                icon: Icons.local_fire_department,
                                color: AppColors.error,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: StatsCard(
                                title: 'Longest Streak',
                                value: '${stats['longestStreak'] ?? 0} days',
                                icon: Icons.emoji_events,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 24.h),

                // Achievements Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Achievements', style: AppTextStyles.heading3),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all achievements
                      },
                      child: Text(
                        'See all',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Achievement badges
                Container(
                  height: 100.h,
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('achievements')
                            .orderBy('unlockedAt', descending: true)
                            .limit(5)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LoadingIndicator();
                      }

                      final achievements = snapshot.data!.docs;

                      if (achievements.isEmpty) {
                        return Center(
                          child: Text(
                            'No achievements yet. Keep going!',
                            style: AppTextStyles.bodySmall,
                          ),
                        );
                      }

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: achievements.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12.w),
                        itemBuilder: (context, index) {
                          final achievement =
                              achievements[index].data()
                                  as Map<String, dynamic>;
                          return AchievementBadge(
                            title: achievement['title'] ?? '',
                            icon: _getAchievementIcon(
                              achievement['type'] ?? '',
                            ),
                            color: _getAchievementColor(
                              achievement['type'] ?? '',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                SizedBox(height: 40.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFocusTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }

  IconData _getAchievementIcon(String type) {
    switch (type) {
      case 'level_up':
        return Icons.trending_up;
      case 'streak':
        return Icons.local_fire_department;
      case 'focus_time':
        return Icons.timer;
      case 'tasks':
        return Icons.task_alt;
      default:
        return Icons.star;
    }
  }

  Color _getAchievementColor(String type) {
    switch (type) {
      case 'level_up':
        return AppColors.primary;
      case 'streak':
        return AppColors.error;
      case 'focus_time':
        return AppColors.success;
      case 'tasks':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
