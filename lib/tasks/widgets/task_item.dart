import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/task_model.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onUncomplete;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onUncomplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          border: Border.all(
            color:
                task.isCompleted
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: task.isCompleted ? onUncomplete : onComplete,
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        task.isCompleted
                            ? AppColors.success
                            : AppColors.textSecondary,
                    width: 2,
                  ),
                  color:
                      task.isCompleted ? AppColors.success : Colors.transparent,
                ),
                child:
                    task.isCompleted
                        ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                        : null,
              ),
            ),
            SizedBox(width: 12.w),

            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.body.copyWith(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color:
                          task.isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                    ),
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      task.description!,
                      style: AppTextStyles.caption.copyWith(
                        decoration:
                            task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
