import 'package:adminpanel/core/services/supabase_service.dart';
import 'package:adminpanel/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hod.dart';

class HodServiceException implements Exception {
  const HodServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HodService {
  SupabaseClient get _supabase => SupabaseService.client;

  Stream<List<Hod>> watchHods() {
    AppLogger.log(
      'HodService',
      'Starting Supabase realtime HOD list',
      data: {'schema': 'public', 'table': 'hods'},
    );
    return _supabase.from('hods').stream(primaryKey: ['id']).order('name').map((
      rows,
    ) {
      final hods = rows.map(Hod.fromMap).toList();
      AppLogger.log(
        'HodService',
        'Realtime HOD list received',
        data: {'count': hods.length},
      );
      return hods;
    });
  }

  Stream<Hod?> watchHod(String id) {
    final lookupColumn = _isUuid(id) ? 'id' : 'hod_code';
    AppLogger.log(
      'HodService',
      'Starting Supabase realtime HOD details',
      data: {'table': 'hods', lookupColumn: id},
    );
    return _supabase
        .from('hods')
        .stream(primaryKey: ['id'])
        .eq(lookupColumn, id)
        .map((rows) => rows.isEmpty ? null : Hod.fromMap(rows.first));
  }

  Future<String> createHod({
    required String name,
    required String email,
    required String password,
    required String college,
    required String department,
  }) async {
    final response = await _invoke({
      'action': 'create',
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'college': college.trim(),
      'department': department.trim(),
    });
    return response['id']?.toString() ?? '';
  }

  Future<void> updateHod({
    required String id,
    required String name,
    required String email,
    required String college,
    required String department,
  }) async {
    await _invoke({
      'action': 'update',
      'id': id,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'college': college.trim(),
      'department': department.trim(),
    });
  }

  Future<void> setActive(String id, bool isActive) async {
    await _invoke({'action': 'set_active', 'id': id, 'is_active': isActive});
  }

  Future<void> deleteHod(String id) async {
    final response = await _invoke({'action': 'delete', 'id': id});
    if (response['success'] == true) return;

    throw HodServiceException(
      _responseMessage(response) ?? 'HOD delete was not confirmed.',
    );
  }

  Future<void> repairLegacyHods() async {
    await _invoke({'action': 'repair_legacy'});
  }

  Future<Map<String, dynamic>> _invoke(Map<String, Object?> body) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const HodServiceException(
        'Admin session is required. Please sign in again.',
      );
    }

    final safeBody = AppLogger.redactPassword(body);
    AppLogger.log(
      'HodService',
      'Supabase HOD function call started',
      data: {
        'function': 'manage-hod',
        'adminUid': session.user.id,
        'request': safeBody,
      },
    );

    try {
      final response = await _supabase.functions.invoke(
        'manage-hod',
        body: body,
      );
      final data = response.data;
      final status = response.status;
      AppLogger.log(
        'HodService',
        'Supabase HOD function call succeeded',
        data: {'status': status, 'adminUid': session.user.id, 'response': data},
      );
      if (data is! Map) {
        throw const HodServiceException(
          'The HOD service returned an invalid response.',
        );
      }
      final mapped = Map<String, dynamic>.from(data);
      if (mapped['success'] == false) {
        throw HodServiceException(
          _responseMessage(mapped) ?? 'Unable to complete the HOD operation.',
        );
      }
      return mapped;
    } on FunctionException catch (error, stackTrace) {
      AppLogger.error(
        'HodService',
        'Supabase HOD function call failed',
        error,
        stackTrace,
        data: {
          'status': error.status,
          'reason': error.reasonPhrase,
          'details': error.details,
          'request': safeBody,
        },
      );
      throw HodServiceException(_functionMessage(error));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(
        'HodService',
        'Supabase HOD database operation failed',
        error,
        stackTrace,
        data: {
          'code': error.code,
          'message': error.message,
          'details': error.details,
          'hint': error.hint,
        },
      );
      throw HodServiceException(error.message);
    } catch (error, stackTrace) {
      AppLogger.error(
        'HodService',
        'Unexpected HOD operation failure',
        error,
        stackTrace,
        data: {'request': safeBody},
      );
      if (error is HodServiceException) rethrow;
      throw HodServiceException(error.toString());
    }
  }

  String _functionMessage(FunctionException error) {
    final details = error.details;
    if (details is Map && details['error'] != null) {
      return details['error'].toString();
    }
    if (details is Map && details['message'] != null) {
      return details['message'].toString();
    }
    if (details is Map && details['code'] == 'NOT_FOUND') {
      return 'The manage-hod Supabase Edge Function is not deployed.';
    }
    if (details is String && details.isNotEmpty) return details;
    if (error.status == 404) {
      return 'The manage-hod Supabase Edge Function is not deployed.';
    }
    return error.reasonPhrase ?? 'Unable to complete the HOD operation.';
  }

  String? _responseMessage(Map<String, dynamic> response) {
    final message = response['message'] ?? response['error'];
    final text = message?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
