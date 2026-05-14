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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    debugPrint('REGISTER SCREEN: mounted');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _emailCtrl.dispose();
    _emailFocus.dispose();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    _confirmCtrl.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Vui lòng nhập họ và tên'
          : null;
      _emailError = !_emailCtrl.text.trim().contains('@')
          ? 'Email không hợp lệ'
          : null;
      _phoneError = _phoneCtrl.text.trim().length < 9
          ? 'Số điện thoại không hợp lệ'
          : null;
      _passwordError = _passwordCtrl.text.length < 6
          ? 'Mật khẩu tối thiểu 6 ký tự'
          : null;
      _confirmError = _confirmCtrl.text != _passwordCtrl.text
          ? 'Mật khẩu xác nhận không khớp'
          : null;
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
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
      );
      // FIX: bỏ AuthGuard.instance.setAuthenticated() ở đây —
      // AuthService.register() đã gọi nội bộ rồi (nhất quán với login).
      // GoRouter tự redirect khi nhận notifyListeners().
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onLogin() => context.go('/auth/login');
  void _onGoogleRegister() {} // TODO
  void _onFacebookRegister() {} // TODO

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

                  const SpFieldLabel('HỌ VÀ TÊN'),
                  const SizedBox(height: 8),
                  SpTextField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    nextFocusNode: _emailFocus,
                    hintText: 'Nhập họ và tên',
                    keyboardType: TextInputType.name,
                    prefixIcon: Icons.person_outline_rounded,
                    errorText: _nameError,
                    onChanged: (_) => setState(() => _nameError = null),
                  ),
                  const SizedBox(height: 18),

                  const SpFieldLabel('EMAIL'),
                  const SizedBox(height: 8),
                  SpTextField(
                    controller: _emailCtrl,
                    focusNode: _emailFocus,
                    nextFocusNode: _phoneFocus,
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    errorText: _emailError,
                    onChanged: (_) => setState(() => _emailError = null),
                  ),
                  const SizedBox(height: 18),

                  const SpFieldLabel('SỐ ĐIỆN THOẠI'),
                  const SizedBox(height: 8),
                  SpTextField(
                    controller: _phoneCtrl,
                    focusNode: _phoneFocus,
                    nextFocusNode: _passwordFocus,
                    hintText: '0xxxxxxxxx',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android_outlined,
                    errorText: _phoneError,
                    onChanged: (_) => setState(() => _phoneError = null),
                  ),
                  const SizedBox(height: 18),

                  const SpFieldLabel('MẬT KHẨU'),
                  const SizedBox(height: 8),
                  SpPasswordField(
                    controller: _passwordCtrl,
                    obscure: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    errorText: _passwordError,
                    onChanged: (_) => setState(() => _passwordError = null),
                  ),
                  const SizedBox(height: 18),

                  const SpFieldLabel('XÁC NHẬN MẬT KHẨU'),
                  const SizedBox(height: 8),
                  SpPasswordField(
                    controller: _confirmCtrl,
                    obscure: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    errorText: _confirmError,
                    onChanged: (_) => setState(() => _confirmError = null),
                  ),
                  const SizedBox(height: 22),

                  _TermsCheckbox(
                    value: _agreedToTerms,
                    onChanged: (v) =>
                        setState(() => _agreedToTerms = v ?? false),
                    onTermsTap: () {},
                    onPrivacyTap: () {},
                  ),
                  const SizedBox(height: 28),

                  SpPrimaryButton(
                    label: 'Đăng ký',
                    isLoading: _isLoading,
                    onTap: _agreedToTerms ? _onRegister : null,
                    trailingIcon: null,
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: _onLogin,
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
                  const SizedBox(height: 28),

                  const SpOrDivider(),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: SpSocialButton(
                          label: 'Google',
                          icon: const SpGoogleIcon(),
                          onTap: _onGoogleRegister,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SpSocialButton(
                          label: 'Facebook',
                          icon: const SpFacebookIcon(),
                          onTap: _onFacebookRegister,
                        ),
                      ),
                    ],
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

// ── TERMS CHECKBOX ─────────────────────────────────────────────────────────
class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

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
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textMid,
                fontSize: 13.5,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Tôi đồng ý với các '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: onTermsTap,
                    child: const Text(
                      'Điều khoản sử dụng',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' và '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: onPrivacyTap,
                    child: const Text(
                      'Chính sách bảo mật',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
