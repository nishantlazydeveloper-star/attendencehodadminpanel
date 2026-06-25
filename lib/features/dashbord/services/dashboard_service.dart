import 'dart:async';

import 'package:adminpanel/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../colleges/models/college.dart';
import '../../colleges/services/colleges_service.dart';

class DashboardCounts {
  const DashboardCounts({
    required this.colleges,
    required this.hods,
    required this.teachers,
    required this.students,
    required this.appUsers,
  });

  final int colleges;
  final int hods;
  final int teachers;
  final int students;
  final int appUsers;
}

class DashboardPerson {
  const DashboardPerson({
    required this.name,
    required this.meta,
    required this.code,
    required this.email,
    required this.college,
    required this.role,
    required this.phone,
    required this.status,
  });

  final String name;
  final String meta;
  final String code;
  final String email;
  final String college;
  final String role;
  final String phone;
  final String status;
}

class CollegePeopleGroup {
  const CollegePeopleGroup({required this.college, required this.people});

  final String college;
  final List<DashboardPerson> people;
}

class DashboardAuthException implements Exception {
  const DashboardAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DashboardService {
  final _supabase = SupabaseService.client;
  final _collegesService = CollegesService();

  RealtimeChannel? _countChannel;
  StreamController<DashboardCounts>? _countController;
  var _loadingCounts = false;
  var _reloadCountsAgain = false;

  Stream<DashboardCounts> watchCounts() {
    final controller = StreamController<DashboardCounts>.broadcast(
      onListen: () {
        _subscribeToCountChanges();
        _loadCounts();
      },
    );
    _countController = controller;
    return controller.stream;
  }

  Stream<List<CollegePeopleGroup>> watchCollegeWisePeople(
    String table, {
    String? role,
  }) {
    return Stream.multi((controller) {
      List<College>? colleges;
      List<Map<String, dynamic>>? peopleRows;

      void emit() {
        final rows = peopleRows;
        if (rows == null) return;
        controller.add(_groupPeople(rows, colleges ?? const [], table));
      }

      final collegesSubscription = _collegesService.watchColleges().listen((
        value,
      ) {
        colleges = value;
        emit();
      }, onError: controller.addError);

      final peopleStream = _supabase
          .from(table)
          .stream(primaryKey: _primaryKey(table));
      final filteredPeopleStream = role == null
          ? peopleStream
          : peopleStream.eq('role', role);
      final peopleSubscription = filteredPeopleStream
          .map((rows) => rows.map(Map<String, dynamic>.from).toList())
          .listen((value) {
            peopleRows = value;
            emit();
          }, onError: controller.addError);

      controller.onCancel = () async {
        await collegesSubscription.cancel();
        await peopleSubscription.cancel();
      };
    });
  }

  Stream<List<DashboardPerson>> watchPeople(String table) {
    return _supabase.from(table).stream(primaryKey: _primaryKey(table)).map((
      rows,
    ) {
      return rows
          .map((row) => _person(Map<String, dynamic>.from(row), table))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> dispose() async {
    await _countController?.close();
    final channel = _countChannel;
    if (channel != null) {
      await _supabase.removeChannel(channel);
    }
  }

  void _subscribeToCountChanges() {
    if (_countChannel != null) return;
    var channel = _supabase.channel('dashboard-counts');
    for (final table in _countTables.keys) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _loadCounts(),
      );
    }
    _countChannel = channel..subscribe();
  }

  Future<void> _loadCounts() async {
    if (_loadingCounts) {
      _reloadCountsAgain = true;
      return;
    }
    _loadingCounts = true;
    try {
      _requireAdminSession();
      final counts = DashboardCounts(
        colleges: await _count('colleges'),
        hods: await _countRole('hod'),
        teachers: await _countRole('teacher'),
        students: await _countRole('student'),
        appUsers: await _count('app_users'),
      );
      _addCounts(counts);
    } catch (error, stackTrace) {
      _addCountError(error, stackTrace);
    } finally {
      _loadingCounts = false;
      if (_reloadCountsAgain) {
        _reloadCountsAgain = false;
        unawaited(_loadCounts());
      }
    }
  }

  Future<int> _count(String table) {
    return _supabase.from(table).count(CountOption.exact);
  }

  Future<int> _countRole(String role) {
    return _supabase
        .from('app_users')
        .count(CountOption.exact)
        .eq('role', role);
  }

  void _requireAdminSession() {
    if (_supabase.auth.currentSession != null) return;
    throw const DashboardAuthException(
      'Admin session is required. Please sign in again.',
    );
  }

  void _addCounts(DashboardCounts counts) {
    final controller = _countController;
    if (controller == null || controller.isClosed) return;
    controller.add(counts);
  }

  void _addCountError(Object error, StackTrace stackTrace) {
    final controller = _countController;
    if (controller == null || controller.isClosed) return;
    controller.addError(error, stackTrace);
  }

  List<CollegePeopleGroup> _groupPeople(
    List<Map<String, dynamic>> rows,
    List<College> colleges,
    String table,
  ) {
    final collegeById = {for (final college in colleges) college.id: college};
    final collegeByName = {
      for (final college in colleges) college.name.toLowerCase(): college,
    };
    final collegeByCode = {
      for (final college in colleges) college.code.toLowerCase(): college,
    };
    final grouped = <String, List<DashboardPerson>>{};

    for (final row in rows) {
      final collegeValue = _text(row, [
        'college',
        'college_name',
        'collegeName',
        'college_code',
        'college_id',
        'collegeId',
      ]);
      final college = _collegeLabel(
        collegeValue,
        collegeById,
        collegeByName,
        collegeByCode,
      );
      grouped
          .putIfAbsent(college, () => [])
          .add(_person(row, table, college: college));
    }

    final groups = grouped.entries.map((entry) {
      final people = entry.value..sort((a, b) => a.name.compareTo(b.name));
      return CollegePeopleGroup(college: entry.key, people: people);
    }).toList()..sort((a, b) => a.college.compareTo(b.college));
    return groups;
  }

  String _collegeLabel(
    String value,
    Map<String, College> byId,
    Map<String, College> byName,
    Map<String, College> byCode,
  ) {
    if (value.isEmpty) return 'Unassigned College';
    final key = value.toLowerCase();
    final college = byId[value] ?? byName[key] ?? byCode[key];
    return college?.label ?? value;
  }

  DashboardPerson _person(
    Map<String, dynamic> row,
    String table, {
    String? college,
  }) {
    final role = _text(row, ['role']);
    final fallbackName = role == 'student' || table == 'students'
        ? 'Unnamed student'
        : 'Unnamed';
    final contact = _text(row, ['email', 'phone', 'mobile']);
    return DashboardPerson(
      name: _name(row) ?? (contact.isEmpty ? fallbackName : contact),
      meta: _text(row, [
        'department',
        'class',
        'section',
        'subject',
        'designation',
        'role',
      ]),
      code: _text(row, [
        'teacher_code',
        'teacher_id',
        'student_code',
        'student_id',
        'roll_no',
        'roll_number',
        'admission_no',
        'employee_id',
        'user_code',
      ]),
      email: _text(row, ['email']),
      college:
          college ??
          _text(row, [
            'college',
            'college_name',
            'collegeName',
            'college_code',
            'college_id',
            'collegeId',
          ]),
      role: role,
      phone: _text(row, ['phone', 'mobile', 'phone_number', 'mobile_number']),
      status: _text(row, ['status', 'is_active']),
    );
  }

  String? _name(Map<String, dynamic> row) {
    final direct = _text(row, [
      'name',
      'full_name',
      'teacher_name',
      'student_name',
      'display_name',
    ]);
    if (direct.isNotEmpty) return direct;
    final first = _text(row, ['first_name', 'firstname']);
    final last = _text(row, ['last_name', 'lastname']);
    final combined = [first, last].where((part) => part.isNotEmpty).join(' ');
    return combined.isEmpty ? null : combined;
  }

  String _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  List<String> _primaryKey(String table) {
    return table == 'app_users' ? ['auth_user_id'] : ['id'];
  }
}

const _countTables = {
  'colleges': 'Colleges',
  'hods': 'HODs',
  'teachers': 'Teachers',
  'students': 'Students',
  'app_users': 'App Users',
};
