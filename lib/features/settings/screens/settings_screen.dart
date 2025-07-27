import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../widgets/loading_indicator.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import 'focus_settings_screen.dart';
import 'blocked_apps_screen.dart';
import 'about_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userService = Provider.of<UserService>(context);
    final user = userService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: LoadingIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Settings', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Focus Settings Section
            SettingsSection(
              title: 'Focus Settings',
              children: [
                SettingsTile(
                  icon: Icons.timer,
                  title: 'Focus Timer',
                  subtitle: 'Adjust focus and break durations',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FocusSettingsScreen(),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.block,
                  title: 'Blocked Apps & Websites',
                  subtitle: 'Manage your blocklist',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BlockedAppsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Notifications Section
            SettingsSection(
              title: 'Notifications',
              children: [
                SettingsTile(
                  icon: Icons.notifications,
                  title: 'Notification Settings',
                  subtitle: 'Configure alerts and reminders',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // App Settings Section - FIXED

            // Account Section
            SettingsSection(
              title: 'Account',
              children: [
                SettingsTile(
                  icon: Icons.email,
                  title: 'Email',
                  subtitle: user.email,
                  onTap: null, // Non-clickable
                ),
                SettingsTile(
                  icon: Icons.restore,
                  title: 'Reset Progress',
                  subtitle: 'Clear all data and start fresh',
                  textColor: AppColors.error,
                  onTap: () => _showResetDialog(context),
                ),
                SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  textColor: AppColors.error,
                  onTap: () => _showSignOutDialog(context),
                ),
              ],
            ),

            // About Section
            SettingsSection(
              title: 'About',
              children: [
                SettingsTile(
                  icon: Icons.info,
                  title: 'About NeoFocus',
                  subtitle: 'Version, licenses, and more',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Learn how we protect your data',
                  onTap: () {
                    // TODO: Open privacy policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy Policy - Coming Soon'),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  subtitle: 'Read our terms and conditions',
                  onTap: () {
                    // TODO: Open terms of service
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terms of Service - Coming Soon'),
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reset Progress?', style: AppTextStyles.heading3),
            content: Text(
              'This will permanently delete all your data including tasks, achievements, and statistics. This action cannot be undone.',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  final userService = Provider.of<UserService>(
                    context,
                    listen: false,
                  );

                  final userId = authService.user?.uid;
                  if (userId != null) {
                    try {
                      await userService.resetProgress(userId);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Progress reset successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error resetting progress: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text('Reset', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sign Out?', style: AppTextStyles.heading3),
            content: Text(
              'Are you sure you want to sign out?',
              style: AppTextStyles.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.signOut();
                },
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
  }
}
