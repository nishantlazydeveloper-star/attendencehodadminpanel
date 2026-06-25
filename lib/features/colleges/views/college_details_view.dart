import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/const/common_back_button.dart';
import '../../../core/router/router.dart';
import '../models/college.dart';
import '../services/colleges_service.dart';

class CollegeDetailsView extends StatelessWidget {
  CollegeDetailsView({this.collegeId, super.key});

  final String? collegeId;
  final CollegesService _service = CollegesService();

  @override
  Widget build(BuildContext context) {
    if (collegeId == null || collegeId!.isEmpty) {
      return _scaffold(
        child: _stateCard(
          icon: Icons.school_outlined,
          title: 'No college selected',
          message: 'Select a college from the Colleges screen to view details.',
        ),
      );
    }

    return StreamBuilder<College?>(
      stream: _service.watchCollege(collegeId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _scaffold(
            child: _stateCard(
              icon: Icons.error_outline,
              title: 'Unable to load college',
              message: snapshot.error.toString(),
            ),
          );
        }
        if (!snapshot.hasData) {
          return _scaffold(child: _loadingCard());
        }
        final college = snapshot.data;
        if (college == null) {
          return _scaffold(
            child: _stateCard(
              icon: Icons.search_off_outlined,
              title: 'College not found',
              message: 'This college may have been deleted.',
            ),
          );
        }
        return _scaffold(child: _details(college));
      },
    );
  }

  Widget _scaffold({required Widget child}) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CommonBackButton(
                        fallbackRouteName: RouteNames.colleges,
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          'College Details',
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
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(College college) {
    final initials = college.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 18.w,
            runSpacing: 16.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                radius: 42.r,
                backgroundColor: const Color(0xff173F3E),
                child: Text(
                  initials.isEmpty ? '-' : initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      college.name.isEmpty ? 'Unnamed college' : college.name,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff173F3E),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 8.h,
                      children: [
                        _pill(
                          college.status,
                          college.isActive
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                        ),
                        if (college.code.isNotEmpty)
                          _pill(college.code, const Color(0xffEAF0F0)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 28.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 680;
              final width = twoColumns
                  ? (constraints.maxWidth - 16.w) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16.w,
                runSpacing: 16.h,
                children: [
                  _infoTile('College Name', college.name, width),
                  _infoTile('College Code', college.code, width),
                  _infoTile('City', college.city, width),
                  _infoTile('State', college.state, width),
                  _infoTile('Status', college.status, width),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42.sp, color: const Color(0xff173F3E)),
          SizedBox(height: 14.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xffF8F9FB),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: const Color(0xff173F3E),
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.isEmpty ? '-' : label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
