import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../buddy/models/buddy.dart';
import '../../buddy/data/buddies_data.dart';
import '../../buddy/widgets/buddy_card_widget.dart';
import '../../buddy/screens/buddy_detail_screen.dart';
import '../services/gacha_service.dart';

class DropRatesScreen extends StatefulWidget {
  const DropRatesScreen({super.key});

  @override
  State<DropRatesScreen> createState() => _DropRatesScreenState();
}

class _DropRatesScreenState extends State<DropRatesScreen> {
  List<String> unlockedBuddyIds = [];

  @override
  void initState() {
    super.initState();
    _loadUnlockedBuddies();
  }

  Future<void> _loadUnlockedBuddies() async {
    final inventory = await GachaService.getInventory().first;
    setState(() {
      unlockedBuddyIds = inventory.map((b) => b.id).toList();
    });
  }

  List<Buddy> _getBuddiesByRarity(BuddyRarity rarity) {
    final buddies =
        allBuddies
            .where(
              (b) => b.rarity == rarity && b.source.contains(BuddySource.gacha),
            )
            .toList();
    // Sort by ID (handle both numeric and old string IDs)
    buddies.sort((a, b) {
      final aId = int.tryParse(a.id) ?? 999;
      final bId = int.tryParse(b.id) ?? 999;
      return aId.compareTo(bId);
    });
    return buddies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Available Bobbys', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Common
          _buildRaritySection(
            'Common (85%)',
            BuddyRarity.common,
            _getBuddiesByRarity(BuddyRarity.common),
          ),
          SizedBox(height: 20.h),

          // Rare
          _buildRaritySection(
            'Rare (13%)',
            BuddyRarity.rare,
            _getBuddiesByRarity(BuddyRarity.rare),
          ),
          SizedBox(height: 20.h),

          // Exotic
          _buildRaritySection(
            'Exotic (2%)',
            BuddyRarity.exotic,
            _getBuddiesByRarity(BuddyRarity.exotic),
          ),
          SizedBox(height: 20.h),

          // Legendary
          _buildRaritySection(
            'Unique',
            BuddyRarity.unique,
            _getBuddiesByRarity(BuddyRarity.unique),
          ),
        ],
      ),
    );
  }

  Widget _buildRateChip(String rarity, String rate, Color color) {
    return Column(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(height: 4.h),
        Text(
          rarity,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          rate,
          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }

  Widget _buildRaritySection(
    String title,
    BuddyRarity rarity,
    List<Buddy> buddies,
  ) {
    final color =
        buddies.isNotEmpty ? buddies.first.getRarityColor() : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.85,
          ),
          itemCount: buddies.length,
          itemBuilder: (context, index) {
            final buddy = buddies[index];
            final isUnlocked = unlockedBuddyIds.contains(buddy.id);
            return BuddyCardWidget(
              buddy: buddy,
              isUnlocked: isUnlocked,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => BuddyDetailScreen(
                          buddy: buddy,
                        ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
