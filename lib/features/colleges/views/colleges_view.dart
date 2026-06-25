import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/const/logout_dialog.dart';
import '../../../core/router/router.dart';
import '../models/college.dart';
import '../services/colleges_service.dart';
import 'create_college_view.dart';

class CollegesView extends StatefulWidget {
  const CollegesView({this.openCreateDrawer = false, super.key});

  final bool openCreateDrawer;

  @override
  State<CollegesView> createState() => _CollegesViewState();
}

class _CollegesViewState extends State<CollegesView> {
  final _service = CollegesService();
  final _searchController = TextEditingController();
  String _query = '';
  String? _busyId;
  College? _editingCollege;
  bool _drawerOpen = false;
  bool _refreshing = false;
  int _refreshKey = 0;
  late Stream<List<College>> _collegesStream;

  @override
  void initState() {
    super.initState();
    _collegesStream = _service.watchColleges();
    _drawerOpen = widget.openCreateDrawer;
    debugPrint(
      '[Colleges][UI][Init] openCreateDrawer=${widget.openCreateDrawer}',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _refreshButton(),
                          SizedBox(width: 12.w),
                          Flexible(
                            child: Text(
                              'Colleges',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff173F3E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff173F3E),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                      ),
                      onPressed: () => _openDrawer(),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add College',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search College',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                _header(),
                SizedBox(height: 10.h),
                Expanded(
                  child: StreamBuilder<List<College>>(
                    key: ValueKey(_refreshKey),
                    stream: _collegesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        _finishRefresh();
                        return _center(
                          'Unable to load colleges.\n${snapshot.error}',
                          Icons.error_outline,
                        );
                      }
                      if (!snapshot.hasData) {
                        debugPrint('[Colleges][UI][StreamBuilder] waiting');
                        return const Center(child: CircularProgressIndicator());
                      }
                      _finishRefresh();
                      final colleges = snapshot.data!.where(_matches).toList();
                      debugPrint(
                        '[Colleges][UI][StreamBuilder] rawRows=${snapshot.data!.length} '
                        'filteredRows=${colleges.length} query="$_query" '
                        'ids=${colleges.map((college) => college.id).join(',')}',
                      );
                      if (colleges.isEmpty) {
                        return _center(
                          _query.isEmpty
                              ? 'No colleges created yet.'
                              : 'No college found.',
                          Icons.school_outlined,
                        );
                      }
                      return ListView.builder(
                        itemCount: colleges.length,
                        itemBuilder: (context, index) => _row(colleges[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_drawerOpen) _slideOver(),
        ],
      ),
    );
  }

  Widget _refreshButton() {
    return IconButton(
      tooltip: 'Refresh',
      onPressed: _refreshing ? null : _refreshColleges,
      icon: _refreshing
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, color: Color(0xff173F3E)),
    );
  }

  void _refreshColleges() {
    debugPrint('[Colleges][UI][RefreshTapped]');
    setState(() {
      _refreshing = true;
      _refreshKey += 1;
      _collegesStream = _service.watchColleges();
    });
  }

  void _finishRefresh() {
    if (!_refreshing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _refreshing) {
        setState(() => _refreshing = false);
      }
    });
  }

  bool _matches(College college) {
    if (_query.isEmpty) return true;
    return [
      college.name,
      college.code,
      college.city,
      college.state,
      college.status,
    ].any((value) => value.toLowerCase().contains(_query));
  }

  Widget _header() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xff173F3E),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText('College Name')),
          Expanded(child: _headerText('Code')),
          Expanded(child: _headerText('City')),
          Expanded(child: _headerText('Status')),
          Expanded(child: _headerText('Action')),
        ],
      ),
    );
  }

  Widget _row(College college) {
    final busy = _busyId == college.id;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(college.name, style: TextStyle(fontSize: 14.sp)),
          ),
          Expanded(child: Text(college.code.isEmpty ? '-' : college.code)),
          Expanded(child: Text(college.city.isEmpty ? '-' : college.city)),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(college.status),
                backgroundColor: college.isActive
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
            ),
          ),
          Expanded(
            child: busy
                ? const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'View',
                        onPressed: () => context.go(
                          '${AppRoutes.collegeDetails}?id=${college.id}',
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _openDrawer(college),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _delete(college),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(College college) async {
    debugPrint('[Colleges][UI][DeleteTapped] id=${college.id}');
    var confirmed = false;
    await showThemedConfirmationDialog(
      context: context,
      barrierLabel: 'Delete College',
      title: 'Delete College',
      message: '${college.name} will be permanently deleted.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
      onConfirm: () => confirmed = true,
    );
    if (confirmed) {
      debugPrint('[Colleges][UI][DeleteConfirmed] id=${college.id}');
      final deleted = await _run(
        college.id,
        () => _service.deleteCollege(college.id),
      );
      debugPrint(
        '[Colleges][UI][DeleteComplete] id=${college.id} success=$deleted',
      );
      if (deleted && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('College deleted.')));
        if (_editingCollege?.id == college.id) {
          _closeDrawer();
        }
      }
    }
  }

  Future<bool> _run(String id, Future<void> Function() action) async {
    debugPrint('[Colleges][UI][RunStart] id=$id');
    setState(() => _busyId = id);
    try {
      await action();
      debugPrint('[Colleges][UI][RunSuccess] id=$id');
      return true;
    } catch (error) {
      debugPrint('[Colleges][UI][RunError] id=$id error=$error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return false;
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _openDrawer([College? college]) {
    debugPrint('[Colleges][UI][OpenDrawer] id=${college?.id ?? 'create'}');
    setState(() {
      _editingCollege = college;
      _drawerOpen = true;
    });
  }

  void _closeDrawer() {
    debugPrint('[Colleges][UI][CloseDrawer]');
    setState(() {
      _editingCollege = null;
      _drawerOpen = false;
    });
  }

  void _handleSaved() {
    debugPrint(
      '[Colleges][UI][SaveHandled] clearingSearch=true closingDrawer=true',
    );
    setState(() {
      _searchController.clear();
      _query = '';
      _editingCollege = null;
      _drawerOpen = false;
    });
  }

  Widget _slideOver() {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width < 560 ? width : 460.w.clamp(400, 520);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _closeDrawer,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.20)),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: panelWidth.toDouble(),
          child: Material(
            color: const Color(0xffF5F7F9),
            elevation: 18,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: CreateCollegeView(
                  key: ValueKey(_editingCollege?.id ?? 'create-college'),
                  college: _editingCollege,
                  embedded: true,
                  onCancel: _closeDrawer,
                  onSaved: _handleSaved,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _center(String text, IconData icon) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Colors.grey),
        SizedBox(height: 12.h),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _headerText(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
}
