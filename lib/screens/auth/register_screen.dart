// lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  final _nameFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _phoneFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _agreedToTerms   = false;
  bool _isLoading       = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();     _nameFocus.dispose();
    _emailCtrl.dispose();    _emailFocus.dispose();
    _phoneCtrl.dispose();    _phoneFocus.dispose();
    _passwordCtrl.dispose(); _passwordFocus.dispose();
    _confirmCtrl.dispose();  _confirmFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    setState(() {
      _nameError = name.isEmpty ? 'Vui lòng nhập họ và tên' : null;

      if (email.isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Email không hợp lệ';
      } else {
        _emailError = null;
      }

      if (phone.isEmpty) {
        _phoneError = 'Vui lòng nhập số điện thoại';
      } else if (phone.length < 9) {
        _phoneError = 'Số điện thoại không hợp lệ';
      } else {
        _phoneError = null;
      }

      if (password.isEmpty) {
        _passwordError = 'Vui lòng nhập mật khẩu';
      } else if (password.length < 6) {
        _passwordError = 'Mật khẩu tối thiểu 6 ký tự';
      } else {
        _passwordError = null;
      }

      if (confirm.isEmpty) {
        _confirmError = 'Vui lòng xác nhận mật khẩu';
      } else if (confirm != password) {
        _confirmError = 'Mật khẩu xác nhận không khớp';
      } else {
        _confirmError = null;
      }
    });

    return _nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _onRegister() async {
    FocusScope.of(context).unfocus();

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản sử dụng'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.register(
        email:    _emailCtrl.text.trim(),
        phone:    _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
      );
      // AuthService.register() đã gọi _guard.setAuthenticated() nội bộ
      // → GoRouter.redirect() tự chuyển về /home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgTop,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/auth/login'),
          ),
          title: const Text('Đăng ký'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgTop, AppColors.bgBottom],
            ),
          ),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      'Gia nhập đội hình',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Bắt đầu hành trình chinh phục mọi sân cỏ\ncùng Sport Plus.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Họ và tên ──────────────────────────────────
                  const SpFieldLabel('HỌ VÀ TÊN'),
                  const SizedBox(height: 8),
                  SpTextField(
                    controller:    _nameCtrl,
                    focusNode:     _nameFocus,
                    nextFocusNode: _emailFocus,
                    hintText:      'Nhập họ và tên',
                    keyboardType:  TextInputType.name,
                    prefixIcon:    Icons.person_outline_rounded,
                    errorText:     _nameError,
                    onChanged:     (_) => setState(() => _nameError = null),
                  ),
                  const SizedBox(height: 18),

                  // ── Email ──────────────────────────────────────
                  const SpFieldLabel('EMAIL'),
                  const SizedBox(height: 8),
                  SpTextField(
                    controller:    _emailCtrl,
                    focusNode:     _emailFocus,
                    nextFocusNode: _phoneFocus,
                    hintText:      'name@example.com',
                    keyboardType:  TextInputType.emailAddress,
                    prefixIcon:    Icons.email_outlined,
                    errorText:     _emailError,
                    onChanged:     (_) => setState(() => _emailError = null),
                  ),
                  const SizedBox(height: 18),

                  // ── Số điện thoại ──────────────────────────────
                  const SpFieldLabel('SỐ ĐIỆN THOẠI'),
                  const SizedBox(height: 8),
                  SpTextField(
                    controller:    _phoneCtrl,
                    focusNode:     _phoneFocus,
                    nextFocusNode: _passwordFocus,
                    hintText:      '0xxxxxxxxx',
                    keyboardType:  TextInputType.phone,
                    prefixIcon:    Icons.phone_android_outlined,
                    errorText:     _phoneError,
                    onChanged:     (_) => setState(() => _phoneError = null),
                  ),
                  const SizedBox(height: 18),

                  // ── Mật khẩu ───────────────────────────────────
                  const SpFieldLabel('MẬT KHẨU'),
                  const SizedBox(height: 8),
                  SpPasswordField(
                    controller: _passwordCtrl,
                    obscure:    _obscurePassword,
                    onToggle:   () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    errorText:  _passwordError,
                    onChanged:  (_) => setState(() => _passwordError = null),
                  ),
                  const SizedBox(height: 18),

                  // ── Xác nhận mật khẩu ──────────────────────────
                  const SpFieldLabel('XÁC NHẬN MẬT KHẨU'),
                  const SizedBox(height: 8),
                  SpPasswordField(
                    controller: _confirmCtrl,
                    obscure:    _obscureConfirm,
                    onToggle:   () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    errorText:  _confirmError,
                    onChanged:  (_) => setState(() => _confirmError = null),
                  ),
                  const SizedBox(height: 22),

                  // ── Terms ──────────────────────────────────────
                  _TermsCheckbox(
                    value:     _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  ),
                  const SizedBox(height: 28),

                  SpPrimaryButton(
                    label:     'ĐĂNG KÝ',
                    isLoading: _isLoading,
                    onTap:     _agreedToTerms ? _onRegister : null,
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/auth/login'),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Đã có tài khoản?  ',
                              style: TextStyle(
                                color: AppColors.textMid,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: 'Đăng nhập',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── TERMS CHECKBOX ────────────────────────────────────────────────
class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.primary : AppColors.fieldBorder,
                width: 1.8,
              ),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Sport Plus.',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}