import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/loading_indicator.dart';
import '../models/challenge_model.dart';
import '../models/friend_model.dart';
import '../services/social_service.dart';

class ChallengeDetailsScreen extends StatelessWidget {
  final Challenge challenge;

  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseService.firestore
                .collection('challenges')
                .doc(challenge.id)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Challenge not found'));
          }

          final updatedChallenge = Challenge.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 200.h,
                pinned: true,
                backgroundColor: _getChallengeColor(updatedChallenge),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    updatedChallenge.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getChallengeColor(updatedChallenge),
                          _getChallengeColor(updatedChallenge).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getChallengeIcon(updatedChallenge.type),
                            size: 64.sp,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getChallengeTypeLabel(updatedChallenge.type),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Challenge Info Card
                      _ChallengeInfoCard(challenge: updatedChallenge),
                      SizedBox(height: 16.h),
                      // Progress Section
                      _ProgressSection(challenge: updatedChallenge),
                      SizedBox(height: 16.h),
                      // Participants Leaderboard
                      _ParticipantsLeaderboard(challenge: updatedChallenge),
                      SizedBox(height: 16.h),
                      // Actions
                      _ActionsSection(challenge: updatedChallenge),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getChallengeColor(Challenge challenge) {
    if (challenge.type == ChallengeType.seasonal) {
      switch (challenge.seasonalTheme) {
        case 'winter':
          return Colors.blue;
        case 'spring':
          return Colors.green;
        case 'summer':
          return Colors.orange;
        case 'fall':
          return Colors.brown;
      }
    }

    switch (challenge.type) {
      case ChallengeType.daily:
        return AppColors.primary;
      case ChallengeType.weekly:
        return AppColors.primaryDark;
      case ChallengeType.friend:
        return AppColors.success;
      case ChallengeType.group:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return Icons.today;
      case ChallengeType.weekly:
        return Icons.date_range;
      case ChallengeType.friend:
        return Icons.people;
      case ChallengeType.group:
        return Icons.groups;
      case ChallengeType.seasonal:
        return Icons.ac_unit;
    }
  }

  String _getChallengeTypeLabel(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return 'Daily Challenge';
      case ChallengeType.weekly:
        return 'Weekly Challenge';
      case ChallengeType.friend:
        return 'Friend Challenge';
      case ChallengeType.group:
        return 'Group Challenge';
      case ChallengeType.seasonal:
        return 'Seasonal Event';
    }
  }
}

class _ChallengeInfoCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeInfoCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
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
          Text('Challenge Details', style: AppTextStyles.heading3),
          SizedBox(height: 16.h),
          Text(challenge.description, style: AppTextStyles.body),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.timer,
                  label: 'Target',
                  value: '${challenge.targetMinutes} min',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.star,
                  label: 'Reward',
                  value: '${challenge.rewardPoints} pts',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_today,
                  label: 'Start',
                  value: _formatDate(challenge.startDate),
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.event,
                  label: 'End',
                  value: _formatDate(challenge.endDate),
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _getStatusColor(challenge).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(challenge),
                  color: _getStatusColor(challenge),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _getTimeRemaining(challenge.endDate),
                  style: AppTextStyles.body.copyWith(
                    color: _getStatusColor(challenge),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  Color _getStatusColor(Challenge challenge) {
    final now = DateTime.now();
    if (challenge.endDate.isBefore(now)) {
      return AppColors.textSecondary;
    } else if (challenge.endDate.difference(now).inHours < 24) {
      return AppColors.error;
    } else {
      return AppColors.success;
    }
  }

  IconData _getStatusIcon(Challenge challenge) {
    final now = DateTime.now();
    if (challenge.endDate.isBefore(now)) {
      return Icons.check_circle;
    } else if (challenge.endDate.difference(now).inHours < 24) {
      return Icons.warning;
    } else {
      return Icons.access_time;
    }
  }

  String _getTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Challenge Ended';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} days remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours remaining';
    } else {
      return '${difference.inMinutes} minutes remaining';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Challenge challenge;

  const _ProgressSection({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;
    final myProgress =
        currentUserId != null
            ? challenge.participantProgress[currentUserId] ?? 0
            : 0;
    final progressPercent =
        challenge.targetMinutes > 0
            ? (myProgress / challenge.targetMinutes).clamp(0.0, 1.0)
            : 0.0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
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
          Text('Your Progress', style: AppTextStyles.heading3),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$myProgress minutes',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: progressPercent,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressPercent >= 1.0 ? AppColors.success : AppColors.primary,
            ),
            minHeight: 12.h,
          ),
          SizedBox(height: 8.h),
          Text(
            '${challenge.targetMinutes - myProgress} minutes to go',
            style: AppTextStyles.caption,
          ),
          if (progressPercent >= 1.0) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Challenge Completed! 🎉',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantsLeaderboard extends StatelessWidget {
  final Challenge challenge;

  const _ParticipantsLeaderboard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final sortedParticipants =
        challenge.participantProgress.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Leaderboard', style: AppTextStyles.heading3),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${challenge.participants.length} participants',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          if (sortedParticipants.isEmpty)
            Center(
              child: Text(
                'No participants yet',
                style: AppTextStyles.bodySmall,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedParticipants.length,
              itemBuilder: (context, index) {
                final entry = sortedParticipants[index];
                return _LeaderboardItem(
                  rank: index + 1,
                  userId: entry.key,
                  progress: entry.value,
                  targetMinutes: challenge.targetMinutes,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final int rank;
  final String userId;
  final int progress;
  final int targetMinutes;

  const _LeaderboardItem({
    required this.rank,
    required this.userId,
    required this.progress,
    required this.targetMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;
    final isCurrentUser = userId == currentUserId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseService.firestore.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final displayName = userData['displayName'] ?? 'Unknown';
        final progressPercent =
            targetMinutes > 0
                ? (progress / targetMinutes).clamp(0.0, 1.0)
                : 0.0;

        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color:
                isCurrentUser
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border:
                isCurrentUser
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: _getRankColor(rank).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      rank <= 3
                          ? Icon(
                            Icons.emoji_events,
                            color: _getRankColor(rank),
                            size: 18.sp,
                          )
                          : Text(
                            '#$rank',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                ),
              ),
              SizedBox(width: 12.w),
              // Name
              Expanded(
                child: Text(
                  displayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser ? AppColors.primary : null,
                  ),
                ),
              ),
              // Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$progress min',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textHint;
    }
  }
}

class _ActionsSection extends StatelessWidget {
  final Challenge challenge;

  const _ActionsSection({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;
    final isParticipant = challenge.participants.contains(currentUserId);
    final isCreator = challenge.createdBy == currentUserId;

    return Column(
      children: [
        if (!isParticipant && challenge.status == ChallengeStatus.active)
          AppButton(
            text: 'Join Challenge',
            onPressed: () async {
              try {
                await SocialService.joinChallenge(challenge.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully joined challenge!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        if (challenge.type == ChallengeType.friend ||
            challenge.type == ChallengeType.group)
          AppButton(
            text: 'Invite Friends',
            onPressed: () {
              // TODO: Implement invite friends
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite feature coming soon!')),
              );
            },
            isOutlined: true,
          ),
      ],
    );
  }
}
