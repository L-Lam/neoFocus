import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('About NeoFocus', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // App Icon
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer, size: 60.sp, color: AppColors.primary),
            ),
            SizedBox(height: 24.h),

            // App Name
            Text('NeoFocus', style: AppTextStyles.heading1),
            SizedBox(height: 8.h),

            // Version
            Text(
              'Version ${_packageInfo?.version ?? '1.0.0'}',
              style: AppTextStyles.bodySmall,
            ),
            SizedBox(height: 32.h),

            // Description
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppConstants.largeRadius),
              ),
              child: Column(
                children: [
                  Text(
                    'Your Productivity Companion',
                    style: AppTextStyles.heading3,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'NeoFocus helps you stay productive with the Pomodoro Technique, task management, and distraction blocking. Build better habits and achieve your goals one focus session at a time.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Features
            _buildFeatureItem(
              icon: Icons.timer,
              title: 'Pomodoro Timer',
              description: 'Stay focused with 25-minute work sessions',
            ),
            _buildFeatureItem(
              icon: Icons.task_alt,
              title: 'Task Management',
              description: 'Organize your daily tasks and earn XP',
            ),
            _buildFeatureItem(
              icon: Icons.block,
              title: 'Distraction Blocking',
              description: 'Block apps and websites during focus time',
            ),
            _buildFeatureItem(
              icon: Icons.insights,
              title: 'Progress Tracking',
              description: 'Monitor your productivity with detailed stats',
            ),

            SizedBox(height: 32.h),

            // Credits
            Text(
              'Made with ❤️ for productivity enthusiasts',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text('© 2024 NeoFocus', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24.sp, color: AppColors.primary),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
