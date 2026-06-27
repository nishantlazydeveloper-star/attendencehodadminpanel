import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/const/logout_dialog.dart';
import '../../../core/router/router.dart';
import '../models/hod.dart';
import '../services/hod_service.dart';
import 'create_hod_view.dart';

class HodmanagementView extends StatefulWidget {
  const HodmanagementView({this.initialHodId, super.key});

  final String? initialHodId;

  @override
  State<HodmanagementView> createState() => _HodmanagementViewState();
}

class _HodmanagementViewState extends State<HodmanagementView> {
  final _service = HodService();
  String _query = '';
  String? _busyId;
  String? _editingHodId;
  bool _drawerOpen = false;
  bool _refreshing = false;
  int _refreshKey = 0;
  late Stream<List<Hod>> _hodsStream;

  @override
  void initState() {
    super.initState();
    _hodsStream = _service.watchHods();
    _editingHodId = widget.initialHodId;
    _drawerOpen = widget.initialHodId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _repairLegacyHods());
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
                              'HOD Management',
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
                        'New HOD',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Expanded(child: _hodList()),
              ],
            ),
          ),
          if (_drawerOpen) _slideOver(),
        ],
      ),
    );
  }

  Widget _hodList() {
    return Column(
      children: [
        TextField(
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search HOD',
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
          child: StreamBuilder<List<Hod>>(
            key: ValueKey(_refreshKey),
            stream: _hodsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                _finishRefresh();
                return _center(
                  'Unable to load HODs.\n${snapshot.error}',
                  icon: Icons.error_outline,
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              _finishRefresh();
              final hods = snapshot.data!.where(_matches).toList();
              if (hods.isEmpty) {
                return _center(
                  _query.isEmpty ? 'No HODs created yet.' : 'No HOD found.',
                  icon: Icons.people_outline,
                );
              }
              return ListView.builder(
                itemCount: hods.length,
                itemBuilder: (context, index) => _row(hods[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _refreshButton() {
    return IconButton(
      tooltip: 'Refresh',
      onPressed: _refreshing ? null : _refreshHods,
      icon: _refreshing
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, color: Color(0xff173F3E)),
    );
  }

  void _refreshHods() {
    setState(() {
      _refreshing = true;
      _refreshKey += 1;
      _hodsStream = _service.watchHods();
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

  bool _matches(Hod hod) {
    if (_query.isEmpty) return true;
    return [
      hod.hodCode,
      hod.name,
      hod.email,
      hod.college,
      hod.department,
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
          Expanded(flex: 1, child: _headerText('HOD ID')),
          Expanded(flex: 2, child: _headerText('Name')),
          Expanded(flex: 2, child: _headerText('Email')),
          Expanded(flex: 1, child: _headerText('College')),
          Expanded(flex: 1, child: _headerText('Department')),
          Expanded(flex: 1, child: _headerText('Status')),
          Expanded(flex: 2, child: _headerText('Action')),
        ],
      ),
    );
  }

  Widget _row(Hod hod) {
    final busy = _busyId == hod.id;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(hod.displayHodCode)),
          Expanded(flex: 2, child: Text(hod.name)),
          Expanded(flex: 2, child: Text(hod.email)),
          Expanded(child: Text(hod.college)),
          Expanded(child: Text(hod.department)),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(hod.isActive ? 'Active' : 'Inactive'),
                backgroundColor: hod.isActive
                    ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: busy
                ? const Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'View',
                        onPressed: () => context.go(
                          '${AppRoutes.hodDetails}?id=${Uri.encodeComponent(hod.hodCode)}',
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Edit',
                        onPressed: () => _openDrawer(hod.id),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        tooltip: hod.isActive ? 'Deactivate' : 'Activate',
                        onPressed: () => _setActive(hod),
                        icon: Icon(
                          hod.isActive
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          color: hod.isActive ? Colors.orange : Colors.green,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete',
                        onPressed: () => _delete(hod),
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

  Future<void> _setActive(Hod hod) async {
    await _run(hod.id, () => _service.setActive(hod.id, !hod.isActive));
  }

  Future<void> _delete(Hod hod) async {
    var confirmed = false;
    await showThemedConfirmationDialog(
      context: context,
      barrierLabel: 'Delete HOD',
      title: 'Delete HOD',
      message:
          '${hod.name} will lose Attendance app access and their HOD profile '
          'will be permanently deleted.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
      onConfirm: () => confirmed = true,
    );
    if (confirmed) {
      final deleted = await _run(hod.id, () => _service.deleteHod(hod.id));
      if (deleted && mounted) {
        _refreshHods();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('HOD deleted.')));
        if (_editingHodId == hod.id) {
          _closeDrawer();
        }
      }
    }
  }

  Future<bool> _run(String id, Future<void> Function() action) async {
    setState(() => _busyId = id);
    try {
      await action();
      return true;
    } on HodServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return false;
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _repairLegacyHods() async {
    try {
      await _service.repairLegacyHods();
    } on HodServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Widget _center(String text, {required IconData icon}) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _headerText(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  );

  void _openDrawer([String? hodId]) {
    setState(() {
      _editingHodId = hodId;
      _drawerOpen = true;
    });
  }

  void _closeDrawer() {
    setState(() {
      _editingHodId = null;
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
                child: CreateHodView(
                  key: ValueKey(_editingHodId ?? 'create-hod'),
                  hodId: _editingHodId,
                  embedded: true,
                  onCancel: _closeDrawer,
                  onSaved: _closeDrawer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
