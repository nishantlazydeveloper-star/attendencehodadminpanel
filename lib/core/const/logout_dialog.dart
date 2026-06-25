import 'package:adminpanel/core/const/colours.dart';
import 'package:adminpanel/core/const/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showLogoutDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  return showThemedConfirmationDialog(
    context: context,
    barrierLabel: 'Logout',
    title: 'Logout',
    message: 'Are you sure you want to logout?',
    confirmText: 'Logout',
    icon: Icons.logout_rounded,
    onConfirm: onConfirm,
  );
}

Future<void> showThemedConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmText,
  required IconData icon,
  required VoidCallback onConfirm,
  String barrierLabel = 'Confirm',
}) {
  var isConfirming = false;
  var isDismissing = false;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320.w,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.whiteColour,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.colour17.withValues(alpha: 0.14),
                  blurRadius: 28.r,
                  offset: Offset(0, 14.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xffD93025).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24.sp,
                    color: const Color(0xffD93025),
                  ),
                ),
                16.verticalSpace,
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontFamily: Fonts.manropeBold,
                    color: AppColors.colour17,
                  ),
                ),
                8.verticalSpace,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: Fonts.inteRegular,
                    color: AppColors.colour41,
                    height: 1.4,
                  ),
                ),
                22.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46.h,
                        child: OutlinedButton(
                          onPressed: () {
                            if (isConfirming || isDismissing) {
                              return;
                            }

                            final dialogRoute = ModalRoute.of(dialogContext);
                            if (dialogRoute?.isCurrent != true) {
                              return;
                            }

                            isDismissing = true;
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.colour41,
                            side: BorderSide(
                              color: AppColors.colour6B.withValues(alpha: 0.22),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            textStyle: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: Fonts.manropeSemibold,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: SizedBox(
                        height: 46.h,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isConfirming || isDismissing) {
                              return;
                            }

                            final dialogRoute = ModalRoute.of(dialogContext);
                            if (dialogRoute?.isCurrent != true) {
                              return;
                            }

                            isConfirming = true;
                            onConfirm();
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xffD93025),
                            foregroundColor: AppColors.whiteColour,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            textStyle: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: Fonts.manropeSemibold,
                            ),
                          ),
                          child: Text(confirmText),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
