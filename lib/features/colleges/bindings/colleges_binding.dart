import 'package:get/get.dart';
import '../controllers/colleges_controller.dart';
import '../repositories/colleges_repository.dart';
import '../providers/colleges_provider.dart';

class CollegesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<CollegesProvider>(CollegesProvider());
    Get.put<CollegesRepository>(
      CollegesRepository(Get.find<CollegesProvider>()),
    );
    Get.put<CollegesController>(
      CollegesController(Get.find<CollegesRepository>()),
    );
  }
}
