// lib/screens/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Import ChangePasswordService khi kết nối backend

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const bgPage = Color(0xFFF2F5F0);

  // AppBar
  static const appBarTitle = Color(0xFF2E7D32);
  static const appBarBack = Color(0xFF2E7D32);

  // Logo card
  static const logoBg = Colors.white;
  static const logoShadow = Color(0x14000000);

  // Brand name
  static const brandName = Color(0xFF2E7D32);

  // Main card
  static const cardBg = Colors.white;
  static const cardRadius = 18.0;

  // Fields (inside card)
  static const fieldBg = Color(0xFFEBECEB);
  static const fieldBorder = Color(0xFFDFE2DF);
  static const fieldRadius = 12.0;
  static const fieldTextColor = Color(0xFF1A1A1A);
  static const fieldHintColor = Color(0xFFAAAAAA);
  static const fieldIconColor = Color(0xFF999999);
  static const fieldIconActive = Color(0xFF2E7D32);
  static const fieldBorderFocus = Color(0xFF2E7D32);
  static const fieldBorderError = Color(0xFFD32F2F);

  // Field labels (inside card)
  static const fieldLabel = Color(0xFF1A1A1A);

  // Rule info box
  static const ruleBoxBg = Color(0xFFF0F8F0);
  static const ruleBoxBorder = Color(0xFFE0EEE0);
  static const ruleLeftBar = Color(0xFF2E7D32);
  static const ruleIconBg = Color(0xFF2E7D32);
  static const ruleTitleColor = Color(0xFF2E7D32);
  static const ruleTextColor = Color(0xFF444444);

  // Buttons
  static const btnBg = Color(0xFF2E7D32);
  static const btnRadius = 14.0;
  static const btnHeight = 56.0;
  static const cancelColor = Color(0xFF777777);

  // Error
  static const errorRed = Color(0xFFD32F2F);

  // static const white = Colors.white;
}

