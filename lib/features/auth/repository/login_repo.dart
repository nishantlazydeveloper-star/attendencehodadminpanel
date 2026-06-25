import 'package:adminpanel/core/services/supabase_service.dart';
import 'package:adminpanel/core/utils/app_logger.dart';
import 'package:adminpanel/features/auth/models/login_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLoginException implements Exception {
  const AdminLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AdminRepository {
  SupabaseClient get _supabase => SupabaseService.client;

  Future<AdminModel?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final request = {'email': normalizedEmail, 'password': password};

    AppLogger.log(
      'AdminLogin',
      'Login start',
      data: AppLogger.redactPassword(request),
    );

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = response.user;

      if (user == null) {
        throw const AdminLoginException(
          'Supabase Auth returned no user after sign-in.',
        );
      }

      AppLogger.log(
        'AdminLogin',
        'Auth success',
        data: {'uid': user.id, 'email': user.email},
      );

      AppLogger.log(
        'AdminLogin',
        'Admin verification started',
        data: {'schema': 'public', 'table': 'admins', 'userId': user.id},
      );

      final adminData = await _supabase
          .from('admins')
          .select('id, email, role, is_active')
          .eq('id', user.id)
          .maybeSingle();

      AppLogger.log(
        'AdminLogin',
        'Admin verification completed',
        data: {'userId': user.id, 'admin': adminData},
      );

      if (adminData == null) {
        await _signOutAfterFailure(
          'No public.admins row exists for user ${user.id}.',
        );
        throw const AdminLoginException(
          'This account is not registered as an admin.',
        );
      }

      final admin = AdminModel.fromMap(adminData, user.id);
      if (admin.role.trim().toLowerCase() != 'admin') {
        await _signOutAfterFailure(
          'Admin role verification failed for user ${user.id}.',
        );
        throw const AdminLoginException(
          'This account does not have the admin role.',
        );
      }

      if (!admin.isActive) {
        await _signOutAfterFailure(
          'Admin account is inactive for user ${user.id}.',
        );
        throw const AdminLoginException('Admin account is inactive.');
      }

      AppLogger.log(
        'AdminLogin',
        'Login success',
        data: {
          'uid': admin.uid,
          'email': admin.email,
          'role': admin.role,
          'isActive': admin.isActive,
        },
      );
      return admin;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error(
        'AdminLogin',
        'Login failure',
        error,
        stackTrace,
        data: {'statusCode': error.statusCode, 'message': error.message},
      );
      throw AdminLoginException(_authMessage(error));
    } on PostgrestException catch (error, stackTrace) {
      await _safeSignOut();
      AppLogger.error(
        'AdminLogin',
        'Login failure during admin verification',
        error,
        stackTrace,
        data: {
          'code': error.code,
          'message': error.message,
          'details': error.details,
          'hint': error.hint,
        },
      );
      throw AdminLoginException(
        'Unable to verify admin access: ${error.message}',
      );
    } catch (error, stackTrace) {
      AppLogger.error('AdminLogin', 'Login failure', error, stackTrace);
      if (error is AdminLoginException) rethrow;
      await _safeSignOut();
      throw AdminLoginException(error.toString());
    }
  }

  Future<void> logout() async {
    AppLogger.log('AdminLogin', 'Supabase sign-out started');
    await _supabase.auth.signOut();
    AppLogger.log('AdminLogin', 'Supabase sign-out completed');
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> _signOutAfterFailure(String reason) async {
    AppLogger.log(
      'AdminLogin',
      'Admin verification rejected; signing out',
      data: {'reason': reason},
    );
    await _safeSignOut();
  }

  Future<void> _safeSignOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error, stackTrace) {
      AppLogger.error(
        'AdminLogin',
        'Sign-out after login failure also failed',
        error,
        stackTrace,
      );
    }
  }

  String _authMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm the admin email before signing in.';
    }
    return error.message;
  }
}
