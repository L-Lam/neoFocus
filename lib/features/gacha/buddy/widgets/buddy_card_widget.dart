import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/buddy.dart';
import '../screens/buddy_detail_screen.dart';

class BuddyCardWidget extends StatelessWidget {
  final Buddy buddy;
  final bool isUnlocked;
  final VoidCallback? onTap; // Optional: if null, navigates to detail screen

  const BuddyCardWidget({
    super.key,
    required this.buddy,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = LayoutBuilder(
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
              // Image or locked state (fixed size, doesn't shrink)
              SizedBox(
                height: constraints.maxHeight * 0.6, // Fixed 60% of card height
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

              // Name or locked (flexible, can shrink)
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isUnlocked ? buddy.name : '???',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
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
    );

    // Wrap in GestureDetector with appropriate onTap
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuddyDetailScreen(buddy: buddy),
              ),
            );
          },
      child: cardContent,
    );
  }
}
