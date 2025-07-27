import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../widgets/app_button.dart';

class FocusSettingsScreen extends StatefulWidget {
  const FocusSettingsScreen({super.key});

  @override
  State<FocusSettingsScreen> createState() => _FocusSettingsScreenState();
}

class _FocusSettingsScreenState extends State<FocusSettingsScreen> {
  late int _focusDuration;
  late int _breakDuration;
  late int _longBreakDuration;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final userService = Provider.of<UserService>(context, listen: false);
    final prefs = userService.currentUser?.preferences;

    _focusDuration = prefs?.focusDuration ?? 25;
    _breakDuration = prefs?.breakDuration ?? 5;
    _longBreakDuration = prefs?.longBreakDuration ?? 15;
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
          focusDuration: _focusDuration,
          breakDuration: _breakDuration,
          longBreakDuration: _longBreakDuration,
        );

        await userService.updatePreferences(
          uid: userId,
          preferences: updatedPrefs,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Focus Timer Settings', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Focus Duration
            _buildDurationSetting(
              title: 'Focus Duration',
              subtitle: 'Length of each focus session',
              value: _focusDuration,
              min: 5,
              max: 60,
              onChanged: (value) {
                setState(() => _focusDuration = value.toInt());
              },
            ),
            SizedBox(height: 32.h),

            // Break Duration
            _buildDurationSetting(
              title: 'Break Duration',
              subtitle: 'Length of short breaks',
              value: _breakDuration,
              min: 1,
              max: 15,
              onChanged: (value) {
                setState(() => _breakDuration = value.toInt());
              },
            ),
            SizedBox(height: 32.h),

            // Long Break Duration
            _buildDurationSetting(
              title: 'Long Break Duration',
              subtitle: 'Length of long breaks after 4 sessions',
              value: _longBreakDuration,
              min: 10,
              max: 30,
              onChanged: (value) {
                setState(() => _longBreakDuration = value.toInt());
              },
            ),
            SizedBox(height: 32.h),

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
                      'The Pomodoro Technique recommends 25-minute focus sessions with 5-minute breaks.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildDurationSetting({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4.h),
        Text(subtitle, style: AppTextStyles.caption),
        SizedBox(height: 16.h),
        Row(
          children: [
            Text(
              '$value min',
              style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
            ),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withOpacity(0.2),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
