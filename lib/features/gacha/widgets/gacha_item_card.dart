import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/gacha_item.dart';

class GachaItemCard extends StatelessWidget {
  final GachaItem item;
  final VoidCallback? onTap;

  const GachaItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          border: Border.all(
            color: _getRarityColor(item.rarity),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getRarityColor(item.rarity).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRarityColor(item.rarity).withOpacity(0.1),
                      _getRarityColor(item.rarity).withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.defaultRadius - 2),
                    topRight: Radius.circular(AppConstants.defaultRadius - 2),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.pets, //awdawd
                        size: 48,
                        color: _getRarityColor(item.rarity),
                      ),
                    ),
                    // Rarity indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRarityColor(item.rarity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.rarityDisplayName.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.obtainedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Obtained ${_formatDate(item.obtainedAt!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.common:
        return AppColors.textSecondary;
      case GachaRarity.rare:
        return AppColors.primary;
      case GachaRarity.epic:
        return AppColors.warning;
      case GachaRarity.legendary:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}