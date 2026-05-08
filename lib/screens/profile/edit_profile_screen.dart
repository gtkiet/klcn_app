// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl    = TextEditingController(text: 'Nguyễn Văn A');
  final _emailCtrl   = TextEditingController(text: 'nguyenvana.sport@gmail.com');
  final _phoneCtrl   = TextEditingController(text: '0987 654 321');
  final _addressCtrl = TextEditingController(
      text: '123 Đường Thể Thao, Quận 1, TP. Hồ Chí Minh');

  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _phoneFocus   = FocusNode();
  final _addressFocus = FocusNode();

  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _nameCtrl.dispose();    _nameFocus.dispose();
    _emailCtrl.dispose();   _emailFocus.dispose();
    _phoneCtrl.dispose();   _phoneFocus.dispose();
    _addressCtrl.dispose(); _addressFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError  = _nameCtrl.text.trim().isEmpty ? 'Vui lòng nhập họ và tên' : null;
      _emailError = !_emailCtrl.text.contains('@') ? 'Email không hợp lệ' : null;
      _phoneError = _phoneCtrl.text.trim().length < 9 ? 'Số điện thoại không hợp lệ' : null;
    });
    return _nameError == null && _emailError == null && _phoneError == null;
  }

  void _onSave() {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _isLoading = true);
    // TODO: UserService.updateProfile(name, email, phone, address)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hồ sơ đã được cập nhật thành công!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
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
          title: const Text('Chỉnh sửa hồ sơ'),
          actions: [
            GestureDetector(
              onTap: _isLoading ? null : _onSave,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Lưu',
                    style: TextStyle(
                      color: _isLoading
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // Avatar
                Center(child: _AvatarSection(onTap: () {})),
                const SizedBox(height: 14),

                // Name + tier
                const Center(
                  child: Text('Nguyễn Văn A',
                      style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Thành viên Hạng Vàng  •  ID: SP-2024',
                      style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                ),
                const SizedBox(height: 30),

                // Fields
                const SpFieldLabel('HỌ VÀ TÊN'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  nextFocusNode: _emailFocus,
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  errorText: _nameError,
                  onChanged: (_) => setState(() => _nameError = null),
                ),
                const SizedBox(height: 18),

                const SpFieldLabel('EMAIL'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  nextFocusNode: _phoneFocus,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) => setState(() => _emailError = null),
                ),
                const SizedBox(height: 18),

                const SpFieldLabel('SỐ ĐIỆN THOẠI'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _phoneCtrl,
                  focusNode: _phoneFocus,
                  nextFocusNode: _addressFocus,
                  prefixIcon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  errorText: _phoneError,
                  onChanged: (_) => setState(() => _phoneError = null),
                ),
                const SizedBox(height: 18),

                const SpFieldLabel('ĐỊA CHỈ'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller: _addressCtrl,
                  focusNode: _addressFocus,
                  prefixIcon: Icons.location_on_outlined,
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Verify row
                _VerifyRow(onTap: () => Navigator.pushNamed(context, '/verify')),
                const SizedBox(height: 28),

                // Save button
                SpPrimaryButton(
                  label: 'LƯU THAY ĐỔI',
                  isLoading: _isLoading,
                  onTap: _onSave,
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

// ── AVATAR SECTION ────────────────────────────
class _AvatarSection extends StatelessWidget {
  final VoidCallback onTap;
  const _AvatarSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF7B6052),
              child: const Icon(Icons.person, color: Colors.white38, size: 56),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: -2,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
    );
  }
}

// ── PROFILE FIELD ─────────────────────────────
class _ProfileField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _ProfileField({
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
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
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            textInputAction: widget.nextFocusNode != null
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: (_) {
              if (widget.nextFocusNode != null) {
                FocusScope.of(context).requestFocus(widget.nextFocusNode);
              } else {
                widget.focusNode.unfocus();
              }
            },
            style: const TextStyle(color: AppColors.textDark, fontSize: 15.5),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 14, vertical: widget.maxLines > 1 ? 14 : 0),
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(widget.prefixIcon, color: AppColors.primary, size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 52),
            ),
          ),
        ),
        if (hasError) SpErrorText(widget.errorText!),
      ],
    );
  }
}

// ── VERIFY ROW ────────────────────────────────
class _VerifyRow extends StatelessWidget {
  final VoidCallback onTap;
  const _VerifyRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryUltraLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_outlined,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xác thực tài khoản',
                      style: TextStyle(
                          color: AppColors.textDark, fontSize: 14.5, fontWeight: FontWeight.w700)),
                  SizedBox(height: 3),
                  Text('Bảo mật thông tin của bạn',
                      style: TextStyle(color: AppColors.textLight, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    );
  }
}
