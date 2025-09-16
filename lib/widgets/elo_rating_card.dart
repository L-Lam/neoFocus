import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_constants.dart';
import '../core/models/rank_system.dart';
import '../core/services/user_service.dart';
import '../features/profile/screens/profile_screen.dart';

class EloRatingCard extends StatelessWidget {
  const EloRatingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null) return const SizedBox.shrink();

        final elo = user.eloRating;
        final currentRank = RankSystem.getRankFromRating(elo.rating);
        final rankProgress = RankSystem.getRankProgress(elo.rating);
        final nextRank = RankSystem.getNextRank(elo.rating);
        final rankColor = currentRank.color;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor.withValues(alpha: 0.1),
                  rankColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header with avatar and name
                Row(
                  children: [
                    // Profile avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: rankColor, width: 2),
                      ),
                      child:
                          user.photoUrl != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.network(
                                  user.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.person,
                                        color: rankColor,
                                        size: 30,
                                      ),
                                ),
                              )
                              : Icon(Icons.person, color: rankColor, size: 30),
                    ),

                    const SizedBox(width: 16),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentRank.name,
                            style: AppTextStyles.body.copyWith(
                              color: rankColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.bio!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Rank badge
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppConstants.smallRadius,
                        ),
                        border: Border.all(color: rankColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          currentRank.badge,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ELO Rating and change indicator
                Row(
                  children: [
                    Text(
                      'ELO Rating: ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${elo.rating}',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress to next rank
                if (nextRank != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to ${nextRank.name}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(rankProgress * 100).toInt()}%',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: rankProgress,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 16),
                ],

                // Profile stats grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildProfileStat(
                              'Total Focus',
                              _formatHours(user.totalFocusMinutes),
                              Icons.timer,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildProfileStat(
                              'Current Streak',
                              '${user.currentStreak} days',
                              Icons.local_fire_department,
                              AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProfileStat(
                              'This Week',
                              '${(elo.weeklyFocusMinutes / 60).toStringAsFixed(1)}h',
                              Icons.calendar_today,
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildProfileStat(
                              'Best Streak',
                              '${user.longestStreak} days',
                              Icons.star,
                              AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tap to view profile hint
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap to view full profile and achievements',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _formatHours(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }
}
