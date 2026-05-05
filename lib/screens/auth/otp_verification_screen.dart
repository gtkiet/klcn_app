// lib/screens/auth/otp_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 4;
  static const int _countdownSec = 59;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  final ValueNotifier<int> _secondsLeft = ValueNotifier(_countdownSec);
  Timer? _timer;
  bool _canResend = false;
  bool _isLoading = false;
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

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft.value = _countdownSec;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft.value <= 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        _secondsLeft.value--;
      }
    });
  }

  String get _countdownLabel =>
      '00:${_secondsLeft.value.toString().padLeft(2, '0')}';

  double get _progress => (_countdownSec - _secondsLeft.value) / _countdownSec;

  void _onDigitChanged(int index, String value) {
    setState(() => _errorMsg = null);
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == _otpLength) _onVerify();
  }

  void _onVerify() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      setState(() => _errorMsg = 'Vui lòng nhập đủ $_otpLength chữ số');
      return;
    }
    // TODO: OtpService.verifyOtp(otp)
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/reset_password');
    });
  }

  void _onResend() {
    if (!_canResend) return;
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _errorMsg = null;
      _startCountdown();
    });
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
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Xác minh OTP'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Brand logo
                // const Center(child: SpBrandLogo(size: 100)),
                // const SizedBox(height: 28),

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
                const Center(
                  child: Text(
                    'Mã OTP đã được gửi đến số điện thoại\ncủa bạn. Vui lòng nhập mã để tiếp tục.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 14.5,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _otpLength,
                    (i) => _OtpBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      hasError: _errorMsg != null,
                      onChanged: (v) => _onDigitChanged(i, v),
                    ),
                  ),
                ),

                if (_errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Resend row
                ValueListenableBuilder<int>(
                  valueListenable: _secondsLeft,
                  builder: (_, _, _) => _ResendRow(
                    canResend: _canResend,
                    countdown: _countdownLabel,
                    onResend: _onResend,
                  ),
                ),
                const SizedBox(height: 10),

                // Progress bar
                ValueListenableBuilder<int>(
                  valueListenable: _secondsLeft,
                  builder: (_, _, _) => Center(
                    child: SizedBox(
                      width: 180,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: AppColors.fieldBorder,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SpPrimaryButton(
                  label: 'XÁC NHẬN',
                  isLoading: _isLoading,
                  onTap: _onVerify,
                ),
                const SizedBox(height: 48),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _footerText('TACTICAL ANALYSIS'),
                    _dot(),
                    _footerText('PITCH PRECISION'),
                    _dot(),
                    _footerText('V2.4.0'),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerText(String t) => Text(
    t,
    style: const TextStyle(
      color: Color(0xFFAAAFAA),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  );

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text('•', style: TextStyle(color: Color(0xFFAAAFAA), fontSize: 10)),
  );
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isFilled ? Colors.white : const Color(0xFFE4E7E4),
        borderRadius: BorderRadius.circular(18),
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
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          color: widget.hasError ? AppColors.errorRed : AppColors.textDark,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ── RESEND ROW ────────────────────────────────
class _ResendRow extends StatelessWidget {
  final bool canResend;
  final String countdown;
  final VoidCallback onResend;

  const _ResendRow({
    required this.canResend,
    required this.countdown,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: canResend ? onResend : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 15,
              color: canResend ? AppColors.primary : AppColors.textMid,
            ),
            const SizedBox(width: 6),
            Text(
              canResend ? 'GỬI LẠI MÃ' : 'GỬI LẠI MÃ SAU $countdown',
              style: TextStyle(
                color: canResend ? AppColors.primary : AppColors.textMid,
                fontSize: 13,
                fontWeight: canResend ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
