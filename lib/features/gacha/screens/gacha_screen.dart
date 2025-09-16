import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/gacha_item.dart';
import '../../../core/services/gacha_service.dart';
import '../../../core/services/user_service.dart';
import '../widgets/gacha_item_card.dart';
import '../widgets/gacha_pull_result_dialog.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late GachaService _gachaService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _gachaService = context.read<GachaService>();
    _gachaService.loadUserItems();
  }

  void _showWhiteFlash() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white,
      builder: (context) => Container(),
    );
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Antique Gacha', style: AppTextStyles.heading2),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Gacha'),
            Tab(text: 'Collection'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPullTab(),
          _buildCollectionTab(),
        ],
      ),
    );
  }

  Widget _buildPullTab() {
    return Consumer<GachaService>(
      builder: (context, gachaService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              
              // Gacha Banner
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Antique Gacha',
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Collect rare antiques and vintage treasures!',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Pull Buttons
              Column(
                children: [
                  // Single Pull
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: gachaService.isLoading ? null : _performSinglePull,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                        ),
                      ),
                      child: gachaService.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.casino),
                                const SizedBox(width: 8),
                                Text(
                                  'Single Pull (Free)',
                                  style: AppTextStyles.button,
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Multi Pull
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: gachaService.isLoading ? null : _performMultiPull,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome),
                          const SizedBox(width: 8),
                          Text(
                            '10x Pull (Free)',
                            style: AppTextStyles.button,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Drop Rates
              _buildDropRates(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollectionTab() {
    return Consumer<GachaService>(
      builder: (context, gachaService, child) {
        if (gachaService.userItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'No antiques collected yet',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try your luck with a gacha pull!',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Collection header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              margin: const EdgeInsets.all(AppConstants.defaultPadding),
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
              child: Row(
                children: [
                  Icon(Icons.collections, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Antique Collection',
                    style: AppTextStyles.heading3,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${gachaService.userItems.length} antiques',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Antiques grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: gachaService.userItems.length,
                itemBuilder: (context, index) {
                  final item = gachaService.userItems[index];
                  return GachaItemCard(item: item);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropRates() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drop Rates',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 12),
          _buildRateRow('Common', '60%', AppColors.textSecondary),
          _buildRateRow('Rare', '30%', AppColors.primary),
          _buildRateRow('Epic', '8%', AppColors.warning),
          _buildRateRow('Legendary', '2%', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildRateRow(String rarity, String rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(rarity, style: AppTextStyles.body),
            ],
          ),
          Text(rate, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _performSinglePull() async {
    final item = await _gachaService.performSinglePull();
    if (item != null && mounted) {
      // Show white flash for rare items
      if (item.isRareOrBetter) {
        _showWhiteFlash();
        await Future.delayed(const Duration(milliseconds: 400));
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => GachaPullResultDialog(items: [item]),
        );
      }
    }
  }

  Future<void> _performMultiPull() async {
    final items = await _gachaService.performMultiPull();
    if (items.isNotEmpty && mounted) {
      // Show white flash if any rare items
      final hasRareItem = items.any((item) => item.isRareOrBetter);
      if (hasRareItem) {
        _showWhiteFlash();
        await Future.delayed(const Duration(milliseconds: 400));
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => GachaPullResultDialog(items: items),
        );
      }
    }
  }
}