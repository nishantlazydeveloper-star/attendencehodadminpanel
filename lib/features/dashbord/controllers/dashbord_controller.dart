import 'package:get/get.dart';
import '../repositories/dashbord_repository.dart';

class DashbordController extends GetxController {
  final DashbordRepository repo;

  DashbordController(this.repo);

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
