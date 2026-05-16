// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = _emailCtrl.text.trim().isEmpty
          ? 'Vui lòng nhập email'
          : null;
      _passwordError = _passwordCtrl.text.trim().isEmpty
          ? 'Vui lòng nhập mật khẩu'
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      // await AuthService.instance.login(
      //   email: _emailCtrl.text.trim(),
      //   password: _passwordCtrl.text.trim(),
      // );
      // FIX: bỏ AuthGuard.instance.setAuthenticated() — AuthService.login()
      // đã gọi nội bộ rồi. GoRouter tự redirect khi nhận notifyListeners().
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

  void _onForgotPassword() => context.push('/auth/forgot-password');
  // void _onRegister() => context.push('/auth/register');
  void _onRegister() {
    debugPrint('NAVIGATE: going to /auth/register');
    context.push('/auth/register');
  }

  void _onGoogleLogin() {} // TODO: GoogleAuthService.signIn()
  void _onFacebookLogin() {} // TODO: FacebookAuthService.signIn()

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

                        // Email
                        const SpFieldLabel('EMAIL'),
                        const SizedBox(height: 8),
                        SpTextField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          nextFocusNode: _passwordFocus,
                          hintText: 'example@gmail.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          errorText: _emailError,
                          onChanged: (_) => setState(() => _emailError = null),
                        ),
                        const SizedBox(height: 20),

                        // Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SpFieldLabel('MẬT KHẨU'),
                            GestureDetector(
                              onTap: _onForgotPassword,
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
                          label: 'Đăng nhập',
                          isLoading: _isLoading,
                          onTap: _onLogin,
                        ),
                        const SizedBox(height: 32),

                        const SpOrDivider(label: 'HOẶC ĐĂNG NHẬP VỚI'),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: SpSocialButton(
                                label: 'Google',
                                icon: const SpGoogleIcon(),
                                onTap: _onGoogleLogin,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SpSocialButton(
                                label: 'Facebook',
                                icon: const SpFacebookIcon(),
                                onTap: _onFacebookLogin,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),

                        Center(
                          child: GestureDetector(
                            onTap: _onRegister,
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
