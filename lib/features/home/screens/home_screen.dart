import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/elo_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../../focus/screens/focus_timer_screen.dart';
import '../../focus/widgets/pomodoro_animation_widget.dart';
import '../../settings/screens/settings_screen.dart';
import '../../gacha/gacha/screens/gacha_screen.dart';
import '../../social/screens/social_hub_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenPadding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('NeoFocus', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.textPrimary,
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.currentUserDoc?.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('Error loading user data', style: AppTextStyles.body),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: screenPadding,
            child: Center(
              child: Container(
                width: ResponsiveHelper.getContentWidth(context),
                constraints: BoxConstraints(maxWidth: 800.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(userData),
                    SizedBox(height: 18.h),
                    Text(
                      "Quick Actions",
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w100,
                        fontSize: 24.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildFocusTimerButton(context),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(child: _buildGachaButton(context)),
                        SizedBox(width: 12.w),
                        Expanded(child: _buildSocialHubButton(context)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Profile Card Widget
  Widget _buildProfileCard(Map<String, dynamic> userData) {
    final displayName = userData['displayName'] ?? 'Hero';
    final dailyFocusMinutes = userData['dailyFocusMinutes'] ?? 0;
    final coins = userData['coins'] ?? 0;
    final maxEloRating = userData['maxEloRating'] ?? 0;
    final eloRating = userData['eloRating'] ?? 0;
    final eloDelta = userData['eloDelta'] ?? 0;
    final totalAuraPoints = userData['totalAuraPoints'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.8), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Row
          Row(
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: EloService.getEloRankColor(eloRating),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text("", style: TextStyle(fontSize: 38.sp)),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      EloService.getEloRankTitle(eloRating),
                      style: AppTextStyles.body.copyWith(
                        color: EloService.getEloRankColor(eloRating),
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withOpacity(0.9),
                        size: 18.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$totalAuraPoints',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Aura Points',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white.withOpacity(0.9),
                        size: 18.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatMinutes(dailyFocusMinutes),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Focus Time',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 18.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$coins',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Coins',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // ELO Display
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Peak',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$maxEloRating',
                        style: AppTextStyles.body.copyWith(
                          color: EloService.getEloRankColor(maxEloRating),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 5,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Current ELO',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$eloRating',
                        style: AppTextStyles.heading3.copyWith(
                          color: EloService.getEloRankColor(eloRating),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 4,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        eloDelta >= 0 ? Icons.trending_up : Icons.trending_down,
                        color:
                            eloDelta >= 0 ? AppColors.success : AppColors.error,
                        size: 20.sp,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${eloDelta >= 0 ? '+' : ''}$eloDelta',
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              eloDelta >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Focus Timer Button Widget
  Widget _buildFocusTimerButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FocusTimerScreen()),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 180.h,
        child: Stack(
          children: [
            Opacity(
              opacity: 0.3,
              child: const PomodoroAnimationWidget(isSessionActive: false),
            ),
            Positioned(
              top: 20.h,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(Icons.play_circle_filled, size: 64.sp),
                  SizedBox(height: 12.h),
                  Text('Start Focus Quest', style: AppTextStyles.heading3),
                  SizedBox(height: 8.h),
                  Text(
                    'Begin your journey to productivity',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Gacha Button Widget
  Widget _buildGachaButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GachaScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, color: AppColors.error, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'Buddy Finder',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Social Hub Button Widget
  Widget _buildSocialHubButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SocialHubScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.largeRadius),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, color: AppColors.primary, size: 48.sp),
            SizedBox(height: 12.h),
            Text(
              'Social Hub',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Utility
  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }
}
