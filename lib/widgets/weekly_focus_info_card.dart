import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_constants.dart';
import '../core/models/rank_system.dart';
import '../core/services/user_service.dart';

class WeeklyFocusInfoCard extends StatelessWidget {
  const WeeklyFocusInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null) return const SizedBox.shrink();

        // Fix: Extract the rating value from the EloRating object
        final eloRating = user.eloRating.rating; // Changed this line
        final currentRank = RankSystem.getRankFromRating(eloRating);
        final nextRank = RankSystem.getNextRank(eloRating);

        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
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
                children: [
                  Icon(Icons.trending_up, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text('ELO Ranking System', style: AppTextStyles.heading3),
                ],
              ),

              const SizedBox(height: 16),

              // Current ELO and rank
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Rating',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        currentRank.badge,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$eloRating ELO',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Next rank requirement
              if (nextRank != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        nextRank.badge,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next: ${nextRank.name}',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Need ${nextRank.minRating - eloRating} more ELO',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],

              // ELO earning examples
              Text(
                'How to Earn ELO:',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              _buildFocusExample('1 hour/week', 'Beginner (1000)', '🌱'),
              _buildFocusExample('3 hours/week', 'Dedicated (1400)', '💪'),
              _buildFocusExample('7 hours/week', 'Committed (2000)', '🔥'),
              _buildFocusExample('14 hours/week', 'Expert (2400)', '⚡'),

              const SizedBox(height: 12),

              // Info
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ELO increases with focus sessions and achievements',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusExample(String time, String rank, String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            '→ $rank',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}