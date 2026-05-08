// lib/screens/profile/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _isLoading   = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentCtrl.dispose(); _currentFocus.dispose();
    _newCtrl.dispose();     _newFocus.dispose();
    _confirmCtrl.dispose(); _confirmFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _currentError = _currentCtrl.text.isEmpty
          ? 'Vui lòng nhập mật khẩu hiện tại'
          : null;

      if (_newCtrl.text.isEmpty) {
        _newError = 'Vui lòng nhập mật khẩu mới';
      } else if (_newCtrl.text.length < 8) {
        _newError = 'Mật khẩu tối thiểu 8 ký tự';
      } else if (!RegExp(r'[a-zA-Z]').hasMatch(_newCtrl.text) ||
          !RegExp(r'[0-9]').hasMatch(_newCtrl.text)) {
        _newError = 'Mật khẩu phải có cả chữ cái và số';
      } else {
        _newError = null;
      }

      if (_confirmCtrl.text.isEmpty) {
        _confirmError = 'Vui lòng xác nhận mật khẩu mới';
      } else if (_confirmCtrl.text != _newCtrl.text) {
        _confirmError = 'Mật khẩu xác nhận không khớp';
      } else {
        _confirmError = null;
      }
    });
    return _currentError == null && _newError == null && _confirmError == null;
  }

  void _onUpdate() {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _isLoading = true);
    // TODO: ChangePasswordService.changePassword(current, newPassword)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu đã được cập nhật!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
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
          title: const Text('Đổi mật khẩu'),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // Header text
                const Center(
                  child: Text(
                    'Bảo mật tài khoản',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Nhập mật khẩu hiện tại và mật khẩu mới\nđể cập nhật bảo mật tài khoản.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Main card with 3 fields
                SpCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current password
                      const Text('Mật khẩu hiện tại',
                          style: TextStyle(
                              color: AppColors.textDark, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _PassField(
                        controller: _currentCtrl,
                        focusNode: _currentFocus,
                        nextFocus: _newFocus,
                        hint: 'Nhập mật khẩu hiện tại',
                        prefixIcon: Icons.lock_outline_rounded,
                        showText: _showCurrent,
                        onToggle: () => setState(() => _showCurrent = !_showCurrent),
                        onChanged: (_) => setState(() => _currentError = null),
                        errorText: _currentError,
                      ),
                      const SizedBox(height: 20),

                      // New password
                      const Text('Mật khẩu mới',
                          style: TextStyle(
                              color: AppColors.textDark, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _PassField(
                        controller: _newCtrl,
                        focusNode: _newFocus,
                        nextFocus: _confirmFocus,
                        hint: 'Nhập mật khẩu mới',
                        prefixIcon: Icons.vpn_key_outlined,
                        showText: _showNew,
                        onToggle: () => setState(() => _showNew = !_showNew),
                        onChanged: (_) => setState(() => _newError = null),
                        errorText: _newError,
                      ),
                      const SizedBox(height: 20),

                      // Confirm password
                      const Text('Xác nhận mật khẩu mới',
                          style: TextStyle(
                              color: AppColors.textDark, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _PassField(
                        controller: _confirmCtrl,
                        focusNode: _confirmFocus,
                        hint: 'Nhập lại mật khẩu mới',
                        prefixIcon: Icons.shield_outlined,
                        showText: _showConfirm,
                        onToggle: () => setState(() => _showConfirm = !_showConfirm),
                        onChanged: (_) => setState(() => _confirmError = null),
                        errorText: _confirmError,
                      ),
                      const SizedBox(height: 20),

                      // Rule box
                      const _PasswordRuleBox(),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Update button
                SpPrimaryButton(
                  label: 'CẬP NHẬT MẬT KHẨU',
                  isLoading: _isLoading,
                  onTap: _onUpdate,
                  trailingIcon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: 16),

                // Cancel
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: const Center(
                    child: Text(
                      'Hủy bỏ',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
    );
  }
}

// ── PASSWORD FIELD (stateful for focus border) ─
class _PassField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final IconData prefixIcon;
  final bool showText;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _PassField({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    required this.hint,
    required this.prefixIcon,
    required this.showText,
    required this.onToggle,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
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
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
            border: Border.all(
              color: hasError
                  ? AppColors.errorRed
                  : _isFocused
                      ? AppColors.primary
                      : AppColors.fieldBorder,
              width: hasError || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? AppColors.primary : AppColors.textHint,
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: !widget.showText,
                  onChanged: widget.onChanged,
                  textInputAction: widget.nextFocus != null
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onSubmitted: (_) {
                    if (widget.nextFocus != null) {
                      FocusScope.of(context).requestFocus(widget.nextFocus);
                    } else {
                      widget.focusNode.unfocus();
                    }
                  },
                  style: const TextStyle(color: AppColors.textDark, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14.5),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, left: 6),
                  child: Icon(
                    widget.showText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) SpErrorText(widget.errorText!),
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
      decoration: BoxDecoration(
        color: AppColors.primaryUltraLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB8D9B8)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('i',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('QUY ĐỊNH MẬT KHẨU',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5)),
                          SizedBox(height: 5),
                          Text(
                            'Mật khẩu phải có ít nhất 8 ký tự, bao gồm cả chữ cái và chữ số để đảm bảo tính bảo mật cho tài khoản của bạn.',
                            style: TextStyle(
                                color: AppColors.textMid, fontSize: 13, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
