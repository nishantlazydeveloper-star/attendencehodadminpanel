import 'package:get/get.dart';
import '../controllers/slider_controller.dart';
import '../repositories/slider_repository.dart';
import '../providers/slider_provider.dart';

class SliderBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SliderProvider>(SliderProvider());
    Get.put<SliderRepository>(
      SliderRepository(Get.find<SliderProvider>()),
    );
    Get.put<SliderController>(
      SliderController(Get.find<SliderRepository>()),
    );
  }
}
