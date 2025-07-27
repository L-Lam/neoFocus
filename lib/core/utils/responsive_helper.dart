import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static double getContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 600.w;
    } else if (isTablet(context)) {
      return 500.w;
    } else {
      return double.infinity;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return EdgeInsets.symmetric(horizontal: 48.w, vertical: 24.h);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h);
    } else {
      return EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h);
    }
  }
}