// ─────────────────────────────────────────────
//  CHANGE PASSWORD SCREEN
// ─────────────────────────────────────────────
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Controllers
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // FocusNodes
  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // Visibility toggles
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  // State
  bool _isLoading = false;
  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _currentFocus.dispose();
    _newCtrl.dispose();
    _newFocus.dispose();
    _confirmCtrl.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────
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

  // ── Actions ────────────────────────────────
  void _onUpdate() {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _isLoading = true);
    // TODO: Gọi ChangePasswordService.changePassword(
    //         current: _currentCtrl.text,
    //         newPassword: _newCtrl.text,
    //       )
    // TODO: Nếu lỗi "wrong current password" → _currentError = 'Mật khẩu hiện tại không đúng'
    // TODO: Sau thành công → logout + navigate('/login') hoặc pop
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu đã được cập nhật!'),
          backgroundColor: _C.primary,
        ),
      );
      Navigator.pop(context);
    });
  }

  void _onCancel() {
    // TODO: context.pop() với go_router
    Navigator.maybePop(context);
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bgPage,
        appBar: _ChangePassAppBar(onBack: () => Navigator.maybePop(context)),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // ── Logo card + brand name ────
                const Center(child: _LogoCard()),
                const SizedBox(height: 16),
                const Center(child: _BrandName()),

                const SizedBox(height: 28),

                // ── Main white card ───────────
                _MainCard(
                  // Current password
                  currentCtrl: _currentCtrl,
                  currentFocus: _currentFocus,
                  nextFocus: _newFocus,
                  showCurrent: _showCurrent,
                  currentError: _currentError,
                  onToggleCurrent: () =>
                      setState(() => _showCurrent = !_showCurrent),
                  onCurrentChanged: (_) => setState(() => _currentError = null),

                  // New password
                  newCtrl: _newCtrl,
                  newFocus: _newFocus,
                  nextNewFocus: _confirmFocus,
                  showNew: _showNew,
                  newError: _newError,
                  onToggleNew: () => setState(() => _showNew = !_showNew),
                  onNewChanged: (_) => setState(() => _newError = null),

                  // Confirm password
                  confirmCtrl: _confirmCtrl,
                  confirmFocus: _confirmFocus,
                  showConfirm: _showConfirm,
                  confirmError: _confirmError,
                  onToggleConfirm: () =>
                      setState(() => _showConfirm = !_showConfirm),
                  onConfirmChanged: (_) => setState(() => _confirmError = null),
                ),

                const SizedBox(height: 28),

                // ── Update button ─────────────
                _UpdateButton(isLoading: _isLoading, onTap: _onUpdate),

                const SizedBox(height: 16),

                // ── Cancel link ───────────────
                GestureDetector(
                  onTap: _onCancel,
                  child: const Center(
                    child: Text(
                      'Hủy bỏ',
                      style: TextStyle(
                        color: _C.cancelColor,
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

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────
class _ChangePassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  const _ChangePassAppBar({required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bgPage,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 48,
      leading: GestureDetector(
        onTap: onBack,
        child: const Padding(
          padding: EdgeInsets.only(left: 14),
          child: Icon(Icons.arrow_back, color: _C.appBarBack, size: 24),
        ),
      ),
      centerTitle: true,
      title: const Text(
        'Đổi mật khẩu',
        style: TextStyle(
          color: _C.appBarTitle,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      titleSpacing: 0,
    );
  }
}

// ─────────────────────────────────────────────
//  LOGO CARD  (white rounded square)
// ─────────────────────────────────────────────
class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: _C.logoBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: _C.logoShadow, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      // TODO: Thay bằng Image.asset('assets/images/sportplus_logo.png')
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer, color: Color(0xFF1565C0), size: 30),
          const SizedBox(height: 3),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'SPORT',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: 'PLUS',
                  style: TextStyle(
                    color: Color(0xFFFFA000),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BRAND NAME
// ─────────────────────────────────────────────
class _BrandName extends StatelessWidget {
  const _BrandName();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Sport Plus',
      style: TextStyle(
        color: _C.brandName,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        // TODO: GoogleFonts.playfairDisplay(...)
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MAIN WHITE CARD  (3 fields + rule box)
// ─────────────────────────────────────────────
class _MainCard extends StatelessWidget {
  // Current password
  final TextEditingController currentCtrl;
  final FocusNode currentFocus;
  final FocusNode nextFocus;
  final bool showCurrent;
  final String? currentError;
  final VoidCallback onToggleCurrent;
  final ValueChanged<String> onCurrentChanged;

  // New password
  final TextEditingController newCtrl;
  final FocusNode newFocus;
  final FocusNode nextNewFocus;
  final bool showNew;
  final String? newError;
  final VoidCallback onToggleNew;
  final ValueChanged<String> onNewChanged;

  // Confirm password
  final TextEditingController confirmCtrl;
  final FocusNode confirmFocus;
  final bool showConfirm;
  final String? confirmError;
  final VoidCallback onToggleConfirm;
  final ValueChanged<String> onConfirmChanged;

  const _MainCard({
    required this.currentCtrl,
    required this.currentFocus,
    required this.nextFocus,
    required this.showCurrent,
    required this.currentError,
    required this.onToggleCurrent,
    required this.onCurrentChanged,
    required this.newCtrl,
    required this.newFocus,
    required this.nextNewFocus,
    required this.showNew,
    required this.newError,
    required this.onToggleNew,
    required this.onNewChanged,
    required this.confirmCtrl,
    required this.confirmFocus,
    required this.showConfirm,
    required this.confirmError,
    required this.onToggleConfirm,
    required this.onConfirmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_C.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Mật khẩu hiện tại ─────────────
          _InlineLabel('Mật khẩu hiện tại'),
          const SizedBox(height: 8),
          _PasswordField(
            controller: currentCtrl,
            focusNode: currentFocus,
            nextFocus: nextFocus,
            hint: 'Nhập mật khẩu hiện tại',
            prefixIcon: Icons.lock_outline_rounded,
            showText: showCurrent,
            onToggle: onToggleCurrent,
            onChanged: onCurrentChanged,
            errorText: currentError,
          ),

          const SizedBox(height: 20),

          // ── Mật khẩu mới ──────────────────
          _InlineLabel('Mật khẩu mới'),
          const SizedBox(height: 8),
          _PasswordField(
            controller: newCtrl,
            focusNode: newFocus,
            nextFocus: nextNewFocus,
            hint: 'Nhập mật khẩu mới',
            prefixIcon: Icons.vpn_key_outlined,
            showText: showNew,
            onToggle: onToggleNew,
            onChanged: onNewChanged,
            errorText: newError,
          ),

          const SizedBox(height: 20),

          // ── Xác nhận mật khẩu mới ─────────
          _InlineLabel('Xác nhận mật khẩu mới'),
          const SizedBox(height: 8),
          _PasswordField(
            controller: confirmCtrl,
            focusNode: confirmFocus,
            nextFocus: null,
            hint: 'Nhập lại mật khẩu mới',
            prefixIcon: Icons.shield_outlined,
            showText: showConfirm,
            onToggle: onToggleConfirm,
            onChanged: onConfirmChanged,
            errorText: confirmError,
          ),

          const SizedBox(height: 20),

          // ── Password rule info box ─────────
          const _PasswordRuleBox(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INLINE FIELD LABEL  (inside card, normal weight)
// ─────────────────────────────────────────────
class _InlineLabel extends StatelessWidget {
  final String text;
  const _InlineLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _C.fieldLabel,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PASSWORD FIELD  (reusable, stateful for focus)
// ─────────────────────────────────────────────
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final IconData prefixIcon;
  final bool showText;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.hint,
    required this.prefixIcon,
    required this.showText,
    required this.onToggle,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isFocused = false;
  late VoidCallback _focusListener;

  @override
  void initState() {
    super.initState();
    _focusListener = () =>
        setState(() => _isFocused = widget.focusNode.hasFocus);
    widget.focusNode.addListener(_focusListener);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_focusListener);
    super.dispose();
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
            color: _C.fieldBg,
            borderRadius: BorderRadius.circular(_C.fieldRadius),
            border: Border.all(
              color: hasError
                  ? _C.fieldBorderError
                  : _isFocused
                  ? _C.fieldBorderFocus
                  : _C.fieldBorder,
              width: hasError || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Prefix icon
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? _C.fieldIconActive : _C.fieldIconColor,
                  size: 20,
                ),
              ),

              // Text field
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
                  style: const TextStyle(
                    color: _C.fieldTextColor,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: _C.fieldHintColor,
                      fontSize: 14.5,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              // Visibility toggle
              GestureDetector(
                onTap: widget.onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, left: 6),
                  child: Icon(
                    widget.showText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _C.fieldIconColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Inline error message
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 13, color: _C.errorRed),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(color: _C.errorRed, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PASSWORD RULE INFO BOX  (green left border)
// ─────────────────────────────────────────────
class _PasswordRuleBox extends StatelessWidget {
  const _PasswordRuleBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.ruleBoxBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.ruleBoxBorder, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _C.ruleLeftBar,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "i" icon circle
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: const BoxDecoration(
                        color: _C.ruleIconBg,
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

                    const SizedBox(width: 10),

                    // Text content
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUY ĐỊNH MẬT KHẨU',
                            style: TextStyle(
                              color: _C.ruleTitleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Mật khẩu phải có ít nhất 8 ký tự, bao '
                            'gồm cả chữ cái và chữ số để đảm '
                            'bảo tính bảo mật cho tài khoản của '
                            'bạn.',
                            style: TextStyle(
                              color: _C.ruleTextColor,
                              fontSize: 13,
                              height: 1.55,
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  UPDATE BUTTON
// ─────────────────────────────────────────────
class _UpdateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _UpdateButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _C.btnHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? _C.primaryLight : _C.btnBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_C.btnRadius),
          ),
          elevation: 5,
          shadowColor: _C.btnBg.withValues(alpha: 0.28),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CẬP NHẬT MẬT KHẨU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(width: 10),
                  // Checkmark circle badge (giống design)
                  _CheckBadge(),
                ],
              ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
    );
  }
}
