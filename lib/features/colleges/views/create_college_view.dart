import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/const/common_back_button.dart';
import '../../../core/router/router.dart';
import '../models/college.dart';
import '../services/colleges_service.dart';

class CreateCollegeView extends StatefulWidget {
  const CreateCollegeView({
    this.college,
    this.embedded = false,
    this.onSaved,
    this.onCancel,
    super.key,
  });

  final College? college;
  final bool embedded;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  @override
  State<CreateCollegeView> createState() => _CreateCollegeViewState();
}

class _CreateCollegeViewState extends State<CreateCollegeView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _service = CollegesService();
  String _status = 'Active';
  bool _saving = false;

  bool get _isEditing => widget.college != null;

  @override
  void initState() {
    super.initState();
    _fill(widget.college);
  }

  @override
  void didUpdateWidget(covariant CreateCollegeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.college?.id != widget.college?.id) {
      _fill(widget.college);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: widget.embedded ? EdgeInsets.zero : EdgeInsets.all(24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!widget.embedded) ...[
                  const CommonBackButton(
                    fallbackRouteName: RouteNames.colleges,
                  ),
                  SizedBox(width: 14.w),
                ],
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit College' : 'Create College',
                    style: TextStyle(
                      fontSize: widget.embedded ? 22.sp : 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff173F3E),
                    ),
                  ),
                ),
                if (widget.embedded)
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving ? null : widget.onCancel,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            SizedBox(height: 24.h),
            Container(
              width: widget.embedded ? double.infinity : 800.w,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  _textField(_name, 'College Name'),
                  SizedBox(height: 18.h),
                  _textField(_code, 'College Code'),
                  SizedBox(height: 18.h),
                  _textField(_city, 'City'),
                  SizedBox(height: 18.h),
                  _textField(_state, 'State'),
                  SizedBox(height: 18.h),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: _decoration('Select Status'),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  SizedBox(height: 30.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff173F3E),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Save Changes' : 'Create College',
                              style: const TextStyle(color: Colors.white),
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

    if (widget.embedded) return content;

    return Scaffold(backgroundColor: const Color(0xffF5F7F9), body: content);
  }

  Widget _textField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      validator: _required,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _decoration(hint),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xffF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  Future<void> _save() async {
    debugPrint(
      '[Colleges][Form][SubmitTapped] mode=${_isEditing ? 'edit' : 'create'} '
      'id=${widget.college?.id ?? 'new'}',
    );
    if (!_formKey.currentState!.validate()) {
      debugPrint(
        '[Colleges][Form][ValidationFailed] mode=${_isEditing ? 'edit' : 'create'}',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final college = widget.college!;
        final values = {
          'college_name': _name.text.trim(),
          'college_code': _code.text.trim(),
          'city': _city.text.trim(),
          'state': _state.text.trim(),
          'status': _status,
          if (college.raw.containsKey('updated_at'))
            'updated_at': DateTime.now().toIso8601String(),
        };
        debugPrint('[Colleges][Form][EditRequest] id=${college.id}');
        final updated = await _service.updateCollege(college, values);
        debugPrint('[Colleges][Form][EditResponse] id=${updated.id}');
      } else {
        debugPrint('[Colleges][Form][CreateRequest]');
        final created = await _service.createCollege(
          name: _name.text,
          code: _code.text,
          city: _city.text,
          state: _state.text,
          status: _status,
        );
        debugPrint('[Colleges][Form][CreateResponse] id=${created.id}');
      }
      if (!mounted) return;
      debugPrint(
        '[Colleges][Form][SnackBarSuccess] mode=${_isEditing ? 'edit' : 'create'}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'College updated.' : 'College created.'),
        ),
      );
      if (widget.embedded) {
        if (!_isEditing) _clear();
        debugPrint('[Colleges][Form][OnSavedCallback]');
        widget.onSaved?.call();
      } else {
        context.go(AppRoutes.colleges);
      }
    } catch (error) {
      debugPrint(
        '[Colleges][Form][SnackBarError] mode=${_isEditing ? 'edit' : 'create'} '
        'error=$error',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _fill(College? college) {
    _name.text = college?.name ?? '';
    _code.text = college?.code ?? '';
    _city.text = college?.city ?? '';
    _state.text = college?.state ?? '';
    _status = college?.isActive == false ? 'Inactive' : 'Active';
  }

  void _clear() {
    _formKey.currentState?.reset();
    _name.clear();
    _code.clear();
    _city.clear();
    _state.clear();
    _status = 'Active';
  }
}
