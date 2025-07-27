import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/focus_session.dart';

class SessionTypeSelector extends StatelessWidget {
  final SessionType selectedType;
  final Function(SessionType) onTypeChanged;

  const SessionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Row(
        children: [
          _buildTypeButton(
            type: SessionType.focus,
            label: 'Focus',
            icon: Icons.timer,
          ),
          _buildTypeButton(
            type: SessionType.shortBreak,
            label: 'Short Break',
            icon: Icons.coffee,
          ),
          _buildTypeButton(
            type: SessionType.longBreak,
            label: 'Long Break',
            icon: Icons.self_improvement,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required SessionType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedType == type;
    final color = _getColorForType(type);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: AnimatedContainer(
          duration: AppConstants.animationDuration,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.smallRadius),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textHint,
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? color : AppColors.textHint,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppColors.primary;
      case SessionType.shortBreak:
        return AppColors.success;
      case SessionType.longBreak:
        return AppColors.focusBreak;
    }
  }
}
