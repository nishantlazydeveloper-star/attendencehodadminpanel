import 'dart:async';

import 'package:adminpanel/core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/college.dart';

class CollegesService {
  SupabaseClient get _supabase => SupabaseService.client;

  static final _collegesController =
      StreamController<List<College>>.broadcast();
  static StreamSubscription<List<College>>? _collegesSubscription;
  static List<College>? _latestColleges;

  Stream<List<College>> watchColleges() {
    _ensureCollegesSubscription();

    return Stream.multi((controller) {
      final subscription = _collegesController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      final latest = _latestColleges;
      if (latest != null) {
        controller.add(latest);
      }
      controller.onCancel = subscription.cancel;
    });
  }

  Stream<College?> watchCollege(String id) {
    debugPrint('[Colleges][Details][Request] id=$id');
    return _supabase
        .from('colleges')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) {
          debugPrint(
            '[Colleges][Details][StreamRefresh] id=$id rows=${rows.length}',
          );
          return rows.isEmpty ? null : College.fromMap(rows.first);
        });
  }

  Future<College> createCollege({
    required String name,
    required String code,
    required String city,
    required String state,
    required String status,
  }) async {
    final values = {
      'college_name': name.trim(),
      'college_code': code.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'status': status,
    };
    debugPrint('[Colleges][Create][Request] values=$values');
    try {
      final row = await _supabase
          .from('colleges')
          .insert(values)
          .select()
          .single();
      final college = College.fromMap(row);
      debugPrint(
        '[Colleges][Create][Success] affectedRows=1 id=${college.id} '
        'response=$row',
      );
      _upsertCollege(college);
      return college;
    } catch (error) {
      debugPrint('[Colleges][Create][Error] values=$values error=$error');
      rethrow;
    }
  }

  Future<College> updateCollege(
    College college,
    Map<String, Object?> values,
  ) async {
    debugPrint('[Colleges][Edit][Request] id=${college.id} values=$values');
    try {
      final row = await _supabase
          .from('colleges')
          .update(values)
          .eq('id', college.id)
          .select()
          .single();
      final updated = College.fromMap(row);
      debugPrint(
        '[Colleges][Edit][Success] affectedRows=1 id=${updated.id} '
        'response=$row',
      );
      _upsertCollege(updated);
      return updated;
    } catch (error) {
      debugPrint(
        '[Colleges][Edit][Error] id=${college.id} values=$values error=$error',
      );
      rethrow;
    }
  }

  Future<void> deleteCollege(String id) async {
    debugPrint('[Colleges][Delete][Request] id=$id');
    try {
      final response = await _supabase
          .from('colleges')
          .delete()
          .eq('id', id)
          .count(CountOption.exact);
      debugPrint(
        '[Colleges][Delete][Response] id=$id affectedRows=${response.count}',
      );
      if (response.count < 1) {
        throw StateError('College was not found or was already deleted.');
      }
      _removeCollege(id);
      debugPrint('[Colleges][Delete][Success] id=$id');
    } catch (error) {
      debugPrint('[Colleges][Delete][Error] id=$id error=$error');
      rethrow;
    }
  }

  static void _ensureCollegesSubscription() {
    if (_collegesSubscription != null) return;

    debugPrint('[Colleges][List][Request] table=public.colleges primaryKey=id');
    _collegesSubscription = SupabaseService.client
        .from('colleges')
        .stream(primaryKey: ['id'])
        .order('college_name')
        .map(_mapColleges)
        .listen(
          _emitColleges,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('[Colleges][List][StreamError] error=$error');
            _collegesController.addError(error, stackTrace);
          },
        );
  }

  static List<College> _mapColleges(List<Map<String, dynamic>> rows) {
    final colleges = rows.map(College.fromMap).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    debugPrint(
      '[Colleges][List][StreamRefresh] rawRows=${rows.length} '
      'mappedRows=${colleges.length} '
      'ids=${colleges.map((college) => college.id).join(',')}',
    );
    return colleges;
  }

  static void _upsertCollege(College college) {
    final colleges = [...?_latestColleges];
    final index = colleges.indexWhere((item) => item.id == college.id);
    if (index == -1) {
      colleges.add(college);
    } else {
      colleges[index] = college;
    }
    colleges.sort((a, b) => a.name.compareTo(b.name));
    _emitColleges(colleges);
  }

  static void _removeCollege(String id) {
    final latest = _latestColleges;
    if (latest == null) return;

    final colleges = latest.where((college) => college.id != id).toList();
    _emitColleges(colleges);
  }

  static void _emitColleges(List<College> colleges) {
    _latestColleges = List.unmodifiable(colleges);
    _collegesController.add(_latestColleges!);
  }
}
