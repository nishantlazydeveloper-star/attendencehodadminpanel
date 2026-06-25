import 'package:adminpanel/features/auth/repositories%2013-05-59-503/auth_repository.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthRepository repo;

  AuthController(this.repo);

  final isLoading = false.obs;

  Future<void> exampleCall() async {
    isLoading.value = true;
    try {
      await repo.example();
    } finally {
      isLoading.value = false;
    }
  }
}
