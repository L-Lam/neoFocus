import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/analytics_data.dart';

class FocusChart extends StatelessWidget {
  final List<DailyFocusData> data;
  final String period;

  const FocusChart({super.key, required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('No data available', style: AppTextStyles.bodySmall),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.divider, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35.w,
              interval: _getYInterval(),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22.h,
              interval: _getXInterval(data.length, period),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length || value < 0) {
                  return const SizedBox();
                }

                final date = data[value.toInt()].date;
                String label = _getDateLabel(date, period, value.toInt());

                return Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _getSpots(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.primary,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.textPrimary,
            tooltipPadding: EdgeInsets.all(8.w),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot spot) {
                final date = data[spot.x.toInt()].date;
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} min',
                  TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          touchSpotThreshold: 10,
        ),
      ),
    );
  }

  String _getDateLabel(DateTime date, String period, int index) {
    switch (period) {
      case 'week':
        return DateFormat('E').format(date).substring(0, 2);
      case 'month':
        // Show every 5th day
        if (index % 5 == 0) {
          return DateFormat('d').format(date);
        }
        return '';
      case 'year':
        // Show every 3rd month
        if (index % 90 == 0) {
          return DateFormat('MMM').format(date).substring(0, 3);
        }
        return '';
      default:
        return DateFormat('E').format(date).substring(0, 2);
    }
  }

  static double _getXInterval(int dataLength, String period) {
    switch (period) {
      case 'week':
        return 1;
      case 'month':
        return 5;
      case 'year':
        return 30;
      default:
        return 1;
    }
  }

  double _getYInterval() {
    final maxY = _getMaxY();
    if (maxY <= 60) return 15;
    if (maxY <= 120) return 30;
    if (maxY <= 240) return 60;
    return 120;
  }

  List<FlSpot> _getSpots() {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.minutes.toDouble());
    }).toList();
  }

  double _getMaxY() {
    if (data.isEmpty) return 60;
    final maxMinutes = data
        .map((d) => d.minutes)
        .reduce((a, b) => a > b ? a : b);
    // Add 20% padding
    return (maxMinutes * 1.2).ceilToDouble();
  }
}
