import 'package:adminpanel/core/router/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.child, super.key});

  final Widget child;

  static const _items = <_SidebarItem>[
    _SidebarItem('Dashboard', Icons.dashboard_outlined, AppRoutes.dashboard),
    _SidebarItem('Colleges', Icons.school_outlined, AppRoutes.colleges),
    _SidebarItem(
      'HOD Management',
      Icons.people_outline,
      AppRoutes.hodManagement,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      body: Row(
        children: [
          Container(
            width: 250.w.clamp(220, 280),
            color: const Color(0xff173F3E),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 28.h),
                    child: Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      children: [
                        for (final item in _items)
                          _SidebarTile(
                            item: item,
                            selected: location == item.location,
                            onTap: () => context.go(item.location),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 20.h),
                    child: _SidebarTile(
                      item: const _SidebarItem(
                        'Logout',
                        Icons.logout,
                        AppRoutes.login,
                      ),
                      selected: false,
                      onTap: () => context.go(AppRoutes.login),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          leading: Icon(item.icon, color: Colors.white, size: 22.sp),
          title: Text(
            item.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem(this.label, this.icon, this.location);

  final String label;
  final IconData icon;
  final String location;
}
