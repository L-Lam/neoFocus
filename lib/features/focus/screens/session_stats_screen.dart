import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/focus_session_service.dart';
import '../../../core/models/session_stats.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../widgets/stats_card.dart';
import '../widgets/session_chart.dart';

class SessionStatsScreen extends StatelessWidget {
  const SessionStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenPadding = ResponsiveHelper.getScreenPadding(context);
    final contentWidth = ResponsiveHelper.getContentWidth(context);

    return ChangeNotifierProvider(
      create: (_) => FocusSessionService(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('Session Statistics', style: AppTextStyles.heading3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<FocusSessionService>(
          builder: (context, sessionService, child) {
            return FutureBuilder<SessionStats>(
              future: sessionService.getSessionStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      'No session data available',
                      style: AppTextStyles.body,
                    ),
                  );
                }

                final stats = snapshot.data!;

                return SingleChildScrollView(
                  padding: screenPadding,
                  child: Center(
                    child: Container(
                      width: contentWidth,
                      constraints: BoxConstraints(maxWidth: 800.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overview Cards
                          Text('Overview', style: AppTextStyles.heading3),
                          SizedBox(height: 16.h),

                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount:
                                ResponsiveHelper.isMobile(context) ? 2 : 4,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                            childAspectRatio: 1.5,
                            children: [
                              StatsCard(
                                title: 'Total Sessions',
                                value: stats.totalSessions.toString(),
                                icon: Icons.timer,
                                color: AppColors.primary,
                              ),
                              StatsCard(
                                title: 'Total Focus',
                                value: '${stats.totalFocusMinutes}m',
                                icon: Icons.access_time,
                                color: AppColors.success,
                              ),
                              StatsCard(
                                title: 'Today',
                                value: '${stats.todayFocusMinutes}m',
                                icon: Icons.today,
                                color: AppColors.warning,
                              ),
                              StatsCard(
                                title: 'Completion',
                                value: '${stats.completionRate}%',
                                icon: Icons.check_circle,
                                color: AppColors.focusActive,
                              ),
                            ],
                          ),

                          SizedBox(height: 32.h),

                          // This Week Stats
                          Text('This Week', style: AppTextStyles.heading3),
                          SizedBox(height: 16.h),

                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppConstants.largeRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildWeekStat(
                                      label: 'Sessions',
                                      value: stats.weekSessions.toString(),
                                    ),
                                    _buildWeekStat(
                                      label: 'Focus Time',
                                      value: '${stats.weekFocusMinutes}m',
                                    ),
                                    _buildWeekStat(
                                      label: 'Avg. Length',
                                      value:
                                          '${stats.averageSessionLength.toStringAsFixed(1)}m',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24.h),

                                // Session Chart
                                SizedBox(
                                  height: 200.h,
                                  child: SessionChart(
                                    weekFocusMinutes: stats.weekFocusMinutes,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Session Types Breakdown
                          Text('Session Types', style: AppTextStyles.heading3),
                          SizedBox(height: 16.h),

                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppConstants.largeRadius,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSessionTypeRow(
                                  type: 'Focus Sessions',
                                  count: stats.sessionsByType['focus'] ?? 0,
                                  total: stats.totalSessions,
                                  color: AppColors.primary,
                                ),
                                SizedBox(height: 16.h),
                                _buildSessionTypeRow(
                                  type: 'Short Breaks',
                                  count:
                                      stats.sessionsByType['shortBreak'] ?? 0,
                                  total: stats.totalSessions,
                                  color: AppColors.success,
                                ),
                                SizedBox(height: 16.h),
                                _buildSessionTypeRow(
                                  type: 'Long Breaks',
                                  count: stats.sessionsByType['longBreak'] ?? 0,
                                  total: stats.totalSessions,
                                  color: AppColors.focusBreak,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekStat({required String label, required String value}) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading2),
        SizedBox(height: 4.h),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildSessionTypeRow({
    required String type,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(type, style: AppTextStyles.body),
            Text('$count sessions', style: AppTextStyles.bodySmall),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8.h,
        ),
      ],
    );
  }
}
