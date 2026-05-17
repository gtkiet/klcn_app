// lib/screens/auth/otp_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  /// email được truyền từ ForgotPasswordScreen qua GoRouter extra
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength    = 6;
  static const int _countdownSec = 120; // 2 phút

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  final ValueNotifier<int> _secondsLeft = ValueNotifier(_countdownSec);
  Timer? _timer;

  bool _canResend = false;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNodes[0].requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _secondsLeft.dispose();
    super.dispose();
  }

  // ── Countdown ─────────────────────────────────────────────────
  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft.value = _countdownSec;
    setState(() => _canResend = false);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft.value <= 0) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        _secondsLeft.value--;
      }
    });
  }

  String get _countdownLabel {
    final m = (_secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Input handling ─────────────────────────────────────────────
  void _onDigitChanged(int index, String value) {
    setState(() => _errorMsg = null);
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-submit khi điền đủ
    if (_controllers.map((c) => c.text).join().length == _otpLength) {
      _onVerify();
    }
  }

  // ── Verify OTP ─────────────────────────────────────────────────
  Future<void> _onVerify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      setState(() => _errorMsg = 'Vui lòng nhập đủ $_otpLength chữ số');
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final resetToken = await AuthService.instance.verifyOtp(
        email: widget.email,
        otp:   otp,
      );

      if (!mounted) return;
      // Truyền resetToken sang màn đặt lại mật khẩu
      context.pushReplacement(
        '/auth/reset-password',
        extra: {'resetToken': resetToken},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString());
      // Xoá ô OTP để nhập lại
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────
  Future<void> _onResend() async {
    if (!_canResend) return;
    setState(() { _isResending = true; _errorMsg = null; });

    try {
      await AuthService.instance.forgotPassword(widget.email);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã OTP mới đã được gửi đến email của bạn'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
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
      if (mounted) setState(() => _isResending = false);
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
          title: const Text('Xác minh OTP'),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // ── Icon ────────────────────────────────────────
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
                        Icons.mark_email_read_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'Nhập mã xác minh',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 14.5,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'Mã OTP đã được gửi đến\n'),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── OTP boxes ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      _otpLength,
                      (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode:  _focusNodes[i],
                        hasError:   _errorMsg != null,
                        onChanged:  (v) => _onDigitChanged(i, v),
                      ),
                    ),
                  ),

                  // ── Error ───────────────────────────────────────
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.errorRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(
                                color: AppColors.errorRed,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Countdown + Resend ──────────────────────────
                  ValueListenableBuilder<int>(
                    valueListenable: _secondsLeft,
                    builder: (_, _, _) => Column(
                      children: [
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_countdownSec - _secondsLeft.value) /
                                _countdownSec,
                            backgroundColor: AppColors.fieldBorder,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Resend row
                        _isResending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              )
                            : GestureDetector(
                                onTap: _canResend ? _onResend : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _canResend
                                          ? Icons.refresh_rounded
                                          : Icons.access_time_rounded,
                                      size: 15,
                                      color: _canResend
                                          ? AppColors.primary
                                          : AppColors.textMid,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _canResend
                                          ? 'GỬI LẠI MÃ'
                                          : 'GỬI LẠI SAU $_countdownLabel',
                                      style: TextStyle(
                                        color: _canResend
                                            ? AppColors.primary
                                            : AppColors.textMid,
                                        fontSize: 13,
                                        fontWeight: _canResend
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Verify button ───────────────────────────────
                  SpPrimaryButton(
                    label:     'XÁC NHẬN',
                    isLoading: _isLoading,
                    onTap:     _onVerify,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── OTP BOX ───────────────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(
      () => setState(() => _isFocused = widget.focusNode.hasFocus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.controller.text.isNotEmpty;

    final borderColor = widget.hasError
        ? AppColors.errorRed
        : _isFocused
            ? AppColors.primary
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: isFilled ? Colors.white : const Color(0xFFE4E7E4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: _isFocused || widget.hasError ? 2 : 0,
        ),
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller:   widget.controller,
        focusNode:    widget.focusNode,
        onChanged:    widget.onChanged,
        keyboardType: TextInputType.number,
        textAlign:    TextAlign.center,
        maxLength:    1,
        style: TextStyle(
          color: widget.hasError ? AppColors.errorRed : AppColors.textDark,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border:         InputBorder.none,
          counterText:    '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}