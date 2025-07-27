import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/user_service.dart';
import '../../../widgets/app_button.dart';

class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  final _appController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void dispose() {
    _appController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final blockedApps = userService.currentUser?.preferences.blockedApps ?? [];
    final blockedWebsites =
        userService.currentUser?.preferences.blockedWebsites ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Blocked Apps & Websites', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'These apps and websites will be blocked during focus sessions.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Blocked Apps Section
            Text('Blocked Apps', style: AppTextStyles.heading3),
            SizedBox(height: 16.h),

            // Add App Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _appController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Enter app name',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                IconButton(
                  onPressed: () async {
                    if (_appController.text.trim().isNotEmpty) {
                      await userService.addBlockedApp(
                        _appController.text.trim(),
                      );
                      _appController.clear();
                    }
                  },
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 20.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Blocked Apps List
            if (blockedApps.isEmpty)
              Center(
                child: Text(
                  'No blocked apps yet',
                  style: AppTextStyles.bodySmall,
                ),
              )
            else
              ...blockedApps.map(
                (app) => _buildBlockedItem(
                  title: app,
                  onDelete: () => userService.removeBlockedApp(app),
                  icon: Icons.apps,
                ),
              ),

            SizedBox(height: 32.h),

            // Blocked Websites Section
            Text('Blocked Websites', style: AppTextStyles.heading3),
            SizedBox(height: 16.h),

            // Add Website Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _websiteController,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Enter website URL',
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                IconButton(
                  onPressed: () async {
                    if (_websiteController.text.trim().isNotEmpty) {
                      await userService.addBlockedWebsite(
                        _websiteController.text.trim(),
                      );
                      _websiteController.clear();
                    }
                  },
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 20.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Blocked Websites List
            if (blockedWebsites.isEmpty)
              Center(
                child: Text(
                  'No blocked websites yet',
                  style: AppTextStyles.bodySmall,
                ),
              )
            else
              ...blockedWebsites.map(
                (website) => _buildBlockedItem(
                  title: website,
                  onDelete: () => userService.removeBlockedWebsite(website),
                  icon: Icons.language,
                ),
              ),

            SizedBox(height: 32.h),

            // Popular Apps Suggestions
            Text(
              'Popular Apps to Block',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16.h),

            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  [
                        'Instagram',
                        'Facebook',
                        'TikTok',
                        'Twitter',
                        'YouTube',
                        'Reddit',
                        'Snapchat',
                        'Discord',
                      ]
                      .map(
                        (app) => _buildSuggestionChip(
                          app,
                          () => userService.addBlockedApp(app),
                          blockedApps.contains(app),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedItem({
    required String title,
    required VoidCallback onDelete,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(child: Text(title, style: AppTextStyles.body)),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.close, size: 20.sp, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, VoidCallback onTap, bool isAdded) {
    return GestureDetector(
      onTap: isAdded ? null : onTap,
      child: Chip(
        label: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isAdded ? AppColors.textHint : AppColors.primary,
          ),
        ),
        backgroundColor:
            isAdded ? AppColors.divider : AppColors.primary.withOpacity(0.1),
      ),
    );
  }
}
