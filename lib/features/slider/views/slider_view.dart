import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/slider_controller.dart';

class SliderView extends GetView<SliderController> {
  const SliderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slider')),
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
