import 'package:adminpanel/features/auth/repository/login_repo.dart';
import 'package:adminpanel/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final AdminRepository _repository = AdminRepository();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  RxBool isLoading = false.obs;
  RxBool obscureText = true.obs;

  Future<bool> login() async {
    try {
      isLoading.value = true;

      await _repository.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Get.snackbar(
        'Success',
        'Login successful',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'LoginController',
        'Login request failed',
        error,
        stackTrace,
      );
      Get.snackbar(
        'Login Failed',
        error is AdminLoginException ? error.message : error.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
