import 'package:adminpanel/features/auth/views/login_screen.dart';
import 'package:adminpanel/features/colleges/views/college_details_view.dart';
import 'package:adminpanel/features/colleges/views/colleges_view.dart';
import 'package:adminpanel/features/dashbord/views/dashbord_view.dart';
import 'package:adminpanel/features/hod_management/views/hod_details_view.dart';
import 'package:adminpanel/features/hod_management/views/hod_management_view.dart';
import 'package:adminpanel/core/widgets/admin_shell.dart';
import 'package:go_router/go_router.dart';

class RouteNames {
  static const login = 'login';
  static const dashboard = 'dashboard';
  static const colleges = 'colleges';
  static const createCollege = 'create-college';
  static const collegeDetails = 'college-details';
  static const hodManagement = 'hod-management';
  static const createHod = 'create-hod';
  static const hodDetails = 'hod-details';
}

class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const colleges = '/colleges';
  static const createCollege = '/colleges/create';
  static const collegeDetails = '/colleges/details';
  static const hodManagement = '/hod-management';
  static const createHod = '/hod-management/create';
  static const hodDetails = '/hod-management/details';
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: RouteNames.dashboard,
            builder: (context, state) => DashbordView(),
          ),
          GoRoute(
            path: AppRoutes.colleges,
            name: RouteNames.colleges,
            builder: (context, state) => const CollegesView(),
          ),
          GoRoute(
            path: AppRoutes.createCollege,
            name: RouteNames.createCollege,
            builder: (context, state) =>
                const CollegesView(openCreateDrawer: true),
          ),
          GoRoute(
            path: AppRoutes.collegeDetails,
            name: RouteNames.collegeDetails,
            builder: (context, state) =>
                CollegeDetailsView(collegeId: state.uri.queryParameters['id']),
          ),
          GoRoute(
            path: AppRoutes.hodManagement,
            name: RouteNames.hodManagement,
            builder: (context, state) => HodmanagementView(
              initialHodId: state.uri.queryParameters['id'],
            ),
          ),
          GoRoute(
            path: AppRoutes.createHod,
            name: RouteNames.createHod,
            builder: (context, state) => const HodmanagementView(),
          ),
          GoRoute(
            path: AppRoutes.hodDetails,
            name: RouteNames.hodDetails,
            builder: (context, state) =>
                HodDetailsView(hodId: state.uri.queryParameters['id']),
          ),
        ],
      ),
    ],
  );
}
