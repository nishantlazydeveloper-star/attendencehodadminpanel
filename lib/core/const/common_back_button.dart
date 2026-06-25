import 'package:adminpanel/core/const/colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CommonBackButton extends StatelessWidget {
  const CommonBackButton({super.key, this.fallbackRouteName});

  final String? fallbackRouteName;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            context.pop();
            return;
          }
          if (fallbackRouteName != null) {
            context.goNamed(fallbackRouteName!);
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: AppColors.whiteColour,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.colour2F.withValues(alpha: 0.05),
                blurRadius: 14.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.sp,
            color: AppColors.colour2F,
          ),
        ),
      ),
    );
  }
}
