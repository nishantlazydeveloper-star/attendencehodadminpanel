import 'package:adminpanel/features/auth/providers%2013-05-55-571/auth_provider.dart';
import 'package:adminpanel/features/auth/repositories%2013-05-59-503/auth_repository.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthProvider>(AuthProvider());
    Get.put<AuthRepository>(AuthRepository(Get.find<AuthProvider>()));
    Get.put<AuthController>(AuthController(Get.find<AuthRepository>()));
  }
}
