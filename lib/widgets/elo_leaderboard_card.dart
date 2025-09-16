import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_constants.dart';
import '../core/models/elo_rating.dart';
import '../core/models/rank_system.dart';
import '../core/services/firebase_service.dart';

class EloLeaderboardCard extends StatelessWidget {
  const EloLeaderboardCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.leaderboard, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('Top Focusers', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseService.firestore
                    .collection('users')
                    .orderBy('eloRating', descending: true)
                    .limit(5)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No rankings yet',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children:
                    snapshot.data!.docs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final data = doc.data() as Map<String, dynamic>;

                      final displayName = data['displayName'] ?? 'Anonymous';
                      final eloRating = data['eloRating'] as int? ?? 1000;
                      final currentRank = RankSystem.getRankFromRating(
                        eloRating,
                      );
                      final rankColor = currentRank.color;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            // Rank position
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    index < 3
                                        ? [
                                          Colors.amber,
                                          Colors.grey,
                                          Colors.brown,
                                        ][index]
                                        : AppColors.textHint,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Rank badge
                            Text(
                              currentRank.badge,
                              style: const TextStyle(fontSize: 20),
                            ),

                            const SizedBox(width: 8),

                            // Name and title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentRank.name,
                                    style: AppTextStyles.caption.copyWith(
                                      color: rankColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Rating
                            Text(
                              '$eloRating',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
