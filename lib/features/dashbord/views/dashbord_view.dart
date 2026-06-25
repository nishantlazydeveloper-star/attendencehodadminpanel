import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../colleges/models/college.dart';
import '../../colleges/services/colleges_service.dart';
import '../controllers/dashbord_controller.dart';

class DashbordView extends GetView<DashbordController> {
  DashbordView({super.key});

  final CollegesService _collegesService = CollegesService();

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
              "Dashboard",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xff173F3E),
              ),
            ),

            SizedBox(height: 24.h),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 1.8,
              children: [
                StreamBuilder<List<College>>(
                  stream: _collegesService.watchColleges(),
                  builder: (context, snapshot) {
                    return _DashboardCard(
                      title: "Total Colleges",
                      count: snapshot.hasData
                          ? snapshot.data!.length.toString()
                          : "-",
                    );
                  },
                ),
                const _DashboardCard(title: "Total HODs", count: "25"),
                const _DashboardCard(title: "Total Teachers", count: "150"),
                const _DashboardCard(title: "Total Students", count: "2500"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String count;

  const _DashboardCard({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
    );
  }
}
