import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/task_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/task_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../widgets/task_item.dart';
import '../widgets/create_task_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late TaskService _taskService;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _taskService = TaskService();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Today';
    } else if (selected == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showCreateTaskDialog() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId == null) return;

    // Use the selected date instead of today
    final xpTaskCount = await _taskService.getXPTaskCountForDate(
      userId,
      _selectedDate,
    );
    final canCreateXPTask = xpTaskCount < TaskService.maxDailyXPTasks;

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => CreateTaskDialog(
            selectedDate: _selectedDate,
            canCreateXPTask: canCreateXPTask,
            remainingXPTasks: TaskService.maxDailyXPTasks - xpTaskCount,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.user?.uid;
    final screenPadding = ResponsiveHelper.getScreenPadding(context);

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view tasks')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Daily Tasks', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: AppColors.textPrimary,
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.symmetric(
              horizontal: screenPadding.left,
              vertical: 16.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => _changeDate(-1),
                  color: AppColors.textPrimary,
                ),
                Column(
                  children: [
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTextStyles.heading3,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _changeDate(1),
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.getUserTasksForDate(userId, _selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                final tasks = snapshot.data ?? [];
                final xpTasks = tasks.where((t) => t.givesXP).toList();
                final regularTasks = tasks.where((t) => !t.givesXP).toList();

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64.sp,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No tasks for this day',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Tap the + button to create a task',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: screenPadding,
                  children: [
                    // XP Tasks Section
                    if (xpTasks.isNotEmpty) ...[
                      _buildSectionHeader(
                        'XP Tasks',
                        '${xpTasks.length}/${TaskService.maxDailyXPTasks} tasks',
                        AppColors.primary,
                      ),
                      SizedBox(height: 8.h),
                      ...xpTasks.map(
                        (task) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: TaskItem(
                            task: task,
                            onComplete:
                                () => _taskService.completeTask(userId, task),
                            onUncomplete:
                                () => _taskService.uncompleteTask(userId, task),
                            onDelete:
                                () => _taskService.deleteTask(userId, task.id),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Regular Tasks Section
                    if (regularTasks.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Regular Tasks',
                        'No XP rewards',
                        AppColors.textSecondary,
                      ),
                      SizedBox(height: 8.h),
                      ...regularTasks.map(
                        (task) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: TaskItem(
                            task: task,
                            onComplete:
                                () => _taskService.completeTask(userId, task),
                            onUncomplete:
                                () => _taskService.uncompleteTask(userId, task),
                            onDelete:
                                () => _taskService.deleteTask(userId, task.id),
                          ),
                        ),
                      ),
                    ],

                    // Add extra spacing at bottom
                    SizedBox(height: 80.h),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
            ),
          ],
        ),
        Text(subtitle, style: AppTextStyles.caption.copyWith(color: color)),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Task System', style: AppTextStyles.heading3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works:',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                _buildInfoItem(
                  '• First ${TaskService.maxDailyXPTasks} tasks each day give ${TaskService.defaultXPReward} XP',
                ),
                _buildInfoItem(
                  '• Additional tasks can be created without XP rewards',
                ),
                _buildInfoItem(
                  '• Complete tasks to level up and unlock achievements',
                ),
                _buildInfoItem('• XP tasks reset daily at midnight'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Got it',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: AppTextStyles.bodySmall),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
