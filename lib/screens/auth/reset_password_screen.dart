// lib/screens/auth/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPassCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final ValueNotifier<_PasswordStrength> _strengthNotifier =
      ValueNotifier(_PasswordStrength.weak);

  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  String? _newPassError;
  String? _confirmPassError;

  static const int _minPassLen = 8;

  @override
  void initState() {
    super.initState();
    _newPassCtrl.addListener(() {
      _strengthNotifier.value = _evaluateStrength(_newPassCtrl.text);
      if (_newPassError != null) setState(() => _newPassError = null);
    });
    _confirmPassCtrl.addListener(() {
      if (_confirmPassError != null) setState(() => _confirmPassError = null);
    });
  }

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _strengthNotifier.dispose();
    super.dispose();
  }

  bool _validate() {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;
    bool valid = true;
    setState(() {
      if (newPass.isEmpty) {
        _newPassError = 'Vui lòng nhập mật khẩu mới';
        valid = false;
      } else if (newPass.length < _minPassLen) {
        _newPassError = 'Mật khẩu tối thiểu $_minPassLen ký tự';
        valid = false;
      } else if (!RegExp(r'[a-zA-Z]').hasMatch(newPass) ||
          !RegExp(r'[0-9]').hasMatch(newPass)) {
        _newPassError = 'Mật khẩu phải có cả chữ cái và số';
        valid = false;
      } else {
        _newPassError = null;
      }

      if (confirm.isEmpty) {
        _confirmPassError = 'Vui lòng xác nhận mật khẩu';
        valid = false;
      } else if (confirm != newPass) {
        _confirmPassError = 'Mật khẩu xác nhận không khớp';
        valid = false;
      } else {
        _confirmPassError = null;
      }
    });
    return valid;
  }

  void _onUpdatePassword() {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    // TODO: ResetPasswordService.resetPassword(token, newPassword)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu đã được cập nhật thành công!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.arrow_back),
            ),
          ),
          title: const Text('Đặt lại mật khẩu'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadH,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                // const Center(child: SpBrandLogo(size: 108)),
                // const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Tạo mật khẩu mới',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Vui lòng nhập mật khẩu mới để bảo mật\ntài khoản của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                const SpFieldLabel('MẬT KHẨU MỚI'),
                const SizedBox(height: 8),
                SpPasswordField(
                  controller: _newPassCtrl,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  errorText: _newPassError,
                ),
                const SizedBox(height: 10),

                // Strength bar
                ValueListenableBuilder<_PasswordStrength>(
                  valueListenable: _strengthNotifier,
                  builder: (_, strength, _) =>
                      _PasswordStrengthBar(strength: strength),
                ),
                const SizedBox(height: 20),

                const SpFieldLabel('XÁC NHẬN MẬT KHẨU'),
                const SizedBox(height: 8),
                SpPasswordField(
                  controller: _confirmPassCtrl,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  errorText: _confirmPassError,
                ),
                const SizedBox(height: 20),

                // Info box
                const _PasswordRuleBox(),
                const SizedBox(height: 32),

                SpPrimaryButton(
                  label: 'CẬP NHẬT MẬT KHẨU',
                  isLoading: _isLoading,
                  onTap: _onUpdatePassword,
                  trailingIcon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 16, color: AppColors.textMid),
                      SizedBox(width: 6),
                      Text(
                        'Quay lại đăng nhập',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PASSWORD STRENGTH ─────────────────────────
enum _PasswordStrength { weak, medium, strong }

_PasswordStrength _evaluateStrength(String password) {
  if (password.length < 6) return _PasswordStrength.weak;
  int score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
  if (score <= 1) return _PasswordStrength.weak;
  if (score == 2) return _PasswordStrength.medium;
  return _PasswordStrength.strong;
}

class _PasswordStrengthBar extends StatelessWidget {
  final _PasswordStrength strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final (label, color, filled) = switch (strength) {
      _PasswordStrength.weak   => ('Yếu', const Color(0xFFE53935), 1),
      _PasswordStrength.medium => ('Trung bình', const Color(0xFFFB8C00), 2),
      _PasswordStrength.strong => ('Mạnh', AppColors.primary, 3),
    };
    return Row(
      children: [
        ...List.generate(3, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < filled ? color : AppColors.fieldBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── PASSWORD RULE BOX ─────────────────────────
class _PasswordRuleBox extends StatelessWidget {
  const _PasswordRuleBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryUltraLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3D9C3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'i',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mật khẩu phải chứa ít nhất 8 ký tự, bao gồm chữ cái và số để đảm bảo tính an toàn tối đa cho tài khoản của bạn.',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
