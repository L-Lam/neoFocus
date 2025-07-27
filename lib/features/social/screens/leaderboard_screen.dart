import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/loading_indicator.dart';
import '../services/social_service.dart';
import '../models/friend_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Leaderboard', style: AppTextStyles.heading3),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Global'), Tab(text: 'Friends')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_GlobalLeaderboardTab(), _FriendsLeaderboardTab()],
      ),
    );
  }
}

class _GlobalLeaderboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;

    return StreamBuilder<List<Friend>>(
      stream: SocialService.getGlobalLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isCurrentUser = user.uid == currentUserId;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color:
                    isCurrentUser
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    isCurrentUser
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                leading: _RankBadge(rank: index + 1),
                title: Text(
                  user.displayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser ? AppColors.primary : null,
                  ),
                ),
                subtitle: Text(
                  'Level ${user.level} • ${user.currentStreak} day streak',
                  style: AppTextStyles.caption,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${user.totalFocusMinutes}',
                      style: AppTextStyles.heading3.copyWith(
                        color:
                            isCurrentUser
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                    ),
                    Text('minutes', style: AppTextStyles.caption),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FriendsLeaderboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;

    return StreamBuilder<List<Friend>>(
      stream: SocialService.getFriendsLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80.sp,
                  color: AppColors.textHint,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No friends yet',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Add friends to see their progress!',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                leading: _RankBadge(rank: index + 1),
                title: Text(
                  friend.displayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Level ${friend.level} • ${friend.currentStreak} day streak',
                  style: AppTextStyles.caption,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${friend.totalFocusMinutes}',
                      style: AppTextStyles.heading3,
                    ),
                    Text('minutes', style: AppTextStyles.caption),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData? icon;

    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Gold
        icon = Icons.emoji_events;
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Silver
        icon = Icons.emoji_events;
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        icon = Icons.emoji_events;
        break;
      default:
        badgeColor = AppColors.textHint;
        icon = null;
    }

    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: badgeColor, width: 2),
      ),
      child: Center(
        child:
            icon != null
                ? Icon(icon, color: badgeColor, size: 24.sp)
                : Text(
                  '#$rank',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
      ),
    );
  }
}
