import 'package:get/get.dart';
import '../repositories/slider_repository.dart';

class SliderController extends GetxController {
  final SliderRepository repo;

  SliderController(this.repo);

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
