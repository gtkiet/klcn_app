// lib/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/profile_service.dart';
import '../../session/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _session = UserSession.instance;

  late final _nameCtrl    = TextEditingController(text: _session.fullName ?? '');
  late final _phoneCtrl   = TextEditingController(text: _session.phone    ?? '');
  late final _addressCtrl = TextEditingController(text: _session.address  ?? '');

  final _nameFocus    = FocusNode();
  final _phoneFocus   = FocusNode();
  final _addressFocus = FocusNode();

  DateTime? _selectedDob;
  bool _isLoading         = false;
  bool _isUploadingAvatar = false;

  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    // Parse dob từ session nếu có
    if (_session.dateOfBirth != null) {
      _selectedDob = DateTime.tryParse(_session.dateOfBirth!);
    }
    // Fetch fresh data, điền lại form nếu có gì mới
    _loadFreshProfile();
  }

  Future<void> _loadFreshProfile() async {
    try {
      final user = await ProfileService.instance.getProfile();
      if (!mounted) return;
      _nameCtrl.text    = user.fullName;
      _phoneCtrl.text   = user.phone;
      _addressCtrl.text = user.address ?? '';
      setState(() => _selectedDob = user.dateOfBirth);
    } catch (_) {
      // Giữ dữ liệu session
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();    _nameFocus.dispose();
    _phoneCtrl.dispose();   _phoneFocus.dispose();
    _addressCtrl.dispose(); _addressFocus.dispose();
    super.dispose();
  }

  // ── Validate ──────────────────────────────────────────────────
  bool _validate() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty
          ? 'Vui lòng nhập họ và tên'
          : null;
      _phoneError = _phoneCtrl.text.trim().length < 9
          ? 'Số điện thoại không hợp lệ'
          : null;
    });
    return _nameError == null && _phoneError == null;
  }

  // ── Save profile ───────────────────────────────────────────────
  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await ProfileService.instance.updateProfile(
        fullName:    _nameCtrl.text.trim(),
        phone:       _phoneCtrl.text.trim(),
        dateOfBirth: _selectedDob,
        address:     _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hồ sơ đã được cập nhật thành công!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
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

  // ── Pick & upload avatar ───────────────────────────────────────
  Future<void> _onPickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'CHỌN ẢNH ĐẠI DIỆN',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: _SheetIconBox(Icons.photo_library_outlined),
                title: const Text(
                  'Chọn từ thư viện',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text(
                  'Chọn ảnh có sẵn trên thiết bị',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const Divider(indent: 70, endIndent: 16, height: 1),
              ListTile(
                leading: _SheetIconBox(Icons.camera_alt_outlined),
                title: const Text(
                  'Chụp ảnh mới',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: const Text(
                  'Dùng camera để chụp ảnh đại diện',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:       source,
      imageQuality: 85,
      maxWidth:     1024,
      maxHeight:    1024,
    );

    if (file == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ProfileService.instance.updateAvatar(file.path);
      // session.avatarUrlNotifier đã update trong service
      // → ValueListenableBuilder tự rebuild
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật ảnh thất bại: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ── Date picker ────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedDob ?? DateTime(now.year - 20),
      firstDate:   DateTime(1940),
      lastDate:    DateTime(now.year - 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  String get _dobText => _selectedDob != null
      ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
      : 'Chọn ngày sinh';

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
          title: const Text('Chỉnh sửa hồ sơ'),
          actions: [
            // Nút Lưu nhanh trên AppBar
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // ── Avatar ──────────────────────────────────────
                Center(
                  child: _AvatarSection(
                    isUploading: _isUploadingAvatar,
                    onTap:       _onPickAvatar,
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: Text(
                    _session.fullName ?? '—',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    _session.email ?? '',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // ── Họ và tên ───────────────────────────────────
                const SpFieldLabel('HỌ VÀ TÊN'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller:    _nameCtrl,
                  focusNode:     _nameFocus,
                  nextFocusNode: _phoneFocus,
                  prefixIcon:    Icons.person_outline_rounded,
                  keyboardType:  TextInputType.name,
                  errorText:     _nameError,
                  onChanged:     (_) => setState(() => _nameError = null),
                ),
                const SizedBox(height: 18),

                // ── Email (read-only) ────────────────────────────
                const SpFieldLabel('EMAIL'),
                const SizedBox(height: 8),
                _ReadOnlyField(
                  value:      _session.email ?? '',
                  prefixIcon: Icons.email_outlined,
                  hint:       'Email không thể thay đổi',
                ),
                const SizedBox(height: 18),

                // ── Số điện thoại ────────────────────────────────
                const SpFieldLabel('SỐ ĐIỆN THOẠI'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller:    _phoneCtrl,
                  focusNode:     _phoneFocus,
                  nextFocusNode: _addressFocus,
                  prefixIcon:    Icons.phone_android_outlined,
                  keyboardType:  TextInputType.phone,
                  errorText:     _phoneError,
                  onChanged:     (_) => setState(() => _phoneError = null),
                ),
                const SizedBox(height: 18),

                // ── Ngày sinh ────────────────────────────────────
                const SpFieldLabel('NGÀY SINH'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDob,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBg,
                      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            Icons.cake_outlined,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                        ),
                        Text(
                          _dobText,
                          style: TextStyle(
                            color: _selectedDob != null
                                ? AppColors.textDark
                                : AppColors.textHint,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Địa chỉ ─────────────────────────────────────
                const SpFieldLabel('ĐỊA CHỈ'),
                const SizedBox(height: 8),
                _ProfileField(
                  controller:   _addressCtrl,
                  focusNode:    _addressFocus,
                  prefixIcon:   Icons.location_on_outlined,
                  keyboardType: TextInputType.streetAddress,
                  maxLines:     2,
                ),
                const SizedBox(height: 28),

                // ── Save button ──────────────────────────────────
                SpPrimaryButton(
                  label:        'LƯU THAY ĐỔI',
                  isLoading:    _isLoading,
                  onTap:        _onSave,
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
  final bool isUploading;

  const _AvatarSection({required this.onTap, this.isUploading = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: UserSession.instance.avatarUrlNotifier,
          builder: (_, avatarUrl, _) => Container(
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
              child: isUploading
                  ? Container(
                      color: AppColors.fieldBg,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallback(),
                        )
                      : _fallback(),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: -2,
          child: GestureDetector(
            onTap: isUploading ? null : onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isUploading ? AppColors.primaryLight : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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

  Widget _fallback() => Container(
        color: const Color(0xFF7B6052),
        child: const Icon(Icons.person, color: Colors.white38, size: 56),
      );
}

// ── BOTTOM SHEET ICON BOX ─────────────────────
class _SheetIconBox extends StatelessWidget {
  final IconData icon;
  const _SheetIconBox(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primaryUltraLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

// ── READ-ONLY FIELD ───────────────────────────
class _ReadOnlyField extends StatelessWidget {
  final String value;
  final IconData prefixIcon;
  final String hint;

  const _ReadOnlyField({
    required this.value,
    required this.prefixIcon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.fieldBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(prefixIcon, color: AppColors.textHint, size: 20),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : hint,
              style: TextStyle(
                color: value.isNotEmpty ? AppColors.textMid : AppColors.textHint,
                fontSize: 15,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.lock_outline, color: AppColors.textHint, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── PROFILE FIELD ─────────────────────────────
// Animated border khi focus — dùng riêng vì SpTextField không có focus color
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
            controller:      widget.controller,
            focusNode:       widget.focusNode,
            keyboardType:    widget.keyboardType,
            maxLines:        widget.maxLines,
            onChanged:       widget.onChanged,
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
                horizontal: 14,
                vertical: widget.maxLines > 1 ? 14 : 0,
              ),
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? AppColors.primary : AppColors.textHint,
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
        if (hasError) SpErrorText(widget.errorText!),
      ],
    );
  }
}