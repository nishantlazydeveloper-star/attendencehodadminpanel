import 'package:adminpanel/core/router/router.dart';
import 'package:adminpanel/features/auth/controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';
import '../../../core/const/colours.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Scaffold(
      backgroundColor: AppColors.bgcolour,
      body: Center(
        child: Container(
          width: 420.w,
          constraints: BoxConstraints(maxWidth: 420.w),
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: AppColors.whiteColour,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.colour2F.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                size: 70.sp,
                color: AppColors.colour2F,
              ),

              SizedBox(height: 16.h),

              Text(
                "Admin Panel",
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.colour2F,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                "Login to continue",
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),

              SizedBox(height: 32.h),

              TextField(
                controller: controller.emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              Obx(
                () => TextField(
                  controller: controller.passwordController,
                  obscureText: controller.obscureText.value,
                  decoration: InputDecoration(
                    hintText: "Password",
                    suffixIcon: IconButton(
                      onPressed: () {
                        controller.obscureText.toggle();
                      },
                      icon: Icon(
                        controller.obscureText.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.colour2F,
                      disabledBackgroundColor: AppColors.colour2F,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            final success = await controller.login();

                            if (success && context.mounted) {
                              context.goNamed(RouteNames.dashboard);
                            }
                          },
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.whiteColour,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
