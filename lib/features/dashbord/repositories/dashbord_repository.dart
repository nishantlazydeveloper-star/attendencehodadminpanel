import '../providers/dashbord_provider.dart';

class DashbordRepository {
  final DashbordProvider provider;

  DashbordRepository(this.provider);

  Future<void> example() async {
    return provider.example();
  }
}
