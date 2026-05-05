// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Import UserService, ImagePicker khi kết nối backend

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  // static const primaryLight = Color(0xFF4CAF50);
  static const bgPage = Color(0xFFF2F5F0);

  // Avatar
  static const avatarBorder = Colors.white;
  static const cameraBadge = Color(0xFF2E7D32);

  // App bar
  // static const appBarTitle = Color(0xFF1A1A1A);
  static const appBarSave = Color(0xFF2E7D32);

  // Membership tag
  // static const membershipText = Color(0xFF555555);
  // static const idText = Color(0xFF888888);

  // Fields
  static const fieldBg = Color(0xFFECEEEC);
  static const fieldBorder = Color(0xFFDFE2DF);
  static const fieldRadius = 14.0;
  static const fieldPrefixIcon = Color(0xFF2E7D32);
  static const fieldText = Color(0xFF1A1A1A);
  static const labelColor = Color(0xFF777777);

  // Verify card
  static const verifyCardBg = Color(0xFFF7F8F6);
  static const verifyCardBdr = Color(0xFFE4E7E4);
  static const verifyIconBg = Color(0xFFE8F5E9);
  static const verifyIconColor = Color(0xFF2E7D32);
  static const verifyArrow = Color(0xFFBBBBBB);

  // Save button
  static const btnBg = Color(0xFF2E7D32);
  static const btnRadius = 14.0;
  static const btnHeight = 56.0;

  // Footer
  static const footerIcon = Color(0xFFCDD8CD);

  // static const white = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  // static const textMid = Color(0xFF555555);
  static const textLight = Color(0xFF888888);
}

