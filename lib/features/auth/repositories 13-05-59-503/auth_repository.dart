import 'package:adminpanel/features/auth/providers%2013-05-55-571/auth_provider.dart';

class AuthRepository {
  final AuthProvider provider;

  AuthRepository(this.provider);

  Future<void> example() async {
    return provider.example();
  }
}
