// lib/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final input = _emailCtrl.text.trim();
    setState(() {
      if (input.isEmpty) {
        _emailError = 'Vui lòng nhập email';
      } else if (!input.contains('@') || !input.contains('.')) {
        _emailError = 'Email không hợp lệ';
      } else {
        _emailError = null;
      }
    });
    return _emailError == null;
  }

  Future<void> _onSendCode() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailCtrl.text.trim();
      await AuthService.instance.forgotPassword(email);

      if (!mounted) return;
      // Truyền email sang OTP screen để verify-otp biết gửi lên đâu
      context.push('/auth/otp-verification', extra: {'email': email});
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
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Quên mật khẩu'),
        ),
        body: Column(
          children: [
            _UpperSection(),
            Expanded(
              child: _LowerCard(
                emailCtrl:     _emailCtrl,
                emailError:    _emailError,
                isLoading:     _isLoading,
                onEmailChanged: (_) => setState(() => _emailError = null),
                onSendCode:    _onSendCode,
                onBackToLogin: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── UPPER SECTION ─────────────────────────────
class _UpperSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadH, 24, AppSpacing.pagePadH, 36,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: Column(
        children: [
          // Icon minh họa
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 1.5),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nhập email đã đăng ký để nhận\nmã OTP thiết lập lại mật khẩu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 14.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── LOWER CARD ────────────────────────────────
class _LowerCard extends StatelessWidget {
  final TextEditingController emailCtrl;
  final String? emailError;
  final bool isLoading;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onSendCode;
  final VoidCallback onBackToLogin;

  const _LowerCard({
    required this.emailCtrl,
    required this.emailError,
    required this.isLoading,
    required this.onEmailChanged,
    required this.onSendCode,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Watermark
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, 0.2),
            child: Transform.rotate(
              angle: -0.35,
              child: Text(
                'SportPlus',
                style: TextStyle(
                  color: AppColors.fieldBorder.withValues(alpha: 0.5),
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),

        // Card
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft:  Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadH,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SpFieldLabel('EMAIL'),
                const SizedBox(height: 10),
                SpTextField(
                  controller:   emailCtrl,
                  hintText:     'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon:   Icons.email_outlined,
                  errorText:    emailError,
                  onChanged:    onEmailChanged,
                ),
                const SizedBox(height: 24),

                SpPrimaryButton(
                  label:     'GỬI MÃ XÁC MINH',
                  isLoading: isLoading,
                  onTap:     onSendCode,
                ),
                const SizedBox(height: 32),
                const Divider(color: Color(0xFFE0E2E0), thickness: 1),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: onBackToLogin,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 17, color: AppColors.textMid),
                      SizedBox(width: 8),
                      Text(
                        'Quay lại Đăng nhập',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}