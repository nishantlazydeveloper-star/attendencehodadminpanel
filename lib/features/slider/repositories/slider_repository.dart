import '../providers/slider_provider.dart';

class SliderRepository {
  final SliderProvider provider;

  SliderRepository(this.provider);

  Future<void> example() async {
    return provider.example();
  }
}
