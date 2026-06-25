import 'package:adminpanel/core/const/colours.dart';
import 'package:adminpanel/core/const/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.autovalidateMode,
    this.readOnly = false,
    this.onTap,
  });

  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode? autovalidateMode;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: autovalidateMode,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontSize: 14.sp,
        fontFamily: Fonts.inteMedium,
        color: AppColors.colour17,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14.sp,
          fontFamily: Fonts.inteRegular,
          color: AppColors.colour6B,
        ),
        prefixIcon: Icon(prefixIcon, size: 20.sp, color: AppColors.colour6B),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixTap,
                icon: Icon(suffixIcon, size: 20.sp, color: AppColors.colour6B),
              ),
        filled: true,
        fillColor: AppColors.whiteColour,
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: AppColors.colour6B.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.colour3F),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: AppColors.colour6B.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({super.key, required this.assetPath, this.onTap});

  final String assetPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        assetPath,
        width: 60.w,
        height: 60.h,
        fit: BoxFit.contain,
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.colour6B.withValues(alpha: 0.2)),
        ),
        12.horizontalSpace,
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: Fonts.inteRegular,
            color: AppColors.colour6B,
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Divider(color: AppColors.colour6B.withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}
