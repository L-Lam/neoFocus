import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/constants/app_constants.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;

    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: isOutlined ? Colors.transparent : buttonColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          child: Container(
            padding:
                padding ??
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              border:
                  isOutlined ? Border.all(color: buttonColor, width: 2) : null,
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
            child: Center(
              child:
                  isLoading
                      ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOutlined ? buttonColor : Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        text,
                        style: AppTextStyles.button.copyWith(
                          color: isOutlined ? buttonColor : Colors.white,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
