import 'package:adminpanel/core/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../services/dashboard_service.dart';

class DashbordView extends StatefulWidget {
  const DashbordView({super.key});

  @override
  State<DashbordView> createState() => _DashbordViewState();
}

class _DashbordViewState extends State<DashbordView> {
  final _service = DashboardService();
  late final Stream<DashboardCounts> _countsStream;

  @override
  void initState() {
    super.initState();
    _countsStream = _service.watchCounts();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = GoRouterState.of(context).uri.queryParameters['view'];
    if (view == 'teachers') {
      return _CollegeWisePeopleScreen(
        title: 'College-wise Teachers',
        emptyTitle: 'No teachers found',
        emptyMessage: 'Teachers will appear here once they are added.',
        stream: _service.watchCollegeWisePeople('app_users', role: 'teacher'),
      );
    }
    if (view == 'students') {
      return _CollegeWisePeopleScreen(
        title: 'College-wise Students',
        emptyTitle: 'No students found',
        emptyMessage: 'Students will appear here once they are added.',
        stream: _service.watchCollegeWisePeople('app_users', role: 'student'),
      );
    }
    if (view == 'app-users') {
      return _PeopleScreen(
        title: 'App Users',
        emptyTitle: 'No app users found',
        emptyMessage: 'App users will appear here once they are available.',
        stream: _service.watchPeople('app_users'),
      );
    }
    return _DashboardHome(countsStream: _countsStream);
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({required this.countsStream});

  final Stream<DashboardCounts> countsStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xff173F3E),
              ),
            ),
            SizedBox(height: 24.h),
            StreamBuilder<DashboardCounts>(
              stream: countsStream,
              builder: (context, snapshot) {
                final counts = snapshot.data;
                final error = snapshot.hasError;
                final loading = !snapshot.hasData && !error;
                if (loading) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width >= 1180
                        ? 5
                        : width >= 900
                        ? 4
                        : width >= 680
                        ? 3
                        : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 1.65,
                      children: [
                        _DashboardCard(
                          title: 'Total Colleges',
                          count: error ? '!' : _count(counts!.colleges),
                          icon: Icons.school_outlined,
                          onTap: () => context.go(AppRoutes.colleges),
                        ),
                        _DashboardCard(
                          title: 'Total HODs',
                          count: error ? '!' : _count(counts!.hods),
                          icon: Icons.people_outline,
                          onTap: () => context.go(AppRoutes.hodManagement),
                        ),
                        _DashboardCard(
                          title: 'Total Teachers',
                          count: error ? '!' : _count(counts!.teachers),
                          icon: Icons.badge_outlined,
                          onTap: () => context.go(
                            '${AppRoutes.dashboard}?view=teachers',
                          ),
                        ),
                        _DashboardCard(
                          title: 'Total Students',
                          count: error ? '!' : _count(counts!.students),
                          icon: Icons.groups_outlined,
                          onTap: () => context.go(
                            '${AppRoutes.dashboard}?view=students',
                          ),
                        ),
                        _DashboardCard(
                          title: 'Total App Users',
                          count: error ? '!' : _count(counts!.appUsers),
                          icon: Icons.mobile_friendly_outlined,
                          onTap: () => context.go(
                            '${AppRoutes.dashboard}?view=app-users',
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _count(int value) => value.toString();
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xff173F3E), size: 24.sp),
              SizedBox(height: 12.h),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8.h),
              Text(
                count,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff173F3E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollegeWisePeopleScreen extends StatelessWidget {
  const _CollegeWisePeopleScreen({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.stream,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final Stream<List<CollegePeopleGroup>> stream;

  @override
  Widget build(BuildContext context) {
    return _DashboardPage(
      title: title,
      child: StreamBuilder<List<CollegePeopleGroup>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load data',
              message: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return _EmptyState(
              icon: Icons.inbox_outlined,
              title: emptyTitle,
              message: emptyMessage,
            );
          }
          return ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, index) => SizedBox(height: 14.h),
            itemBuilder: (context, index) =>
                _CollegeGroup(group: groups[index]),
          );
        },
      ),
    );
  }
}

class _PeopleScreen extends StatelessWidget {
  const _PeopleScreen({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.stream,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final Stream<List<DashboardPerson>> stream;

  @override
  Widget build(BuildContext context) {
    return _DashboardPage(
      title: title,
      child: StreamBuilder<List<DashboardPerson>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load data',
              message: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final people = snapshot.data!;
          if (people.isEmpty) {
            return _EmptyState(
              icon: Icons.inbox_outlined,
              title: emptyTitle,
              message: emptyMessage,
            );
          }
          return ListView.separated(
            itemCount: people.length,
            separatorBuilder: (_, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) => _PersonRow(person: people[index]),
          );
        },
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.go(AppRoutes.dashboard),
                  icon: const Icon(Icons.arrow_back),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff173F3E),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _CollegeGroup extends StatelessWidget {
  const _CollegeGroup({required this.group});

  final CollegePeopleGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.college,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff173F3E),
                  ),
                ),
              ),
              Text(
                '${group.people.length}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          for (final person in group.people)
            _PersonRow(person: person, showView: true),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, this.showView = false});

  final DashboardPerson person;
  final bool showView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(person.email.isEmpty ? '-' : person.email),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 14.w,
                  runSpacing: 8.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(person.code.isEmpty ? '-' : person.code),
                    Text(person.meta.isEmpty ? '-' : person.meta),
                    if (showView) _ViewButton(person: person),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 2, child: Text(person.name)),
              Expanded(child: Text(person.code.isEmpty ? '-' : person.code)),
              Expanded(child: Text(person.meta.isEmpty ? '-' : person.meta)),
              Expanded(
                flex: 2,
                child: Text(person.email.isEmpty ? '-' : person.email),
              ),
              if (showView) _ViewButton(person: person),
            ],
          );
        },
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.person});

  final DashboardPerson person;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showPersonDetails(context, person),
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('View'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xff173F3E),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        minimumSize: Size(76.w, 36.h),
      ),
    );
  }
}

void _showPersonDetails(BuildContext context, DashboardPerson person) {
  final role = person.role.trim().toLowerCase();
  final title = role == 'student'
      ? 'Student Details'
      : role == 'teacher'
      ? 'Teacher Details'
      : 'User Details';

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 460.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Name', value: person.name),
              _DetailRow(label: 'ID', value: person.code),
              _DetailRow(label: 'Email', value: person.email),
              _DetailRow(label: 'College', value: person.college),
              _DetailRow(label: 'Role', value: person.role),
              _DetailRow(label: 'Details', value: person.meta),
              _DetailRow(label: 'Phone', value: person.phone),
              _DetailRow(label: 'Status', value: person.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value.trim().isEmpty ? '-' : value.trim())),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.sp, color: Colors.grey.shade500),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xff173F3E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
