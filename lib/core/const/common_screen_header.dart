import 'package:adminpanel/core/const/common_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonScreenHeader extends StatelessWidget {
  const CommonScreenHeader({
    super.key,
    required this.fallbackRouteName,
    this.bottomSpacing = 40,
  });

  final String fallbackRouteName;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          12.verticalSpace,
          CommonBackButton(fallbackRouteName: fallbackRouteName),
          bottomSpacing.verticalSpace,
        ],
      ),
    );
  }
}