// ─────────────────────────────────────────────
//  EDIT PROFILE SCREEN
// ─────────────────────────────────────────────
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers pre-filled with mock data
  final _nameCtrl = TextEditingController(text: 'Nguyễn Văn A');
  final _emailCtrl = TextEditingController(text: 'nguyenvana.sport@gmail.com');
  final _phoneCtrl = TextEditingController(text: '0987 654 321');
  final _addressCtrl = TextEditingController(
    text: '123 Đường Thể Thao, Quận 1, TP. Hồ Chí Minh',
  );

  // FocusNodes for keyboard management
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();

  bool _isLoading = false;

  // Validation errors
  String? _nameError;
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _emailCtrl.dispose();
    _emailFocus.dispose();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    _addressCtrl.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────
  bool _validate() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Vui lòng nhập họ và tên'
          : null;
      _emailError = !_emailCtrl.text.contains('@')
          ? 'Email không hợp lệ'
          : null;
      _phoneError = _phoneCtrl.text.trim().length < 9
          ? 'Số điện thoại không hợp lệ'
          : null;
    });
    return _nameError == null && _emailError == null && _phoneError == null;
  }

  // ── Actions ────────────────────────────────
  void _onSave() {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _isLoading = true);
    // TODO: Gọi UserService.updateProfile(name, email, phone, address)
    // TODO: Sau thành công → Navigator.pop(context) hoặc showSnackBar
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hồ sơ đã được cập nhật thành công!'),
          backgroundColor: _C.primary,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    });
  }

  void _onPickImage() {
    // TODO: ImagePicker().pickImage(source: ImageSource.gallery)
    // TODO: Upload → UserService.updateAvatar(file)
  }

  void _onVerify() {
    // TODO: Navigator.pushNamed(context, '/verify')
    Navigator.pushNamed(context, '/verify');
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
        appBar: _EditProfileAppBar(
          onBack: () => Navigator.maybePop(context),
          onSave: _isLoading ? null : _onSave,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // ── Avatar section ────────────
                Center(child: _AvatarSection(onTap: _onPickImage)),

                const SizedBox(height: 16),

                // ── Name + membership ─────────
                const Center(
                  child: Text(
                    'Nguyễn Văn A',
                    style: TextStyle(
                      color: _C.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    'Thành viên Hạng Vàng  •  ID: SP-2024',
                    style: TextStyle(color: _C.textLight, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 30),

                // ── HỌ VÀ TÊN ────────────────
                _FieldLabel('HỌ VÀ TÊN'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  nextFocus: _emailFocus,
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  errorText: _nameError,
                  onChanged: (_) => setState(() => _nameError = null),
                ),

                const SizedBox(height: 18),

                // ── EMAIL ─────────────────────
                _FieldLabel('EMAIL'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  nextFocus: _phoneFocus,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) => setState(() => _emailError = null),
                ),

                const SizedBox(height: 18),

                // ── SỐ ĐIỆN THOẠI ─────────────
                _FieldLabel('SỐ ĐIỆN THOẠI'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _phoneCtrl,
                  focusNode: _phoneFocus,
                  nextFocus: _addressFocus,
                  prefixIcon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  errorText: _phoneError,
                  onChanged: (_) => setState(() => _phoneError = null),
                ),

                const SizedBox(height: 18),

                // ── ĐỊA CHỈ ──────────────────
                _FieldLabel('ĐỊA CHỈ'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _addressCtrl,
                  focusNode: _addressFocus,
                  prefixIcon: Icons.location_on_outlined,
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // ── Verify account row ────────
                _VerifyAccountRow(onTap: _onVerify),

                const SizedBox(height: 28),

                // ── Save button ───────────────
                _SaveButton(isLoading: _isLoading, onTap: _onSave),

                const SizedBox(height: 20),

                // ── Footer icon ───────────────
                const Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 24,
                    color: _C.footerIcon,
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

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────
class _EditProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback? onSave;

  const _EditProfileAppBar({required this.onBack, required this.onSave});

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
          child: Icon(Icons.arrow_back, color: _C.primary, size: 24),
        ),
      ),
      title: const Text(
        'Chỉnh sửa hồ sơ',
        style: TextStyle(
          color: _C.primary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      titleSpacing: 0,
      actions: [
        // Soccer icon (center-ish decoration)
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.sports_soccer, color: _C.primary, size: 20),
        ),
        // "Lưu" text action
        GestureDetector(
          onTap: onSave,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: Text(
              'Lưu',
              style: TextStyle(
                color: onSave != null
                    ? _C.appBarSave
                    : _C.appBarSave.withValues(alpha: 0.4),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  AVATAR SECTION  (circle + camera badge)
// ─────────────────────────────────────────────
class _AvatarSection extends StatelessWidget {
  final VoidCallback onTap;
  const _AvatarSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar circle
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.avatarBorder, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            // TODO: Thay bằng Image.network(user.avatarUrl, fit: BoxFit.cover)
            child: Container(
              color: const Color(0xFF7B6052),
              child: const Icon(Icons.person, color: Colors.white38, size: 56),
            ),
          ),
        ),

        // Camera badge (bottom-right)
        Positioned(
          bottom: 2,
          right: -2,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _C.cameraBadge,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  FIELD LABEL
// ─────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _C.labelColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE FIELD  (reusable with prefix icon)
// ─────────────────────────────────────────────
class _ProfileField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _ProfileField({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
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
          decoration: BoxDecoration(
            color: _C.fieldBg,
            borderRadius: BorderRadius.circular(_C.fieldRadius),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFD32F2F)
                  : _isFocused
                  ? _C.primary
                  : _C.fieldBorder,
              width: hasError || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
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
              color: _C.fieldText,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: widget.maxLines > 1 ? 14 : 0,
              ),
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  widget.prefixIcon,
                  color: _C.fieldPrefixIcon,
                  size: 20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 52,
              ),
            ),
          ),
        ),

        // Inline error
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 13,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(width: 4),
              Text(
                widget.errorText!,
                style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  VERIFY ACCOUNT ROW
// ─────────────────────────────────────────────
class _VerifyAccountRow extends StatelessWidget {
  final VoidCallback onTap;
  const _VerifyAccountRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _C.verifyCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.verifyCardBdr, width: 1),
        ),
        child: Row(
          children: [
            // Shield icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _C.verifyIconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: _C.verifyIconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xác thực tài khoản',
                    style: TextStyle(
                      color: _C.textDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Bảo mật thông tin của bạn',
                    style: TextStyle(color: _C.textLight, fontSize: 12.5),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: _C.verifyArrow, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SAVE BUTTON
// ─────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _SaveButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: _C.btnHeight,
        decoration: BoxDecoration(
          color: isLoading ? const Color(0xFF4CAF50) : _C.btnBg,
          borderRadius: BorderRadius.circular(_C.btnRadius),
          boxShadow: [
            BoxShadow(
              color: _C.btnBg.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'LƯU THAY ĐỔI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
