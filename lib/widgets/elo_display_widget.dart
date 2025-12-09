import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/services/elo_service.dart';

class EloDisplayWidget extends StatelessWidget {
  final int eloRating;
  final int eloRank;
  final bool showRankIcon;
  final bool isCompact;

  const EloDisplayWidget({
    super.key,
    required this.eloRating,
    required this.eloRank,
    this.showRankIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = EloService.getEloRankColor(eloRank);

    if (isCompact) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [rankColor.withOpacity(0.3), rankColor.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rankColor.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showRankIcon) ...[
              Text(
                EloService.getEloRankIcon(eloRank),
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              eloRating.toString(),
              style: AppTextStyles.bodySmall.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [rankColor.withOpacity(0.2), rankColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rankColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showRankIcon) ...[
                Text(
                  EloService.getEloRankIcon(eloRank),
                  style: TextStyle(fontSize: 28.sp),
                ),
                SizedBox(width: 8.w),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ELO Rating',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    eloRating.toString(),
                    style: AppTextStyles.heading2.copyWith(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$eloRank',
              style: AppTextStyles.body.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ELO Progress Chart Widget
class EloProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>> eloHistory;

  const EloProgressChart({super.key, required this.eloHistory});

  @override
  Widget build(BuildContext context) {
    if (eloHistory.isEmpty) {
      return Center(
        child: Text('No ELO history yet', style: AppTextStyles.bodySmall),
      );
    }

    // Get last 7 entries
    final recentHistory =
        eloHistory.length > 7
            ? eloHistory.sublist(eloHistory.length - 7)
            : eloHistory;

    final maxElo = recentHistory.fold<int>(
      0,
      (max, entry) => entry['newElo'] > max ? entry['newElo'] : max,
    );
    final minElo = recentHistory.fold<int>(
      9999,
      (min, entry) => entry['newElo'] < min ? entry['newElo'] : min,
    );
    final range = maxElo - minElo;

    return Container(
      height: 100.h,
      padding: EdgeInsets.all(8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            recentHistory.map((entry) {
              final elo = entry['newElo'] as int;
              final normalizedHeight = range > 0 ? (elo - minElo) / range : 0.5;
              final change = elo - (entry['oldElo'] as int);
              final isPositive = change >= 0;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${isPositive ? '+' : ''}$change',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color:
                              isPositive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        height: 60.h * normalizedHeight + 10.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors:
                                isPositive
                                    ? [
                                      AppColors.success,
                                      AppColors.success.withOpacity(0.7),
                                    ]
                                    : [
                                      AppColors.error,
                                      AppColors.error.withOpacity(0.7),
                                    ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
