import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/const/common_back_button.dart';
import '../../../core/router/router.dart';
import '../models/hod.dart';
import '../services/hod_service.dart';

class HodDetailsView extends StatelessWidget {
  HodDetailsView({required this.hodId, super.key});

  final String? hodId;
  final HodService _service = HodService();

  @override
  Widget build(BuildContext context) {
    if (hodId == null || hodId!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Select a HOD from HOD Management.')),
      );
    }
    return StreamBuilder<Hod?>(
      stream: _service.watchHod(hodId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Unable to load HOD: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final hod = snapshot.data;
        if (hod == null) {
          return const Scaffold(body: Center(child: Text('HOD not found.')));
        }
        return _content(context, hod);
      },
    );
  }

  Widget _content(BuildContext context, Hod hod) {
    final initials = hod.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CommonBackButton(
                  fallbackRouteName: RouteNames.hodManagement,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    'HOD Details',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff173F3E),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Container(
              width: 700.w,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45.r,
                    backgroundColor: const Color(0xff173F3E),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _infoRow('HOD ID', hod.displayHodCode),
                  _infoRow('Name', hod.name),
                  _infoRow('Email', hod.email),
                  _infoRow('College', hod.college),
                  _infoRow('Department', hod.department),
                  _infoRow('Status', hod.isActive ? 'Active' : 'Inactive'),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4D4F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => context.go(
                        '${AppRoutes.hodManagement}?id=${Uri.encodeComponent(hod.hodCode)}',
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit HOD',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) => Padding(
    padding: EdgeInsets.only(bottom: 18.h),
    child: Row(
      children: [
        SizedBox(
          width: 150.w,
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
