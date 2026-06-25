import 'package:adminpanel/core/const/colours.dart';
import 'package:adminpanel/core/const/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

void showSocialAuthSnackbar() {
  debugPrint('[SocialAuthSnackbar] Callback entered');
  debugPrint(
    '[SocialAuthSnackbar] Get.context available: ${Get.context != null}',
  );
  debugPrint(
    '[SocialAuthSnackbar] Get.overlayContext available: '
    '${Get.overlayContext != null}',
  );
  debugPrint(
    '[SocialAuthSnackbar] Get navigator state available: '
    '${Get.key.currentState != null}',
  );

  const title = 'Social sign-in unavailable';
  const message =
      'Please sign in with the credentials provided by your administrator.';

  final context = Get.context;
  final isDark =
      context != null && Theme.of(context).brightness == Brightness.dark;
  final foreground = isDark ? Colors.white : AppColors.colour17;
  final surface = isDark
      ? const Color(0xE6263333)
      : AppColors.whiteColour.withValues(alpha: 0.88);
  final accent = isDark ? const Color(0xFF9BC7C2) : AppColors.colour3F;

  if (Get.isSnackbarOpen) {
    debugPrint('[SocialAuthSnackbar] Closing currently open snackbar');
    Get.closeCurrentSnackbar();
  }

  debugPrint(
    '[SocialAuthSnackbar] Before Get.snackbar',
  );
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    snackStyle: SnackStyle.FLOATING,
    margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    borderRadius: 20.r,
    borderWidth: 1,
    borderColor: accent.withValues(alpha: 0.18),
    backgroundColor: surface,
    colorText: foreground,
    barBlur: 18,
    duration: const Duration(seconds: 4),
    animationDuration: const Duration(milliseconds: 350),
    forwardAnimationCurve: Curves.easeOutCubic,
    reverseAnimationCurve: Curves.easeInCubic,
    boxShadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
        blurRadius: 28.r,
        offset: Offset(0, 10.h),
      ),
    ],
    icon: Container(
      width: 42.w,
      height: 42.w,
      margin: EdgeInsets.only(left: 4.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Icon(Icons.info_outline_rounded, color: accent, size: 22.sp),
    ),
    titleText: Text(
      title,
      style: TextStyle(
        color: foreground,
        fontFamily: Fonts.manropeSemibold,
        fontSize: 15.sp,
        height: 1.2,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        color: foreground.withValues(alpha: 0.72),
        fontFamily: Fonts.inteRegular,
        fontSize: 13.sp,
        height: 1.45,
      ),
    ),
    shouldIconPulse: false,
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
  );
  debugPrint('[SocialAuthSnackbar] After Get.snackbar');
}
