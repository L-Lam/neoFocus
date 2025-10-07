import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/buddy.dart';

class BuddyCardWidget extends StatelessWidget {
  final Buddy buddy;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const BuddyCardWidget({
    super.key,
    required this.buddy,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / 180;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              border: Border.all(
                color: buddy.getRarityColor().withValues(alpha: 0.5),
                width: 2 * scale,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image or locked state
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(8 * scale),
                    child:
                        isUnlocked
                            ? Image.asset(
                              buddy.image,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  '?',
                                  style: TextStyle(fontSize: 60 * scale),
                                );
                              },
                            )
                            : Text('?', style: TextStyle(fontSize: 60 * scale)),
                  ),
                ),

                // Name or locked
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                  child: Text(
                    isUnlocked ? buddy.name : '???',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4 * scale),

                // Rarity badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: buddy.getRarityColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Text(
                    isUnlocked ? buddy.rarity.name.toUpperCase() : '???',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: buddy.getRarityColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 12 * scale),
              ],
            ),
          );
        },
      ),
    );
  }
}
