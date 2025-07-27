import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../widgets/app_button.dart';
import '../widgets/settings_tile.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late bool _notificationsEnabled;
  late String _reminderTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final userService = Provider.of<UserService>(context, listen: false);
    final prefs = userService.currentUser?.preferences;

    _notificationsEnabled = prefs?.notificationsEnabled ?? true;
    _reminderTime = prefs?.focusReminderTime ?? '09:00';
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      final userId = authService.user?.uid;

      if (userId != null) {
        final currentPrefs = userService.currentUser!.preferences;
        final updatedPrefs = currentPrefs.copyWith(
          notificationsEnabled: _notificationsEnabled,
          focusReminderTime: _reminderTime,
        );

        await userService.updatePreferences(
          uid: userId,
          preferences: updatedPrefs,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification settings saved'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _selectTime() async {
    final timeParts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _reminderTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notification Settings', style: AppTextStyles.heading3),
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
            // Master Switch
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    size: 24.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Notifications',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Receive reminders and updates',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Notification Types
            Text(
              'Notification Types',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16.h),

            _buildNotificationOption(
              icon: Icons.timer,
              title: 'Session Reminders',
              subtitle: 'Get notified when it\'s time to focus',
              enabled: _notificationsEnabled,
            ),

            _buildNotificationOption(
              icon: Icons.celebration,
              title: 'Achievement Alerts',
              subtitle: 'Celebrate your accomplishments',
              enabled: _notificationsEnabled,
            ),

            _buildNotificationOption(
              icon: Icons.insights,
              title: 'Daily Summary',
              subtitle: 'Review your daily progress',
              enabled: _notificationsEnabled,
            ),

            SizedBox(height: 32.h),

            // Daily Reminder Time
            Text(
              'Daily Focus Reminder',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16.h),

            InkWell(
              onTap: _notificationsEnabled ? _selectTime : null,
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                  border: Border.all(
                    color:
                        _notificationsEnabled
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color:
                          _notificationsEnabled
                              ? AppColors.primary
                              : AppColors.textHint,
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'Remind me at',
                        style: AppTextStyles.body.copyWith(
                          color:
                              _notificationsEnabled
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : AppColors.textHint,
                        ),
                      ),
                    ),
                    Text(
                      _reminderTime,
                      style: AppTextStyles.body.copyWith(
                        color:
                            _notificationsEnabled
                                ? AppColors.primary
                                : AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // Save Button
            AppButton(
              text: 'Save Settings',
              onPressed: _saveSettings,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: enabled ? AppColors.primary : AppColors.textHint,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color:
                        enabled
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : AppColors.textHint,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        enabled ? AppColors.textSecondary : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            size: 20.sp,
            color: enabled ? AppColors.success : AppColors.divider,
          ),
        ],
      ),
    );
  }
}
