// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading       = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    // TODO: Validate → AuthService.login(phone, password) → lưu token
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  void _onForgotPassword() => Navigator.pushNamed(context, '/forgot_password');
  void _onRegister()        => Navigator.pushNamed(context, '/register');
  void _onGoogleLogin()     {}   // TODO: GoogleAuthService.signIn()
  void _onFacebookLogin()   {}   // TODO: FacebookAuthService.signIn()

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
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 52),

                        // Brand logo
                        // const Center(child: SpBrandLogo(size: 108)),
                        // const SizedBox(height: 24),

                        // App name
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

                        // Phone
                        const SpFieldLabel('SỐ ĐIỆN THOẠI'),
                        const SizedBox(height: 8),
                        SpTextField(
                          controller: _phoneController,
                          hintText: '+84 (___) ___ ____',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_android,
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
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Login button
                        SpPrimaryButton(
                          label: 'Đăng nhập',
                          isLoading: _isLoading,
                          onTap: _onLogin,
                        ),
                        const SizedBox(height: 32),

                        const SpOrDivider(label: 'HOẶC ĐĂNG NHẬP VỚI'),
                        const SizedBox(height: 20),

                        // Social buttons
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

                        // Register footer
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
