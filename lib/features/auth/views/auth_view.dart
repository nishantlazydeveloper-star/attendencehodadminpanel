import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth')),
      body: Center(
        child: Obx(() => controller.isLoading.value
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: controller.exampleCall,
                child: const Text('Run'),
              )),
      ),
    );
  }
}
