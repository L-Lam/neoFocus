import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/gacha_item.dart';
import 'gacha_item_card.dart';

class GachaPullResultDialog extends StatefulWidget {
  final List<GachaItem> items;

  const GachaPullResultDialog({
    super.key,
    required this.items,
  });

  @override
  State<GachaPullResultDialog> createState() => _GachaPullResultDialogState();
}

class _GachaPullResultDialogState extends State<GachaPullResultDialog> {

  @override
  Widget build(BuildContext context) {
    final isSinglePull = widget.items.length == 1;
    final bestItem = widget.items.reduce((a, b) => 
        a.rarity.index > b.rarity.index ? a : b);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.largeRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRarityColor(bestItem.rarity),
                            _getRarityColor(bestItem.rarity).withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppConstants.largeRadius),
                          topRight: Radius.circular(AppConstants.largeRadius),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isSinglePull ? 'New Antique!' : '${widget.items.length} New Antiques!',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          if (!isSinglePull) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Rarest: ${bestItem.rarityDisplayName}',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Items
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: isSinglePull
                            ? _buildSingleItemView()
                            : _buildMultiItemView(),
                      ),
                    ),

                    // Close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                            ),
                          ),
                          child: Text(
                            'Awesome!',
                            style: AppTextStyles.button,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
  }

  Widget _buildSingleItemView() {
    final item = widget.items.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _getRarityColor(item.rarity).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: _getRarityColor(item.rarity),
              width: 3,
            ),
          ),
          child: Icon(
            Icons.pets,
            size: 60,
            color: _getRarityColor(item.rarity),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          item.name,
          style: AppTextStyles.heading3.copyWith(
            color: _getRarityColor(item.rarity),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getRarityColor(item.rarity),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item.rarityDisplayName.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.description,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMultiItemView() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return GachaItemCard(item: item);
      },
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
}