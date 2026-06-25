import 'package:get/get.dart';
import '../controllers/dashbord_controller.dart';
import '../repositories/dashbord_repository.dart';
import '../providers/dashbord_provider.dart';

class DashbordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DashbordProvider>(DashbordProvider());
    Get.put<DashbordRepository>(
      DashbordRepository(Get.find<DashbordProvider>()),
    );
    Get.put<DashbordController>(
      DashbordController(Get.find<DashbordRepository>()),
    );
  }
}
