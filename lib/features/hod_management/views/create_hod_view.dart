import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/router.dart';
import '../../colleges/models/college.dart';
import '../../colleges/services/colleges_service.dart';
import '../models/hod.dart';
import '../services/hod_service.dart';
import '../../../core/utils/app_logger.dart';

class CreateHodView extends StatefulWidget {
  const CreateHodView({
    this.hodId,
    this.embedded = false,
    this.onSaved,
    this.onCancel,
    super.key,
  });

  final String? hodId;
  final bool embedded;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  @override
  State<CreateHodView> createState() => _CreateHodViewState();
}

class _CreateHodViewState extends State<CreateHodView> {
  final _formKey = GlobalKey<FormState>();
  final _hodCode = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _college = TextEditingController();
  final _department = TextEditingController();
  final _service = HodService();
  final _collegesService = CollegesService();
  bool _saving = false;
  bool _loaded = false;
  bool _obscurePassword = true;
  String? _loadedHodId;

  bool get _isEditing => widget.hodId != null;

  @override
  void dispose() {
    _hodCode.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _college.dispose();
    _department.dispose();
    super.dispose();
  }

  void _fill(Hod hod) {
    if (_loaded) return;
    _loaded = true;
    _loadedHodId = hod.id;
    _hodCode.text = hod.displayHodCode;
    _name.text = hod.name;
    _email.text = hod.email;
    _college.text = hod.college;
    _department.text = hod.department;
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return StreamBuilder<Hod?>(
        stream: _service.watchHod(widget.hodId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message('Unable to load HOD: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hod = snapshot.data;
          if (hod == null) return _message('HOD not found.');
          _fill(hod);
          return _form();
        },
      );
    }
    return _form();
  }

  Widget _form() {
    final content = SingleChildScrollView(
      padding: widget.embedded ? EdgeInsets.zero : EdgeInsets.all(24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded) ...[
              Text(
                _isEditing ? 'Edit HOD' : 'Create HOD',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff173F3E),
                ),
              ),
              SizedBox(height: 30.h),
            ],
            Container(
              width: widget.embedded ? double.infinity : 700.w,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.embedded) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEditing ? 'Edit HOD' : 'Create HOD',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff173F3E),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _saving ? null : widget.onCancel,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                  ],
                  _readOnlyField(
                    _hodCode,
                    'HOD ID',
                    hint: _isEditing ? null : 'Generated after save',
                  ),
                  SizedBox(height: 18.h),
                  _field(_name, 'Full Name', _required),
                  SizedBox(height: 18.h),
                  _field(_email, 'Email Address', _validateEmail),
                  if (!_isEditing) ...[
                    SizedBox(height: 18.h),
                    _field(
                      _password,
                      'Password',
                      _validatePassword,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  _collegePicker(),
                  SizedBox(height: 18.h),
                  _field(_department, 'Department', _required),
                  SizedBox(height: 30.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
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
                              _isEditing ? 'Save Changes' : 'Create HOD',
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

  Widget _collegePicker() {
    return StreamBuilder<List<College>>(
      stream: _collegesService.watchColleges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextFormField(
            controller: _college,
            readOnly: true,
            validator: _required,
            decoration: _inputDecoration(
              'College',
              errorText: 'Unable to load colleges.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return InputDecorator(
            decoration: _inputDecoration('College'),
            child: const LinearProgressIndicator(minHeight: 2),
          );
        }

        final colleges = snapshot.data!
            .where((college) => college.name.isNotEmpty && college.isActive)
            .toList();

        return Autocomplete<College>(
          displayStringForOption: (college) => college.label,
          initialValue: TextEditingValue(text: _college.text),
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return colleges;
            return colleges.where((college) {
              return [
                college.name,
                college.code,
                college.city,
              ].any((item) => item.toLowerCase().contains(query));
            });
          },
          onSelected: (college) {
            _college.text = college.name;
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (controller.text != _college.text) {
              controller.value = TextEditingValue(
                text: _college.text,
                selection: TextSelection.collapsed(
                  offset: _college.text.length,
                ),
              );
            }
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              validator: (value) {
                final required = _required(value);
                if (required != null) return required;
                final text = value!.trim();
                final exists = colleges.any(
                  (college) =>
                      college.name.toLowerCase() == text.toLowerCase() ||
                      college.label.toLowerCase() == text.toLowerCase(),
                );
                return exists ? null : 'Select a college from the list.';
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (value) => _college.text = value,
              decoration: _inputDecoration(
                'College',
              ).copyWith(suffixIcon: const Icon(Icons.keyboard_arrow_down)),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, {String? errorText}) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xffF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xffF8F9FB),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _readOnlyField(
    TextEditingController controller,
    String label, {
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xffF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _validateEmail(String? value) {
    final required = _required(value);
    if (required != null) return required;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
        ? null
        : 'Enter a valid email address.';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value)) {
      return 'Use uppercase, lowercase, and a number.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _service.updateHod(
          id: _loadedHodId ?? widget.hodId!,
          name: _name.text,
          email: _email.text,
          college: _college.text,
          department: _department.text,
        );
      } else {
        await _service.createHod(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          college: _college.text,
          department: _department.text,
        );
        AppLogger.log(
          'CreateHodView',
          'HOD creation completed',
          data: {'email': _email.text.trim()},
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'HOD updated.' : 'HOD created.')),
      );
      if (widget.embedded) {
        if (!_isEditing) {
          _formKey.currentState?.reset();
          _hodCode.clear();
          _name.clear();
          _email.clear();
          _password.clear();
          _college.clear();
          _department.clear();
        }
        widget.onSaved?.call();
      } else {
        context.go(AppRoutes.hodManagement);
      }
    } on HodServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'CreateHodView',
        'Create HOD flow failed',
        error,
        stackTrace,
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

  Widget _message(String text) {
    final child = Center(child: Text(text, textAlign: TextAlign.center));
    if (widget.embedded) return child;
    return Scaffold(body: child);
  }
}
