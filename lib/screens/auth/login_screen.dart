// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _identifierError = _identifierCtrl.text.trim().isEmpty
          ? 'Vui lòng nhập email hoặc số điện thoại'
          : null;
      _passwordError = _passwordCtrl.text.isEmpty
          ? 'Vui lòng nhập mật khẩu'
          : null;
    });
    return _identifierError == null && _passwordError == null;
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.login(
        identifier: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgTop, AppColors.bgBottom],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadH,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 52),

                        const Center(child: SpAppNameText(fontSize: 34)),
                        const SizedBox(height: 10),

                        const Center(
                          child: Text(
                            'Chào mừng bạn quay trở lại sân cỏ.',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Identifier ─────────────────────────────
                        const SpFieldLabel('EMAIL HOẶC SỐ ĐIỆN THOẠI'),
                        const SizedBox(height: 8),
                        SpTextField(
                          controller: _identifierCtrl,
                          focusNode: _identifierFocus,
                          nextFocusNode: _passwordFocus,
                          hintText: 'example@gmail.com hoặc 0xxxxxxxxx',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.person_outline_rounded,
                          errorText: _identifierError,
                          onChanged: (_) =>
                              setState(() => _identifierError = null),
                        ),
                        const SizedBox(height: 20),

                        // ── Password ───────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SpFieldLabel('MẬT KHẨU'),
                            GestureDetector(
                              onTap: () =>
                                  context.push('/auth/forgot-password'),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SpPasswordField(
                          controller: _passwordCtrl,
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          errorText: _passwordError,
                          onChanged: (_) =>
                              setState(() => _passwordError = null),
                        ),
                        const SizedBox(height: 28),

                        SpPrimaryButton(
                          label: 'ĐĂNG NHẬP',
                          isLoading: _isLoading,
                          onTap: _onLogin,
                        ),
                        const SizedBox(height: 36),

                        // ── Register link ──────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () => context.push('/auth/register'),
                            child: RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Chưa có tài khoản?  ',
                                    style: TextStyle(
                                      color: AppColors.textMid,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Đăng ký ngay',
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

                        const SizedBox(height: 24),
                        const Spacer(),

                        // ── Footer ─────────────────────────────────
                        const _FooterBadge(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterBadge extends StatelessWidget {
  const _FooterBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sports_soccer, size: 12, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text(
          'SPORT PLUS  •  SÂN CHƠI CHIẾN THUẬT',
          style: TextStyle(
            color: AppColors.textHint.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
