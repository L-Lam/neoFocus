import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../models/analytics_data.dart';

class AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final int totalFocusMinutes;
  final int level;

  const AchievementGrid({
    super.key,
    required this.achievements,
    required this.totalFocusMinutes,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    // Get all possible achievements and mark which are unlocked
    final allAchievements = _getAllAchievements();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 3,
        childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.0 : 1.2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: allAchievements.length,
      itemBuilder: (context, index) {
        final achievement = allAchievements[index];
        final isUnlocked = achievements.any((a) => a.id == achievement.id);

        return _AchievementCard(
          achievement: achievement,
          isUnlocked: isUnlocked,
        );
      },
    );
  }

  List<Achievement> _getAllAchievements() {
    return [
      Achievement(
        id: 'first_session',
        title: 'First Step',
        description: 'Complete your first focus session',
        icon: Icons.flag,
        isUnlocked: totalFocusMinutes >= 25,
      ),
      Achievement(
        id: 'week_streak',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        isUnlocked: false, // Check from user data
      ),
      Achievement(
        id: 'focus_master',
        title: 'Focus Master',
        description: 'Complete 100 focus sessions',
        icon: Icons.psychology,
        isUnlocked: false, // Check from sessions count
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete a session before 7 AM',
        icon: Icons.wb_sunny,
        isUnlocked: false, // Check from session times
      ),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Complete a session after 10 PM',
        icon: Icons.nightlight,
        isUnlocked: false, // Check from session times
      ),
      Achievement(
        id: 'level_10',
        title: 'Dedicated',
        description: 'Reach level 10',
        icon: Icons.grade,
        isUnlocked: level >= 10,
      ),
    ];
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({required this.achievement, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.surface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(
          color:
              isUnlocked
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.divider,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            size: 28.sp,
            color: isUnlocked ? AppColors.primary : AppColors.textHint,
          ),
          SizedBox(height: 6.h),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color:
                  isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 10.sp,
              color: isUnlocked ? AppColors.textSecondary : AppColors.textHint,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
