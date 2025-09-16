import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/task_service.dart';
import '../../../widgets/app_button.dart';

class CreateTaskDialog extends StatefulWidget {
  final DateTime selectedDate;

  const CreateTaskDialog({super.key, required this.selectedDate});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskService = TaskService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId != null) {
      try {
        await _taskService.createTask(
          userId: userId,
          title: _titleController.text.trim(),
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          scheduledFor: widget.selectedDate,
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating task: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        constraints: BoxConstraints(maxWidth: 400.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create Task', style: AppTextStyles.heading3),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Title field
            Text(
              'Task Title',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Enter task title',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
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
            SizedBox(height: 16.h),

            // Description field
            Text(
              'Description (Optional)',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _descriptionController,
              style: AppTextStyles.body,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a description...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
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

            SizedBox(height: 24.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    isOutlined: true,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton(
                    text: 'Create',
                    onPressed: _createTask,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
