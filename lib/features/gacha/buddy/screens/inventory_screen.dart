import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../gacha/services/gacha_service.dart';
import '../models/buddy.dart';
import '../widgets/buddy_card_widget.dart';
import 'buddy_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Buddies', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Buddy>>(
        stream: GachaService.getInventory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📦', style: TextStyle(fontSize: 80.sp)),
                  SizedBox(height: 16.h),
                  Text('No buddies yet!', style: AppTextStyles.heading3),
                  SizedBox(height: 8.h),
                  Text(
                    'Pull some buddies to get started',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          final buddies = snapshot.data!;

          return GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.85,
            ),
            itemCount: buddies.length,
            itemBuilder: (context, index) {
              final buddy = buddies[index];
              return BuddyCardWidget(
                buddy: buddy,
                isUnlocked: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuddyDetailScreen(buddy: buddy),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
