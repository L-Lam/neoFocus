import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/app_button.dart';
import '../models/challenge_model.dart';
import '../screens/challenge_details.dart';
import '../services/social_service.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final bool isSeasonalThemed;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.isSeasonalThemed = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().user?.uid;
    final isParticipant = challenge.participants.contains(currentUserId);
    final progress =
        isParticipant && currentUserId != null
            ? challenge.participantProgress[currentUserId] ?? 0
            : 0;
    final progressPercent =
        challenge.targetMinutes > 0
            ? (progress / challenge.targetMinutes).clamp(0.0, 1.0)
            : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border:
            isSeasonalThemed
                ? Border.all(
                  color: _getSeasonalColor(challenge.seasonalTheme),
                  width: 2,
                )
                : null,
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
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color:
                  isSeasonalThemed
                      ? _getSeasonalColor(
                        challenge.seasonalTheme,
                      ).withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.defaultRadius),
                topRight: Radius.circular(AppConstants.defaultRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getChallengeIcon(challenge.type),
                  color:
                      isSeasonalThemed
                          ? _getSeasonalColor(challenge.seasonalTheme)
                          : AppColors.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _getChallengeTypeLabel(challenge.type),
                        style: AppTextStyles.caption.copyWith(
                          color:
                              isSeasonalThemed
                                  ? _getSeasonalColor(challenge.seasonalTheme)
                                  : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: AppColors.warning, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(
                        '${challenge.rewardPoints}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.description, style: AppTextStyles.bodySmall),
                SizedBox(height: 16.h),
                // Progress
                if (isParticipant) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Progress',
                                  style: AppTextStyles.caption,
                                ),
                                Text(
                                  '$progress / ${challenge.targetMinutes} min',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            LinearProgressIndicator(
                              value: progressPercent,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSeasonalThemed
                                    ? _getSeasonalColor(challenge.seasonalTheme)
                                    : AppColors.primary,
                              ),
                              minHeight: 8.h,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
                // Participants
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${challenge.participants.length} participants',
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    Text(
                      _getTimeRemaining(challenge.endDate),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Action button
                // Replace the join button section in the ChallengeCard widget:

                // Action button
                if (!isParticipant)
                  AppButton(
                    text: 'Join Challenge',
                    onPressed: () async {
                      try {
                        await SocialService.joinChallenge(challenge.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully joined "${challenge.title}"!',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  )
                else if (challenge.status == ChallengeStatus.active)
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Participating',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      AppButton(
                        text: 'View Details',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChallengeDetailsScreen(
                                    challenge: challenge,
                                  ),
                            ),
                          );
                        },
                        isOutlined: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Color _getSeasonalColor(String? theme) {
    switch (theme) {
      case 'winter':
        return Colors.blue;
      case 'spring':
        return Colors.green;
      case 'summer':
        return Colors.orange;
      case 'fall':
        return Colors.brown;
      default:
        return AppColors.primary;
    }
  }

  String _getTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Ended';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else {
      return '${difference.inMinutes} minutes left';
    }
  }
}
