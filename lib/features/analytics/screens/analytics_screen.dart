import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../widgets/focus_chart.dart';
import '../widgets/habit_strength_card.dart';
import '../widgets/achievement_grid.dart';
import '../widgets/stats_summary.dart';
import '../models/analytics_data.dart';
import '../services/analytics_service.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});


  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}


class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  String _selectedPeriod = 'week';


  @override
  Widget build(BuildContext context) {
    final screenPadding = ResponsiveHelper.getScreenPadding(context);


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Analytics', style: AppTextStyles.heading3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<AnalyticsData>(
        stream: _analyticsService.getAnalyticsData(_selectedPeriod),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }


          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No analytics data available',
                style: AppTextStyles.body,
              ),
            );
          }


          final analytics = snapshot.data!;


          return SingleChildScrollView(
            padding: screenPadding,
            child: Center(
              child: Container(
                width: ResponsiveHelper.getContentWidth(context),
                constraints: BoxConstraints(maxWidth: 1200.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),
                    SizedBox(height: 24.h),


                    // Stats Summary
                    StatsSummary(analytics: analytics),
                    SizedBox(height: 24.h),


                    // Focus Time Chart
                    _buildChartSection(
                      'Focus Time Trend',
                      FocusChart(
                        data: analytics.dailyFocusData,
                        period: _selectedPeriod,
                      ),
                    ),
                    SizedBox(height: 24.h),


                    // Habit Strength
                    Text('Habit Strength', style: AppTextStyles.heading3),
                    SizedBox(height: 16.h),
                    HabitStrengthCard(
                      currentStreak: analytics.currentStreak,
                      longestStreak: analytics.longestStreak,
                      consistency: analytics.consistency,
                      totalDays: analytics.totalDays,
                    ),
                    SizedBox(height: 24.h),


                    // Achievements
                    Text('Achievements', style: AppTextStyles.heading3),
                    SizedBox(height: 16.h),
                    AchievementGrid(
                      achievements: analytics.achievements,
                      totalFocusMinutes: analytics.totalFocusMinutes,
                      level: analytics.level,
                    ),
                    SizedBox(height: 24.h),


                    // Insights
                    _buildInsightsSection(analytics),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Week', 'week'),
          _buildPeriodButton('Month', 'month'),
          _buildPeriodButton('Year', 'year'),
        ],
      ),
    );
  }


  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;


    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildChartSection(String title, Widget chart) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          SizedBox(height: 20.h),
          SizedBox(height: 250.h, child: chart),
        ],
      ),
    );
  }


  Widget _buildInsightsSection(AnalyticsData analytics) {
    final insights = _analyticsService.generateInsights(analytics);


    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text('Insights', style: AppTextStyles.heading3),
            ],
          ),
          SizedBox(height: 16.h),
          ...insights
              .map(
                (insight) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    margin: EdgeInsets.only(top: 6.h),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      insight,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .toList(),
        ],
      ),
    );
  }
}



