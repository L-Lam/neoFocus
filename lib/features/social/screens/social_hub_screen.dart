import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_helper.dart';
import '../widgets/social_hub_timer.dart';  // ADD THIS IMPORT
import 'friends_screen.dart';
import 'challenges_screen.dart';
import 'leaderboard_screen.dart';
import 'blog_screen.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FriendsScreen(),
    const ChallengesScreen(),
    const LeaderboardScreen(),
    const BlogScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.people, label: 'Friends'),
    _NavItem(icon: Icons.flag, label: 'Challenges'),
    _NavItem(icon: Icons.leaderboard, label: 'Leaderboard'),
    _NavItem(icon: Icons.forum, label: 'Community'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(  // ADD THIS ENTIRE APPBAR
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            'Social Hub',
            style: AppTextStyles.heading3,
          ),
          actions: [
            const SocialHubTimerWidget(),
            SizedBox(width: 16.w),
          ],
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textHint,
            selectedLabelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.caption,
            items:
            _navItems
                .map(
                  (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
                .toList(),
          ),
        ),
      );
    }

    // Desktop/Tablet layout
    return Scaffold(
      body: Row(
        children: [
          // Side navigation
          Container(
            width: 250.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 32.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(  // MODIFY THIS SECTION
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Social Hub', style: AppTextStyles.heading2),
                      const SocialHubTimerWidget(),  // ADD TIMER HERE TOO
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                ...List.generate(
                  _navItems.length,
                      (index) => _SideNavItem(
                    icon: _navItems[index].icon,
                    label: _navItems[index].label,
                    isSelected: _selectedIndex == index,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          border:
          isSelected
              ? Border(left: BorderSide(color: AppColors.primary, width: 4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


