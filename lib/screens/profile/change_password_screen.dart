// lib/screens/profile/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus     = FocusNode();
  final _confirmFocus = FocusNode();

  final ValueNotifier<_PasswordStrength> _strengthNotifier =
      ValueNotifier(_PasswordStrength.empty);

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() {
      _strengthNotifier.value = _evalStrength(_newCtrl.text);
      if (_newError != null) setState(() => _newError = null);
    });
    _confirmCtrl.addListener(() {
      if (_confirmError != null) setState(() => _confirmError = null);
    });
  }

  @override
  void dispose() {
    _currentCtrl.dispose(); _currentFocus.dispose();
    _newCtrl.dispose();     _newFocus.dispose();
    _confirmCtrl.dispose(); _confirmFocus.dispose();
    _strengthNotifier.dispose();
    super.dispose();
  }

  // ── Validate ──────────────────────────────────────────────────
  bool _validate() {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    bool valid = true;

    setState(() {
      if (current.isEmpty) {
        _currentError = 'Vui lòng nhập mật khẩu hiện tại';
        valid = false;
      } else {
        _currentError = null;
      }

      if (newPass.isEmpty) {
        _newError = 'Vui lòng nhập mật khẩu mới';
        valid = false;
      } else if (newPass.length < 8) {
        _newError = 'Mật khẩu tối thiểu 8 ký tự';
        valid = false;
      } else if (!RegExp(r'[a-zA-Z]').hasMatch(newPass) ||
          !RegExp(r'[0-9]').hasMatch(newPass)) {
        _newError = 'Mật khẩu phải có cả chữ cái và số';
        valid = false;
      } else if (newPass == current) {
        _newError = 'Mật khẩu mới phải khác mật khẩu hiện tại';
        valid = false;
      } else {
        _newError = null;
      }

      if (confirm.isEmpty) {
        _confirmError = 'Vui lòng xác nhận mật khẩu mới';
        valid = false;
      } else if (confirm != newPass) {
        _confirmError = 'Mật khẩu xác nhận không khớp';
        valid = false;
      } else {
        _confirmError = null;
      }
    });

    return valid;
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await ProfileService.instance.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword:     _newCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu đã được cập nhật thành công!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      // Nếu sai mật khẩu hiện tại, server trả lỗi rõ
      final msg = e.toString();
      if (msg.toLowerCase().contains('current') ||
          msg.toLowerCase().contains('incorrect') ||
          msg.toLowerCase().contains('hiện tại') ||
          msg.toLowerCase().contains('sai')) {
        setState(() => _currentError = 'Mật khẩu hiện tại không đúng');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Đổi mật khẩu'),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // ── Header icon ──────────────────────────────────
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryUltraLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Mật khẩu mới phải khác mật khẩu cũ\nvà đảm bảo các yêu cầu bảo mật.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Card ─────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppShadow.card,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Mật khẩu hiện tại ─────────────────────
                      const SpFieldLabel('MẬT KHẨU HIỆN TẠI'),
                      const SizedBox(height: 8),
                      SpPasswordField(
                        controller: _currentCtrl,
                        obscure:    _obscureCurrent,
                        onToggle:   () => setState(
                          () => _obscureCurrent = !_obscureCurrent,
                        ),
                        errorText:  _currentError,
                        onChanged:  (_) => setState(() => _currentError = null),
                      ),
                      const SizedBox(height: 24),

                      const Divider(color: Color(0xFFF0F2F0), height: 1),
                      const SizedBox(height: 24),

                      // ── Mật khẩu mới ──────────────────────────
                      const SpFieldLabel('MẬT KHẨU MỚI'),
                      const SizedBox(height: 8),
                      SpPasswordField(
                        controller: _newCtrl,
                        obscure:    _obscureNew,
                        onToggle:   () =>
                            setState(() => _obscureNew = !_obscureNew),
                        errorText:  _newError,
                        onChanged:  (_) => setState(() => _newError = null),
                      ),
                      const SizedBox(height: 10),

                      // Strength bar
                      ValueListenableBuilder<_PasswordStrength>(
                        valueListenable: _strengthNotifier,
                        builder: (_, strength, _) =>
                            _PasswordStrengthBar(strength: strength),
                      ),
                      const SizedBox(height: 20),

                      // ── Xác nhận mật khẩu mới ─────────────────
                      const SpFieldLabel('XÁC NHẬN MẬT KHẨU MỚI'),
                      const SizedBox(height: 8),
                      SpPasswordField(
                        controller: _confirmCtrl,
                        obscure:    _obscureConfirm,
                        onToggle:   () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        errorText:  _confirmError,
                        onChanged:  (_) =>
                            setState(() => _confirmError = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Rule info box ────────────────────────────────
                const _PasswordRuleBox(),
                const SizedBox(height: 28),

                // ── Submit ───────────────────────────────────────
                SpPrimaryButton(
                  label:        'CẬP NHẬT MẬT KHẨU',
                  isLoading:    _isLoading,
                  onTap:        _onSubmit,
                  trailingIcon: Icons.check_circle_outline_rounded,
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
enum _PasswordStrength { empty, weak, medium, strong }

_PasswordStrength _evalStrength(String p) {
  if (p.isEmpty) return _PasswordStrength.empty;
  if (p.length < 6) return _PasswordStrength.weak;
  int score = 0;
  if (p.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(p)) score++;
  if (RegExp(r'[0-9]').hasMatch(p)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
  if (score <= 1) return _PasswordStrength.weak;
  if (score == 2) return _PasswordStrength.medium;
  return _PasswordStrength.strong;
}

class _PasswordStrengthBar extends StatelessWidget {
  final _PasswordStrength strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    if (strength == _PasswordStrength.empty) return const SizedBox.shrink();

    final (label, color, filled) = switch (strength) {
      _PasswordStrength.weak   => ('Yếu',       const Color(0xFFE53935), 1),
      _PasswordStrength.medium => ('Trung bình', const Color(0xFFFB8C00), 2),
      _PasswordStrength.strong => ('Mạnh',       AppColors.primary,       3),
      _                        => ('',           Colors.transparent,      0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'i',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Yêu cầu mật khẩu',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            'Ít nhất 8 ký tự',
            'Bao gồm cả chữ cái (A-z) và chữ số (0-9)',
            'Khác với mật khẩu hiện tại',
          ].map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rule,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}