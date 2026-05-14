// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../guards/auth_guard.dart';
import '../../services/profile_service.dart';
import '../../session/user_session.dart';
import '../../network/api_client.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';

// ── HELPER ────────────────────────────────────
String? _buildAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '${ApiClient.baseUrl}$path';
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  const _MenuItem(this.icon, this.label, this.route);
}

final _accountItems = [
  const _MenuItem(
    Icons.person_outline_rounded,
    'Thông tin cá nhân',
    'edit_profile',
  ),
  const _MenuItem(
    Icons.lock_outline_rounded,
    'Đổi mật khẩu',
    'change_password',
  ),
  const _MenuItem(
    Icons.history_rounded,
    'Lịch sử đặt sân',
    '/booking_history',
  ),
];

final _supportItems = [
  const _MenuItem(Icons.help_outline_rounded, 'Hỗ trợ & Liên hệ', '/support'),
  const _MenuItem(
    Icons.description_outlined,
    'Điều khoản & Chính sách',
    '/terms',
  ),
];

// ─────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _session = UserSession.instance;

  UserModel? _user;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Hiển thị dữ liệu từ session ngay lập tức
    setState(() {
      _user = _session.toUserModel();
      _isLoading = false;
    });

    // Fetch fresh data từ API ở background
    try {
      final user = await ProfileService.instance.getProfile();
      if (mounted) setState(() => _user = user);
    } catch (_) {
      // Giữ dữ liệu session nếu API lỗi
    }
  }

  void _onMenuItem(String route) {
    if (route.startsWith('/')) {
      context.push(route);
    } else {
      context.push('/profile/$route');
    }
  }

  Future<void> _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textMid),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: AppColors.logoutText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      // FIX: gọi AuthGuard.logout() — nó gọi AuthService.logout() rồi
      // tự set unauthenticated → GoRouter redirect về /auth/login
      await AuthGuard.instance.logout();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Hồ sơ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {}, // TODO: settings
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      _ProfileHeroCard(
                        user: _user,
                        onEditAvatar: () =>
                            context.push('/profile/edit_profile'),
                      ),
                      const SizedBox(height: 24),

                      _SectionLabel('TÀI KHOẢN & THIẾT LẬP'),
                      const SizedBox(height: 8),
                      _MenuGroup(items: _accountItems, onTap: _onMenuItem),
                      const SizedBox(height: 20),

                      _SectionLabel('THÔNG TIN HỖ TRỢ'),
                      const SizedBox(height: 8),
                      _MenuGroup(items: _supportItems, onTap: _onMenuItem),
                      const SizedBox(height: 24),

                      _LogoutButton(
                        onTap: _isLoggingOut ? () {} : _onLogout,
                        isLoading: _isLoggingOut,
                      ),
                      const SizedBox(height: 28),

                      Column(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 20,
                            color: AppColors.textHint.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'SPORT PLUS V2.4.0  •  PITCH PRECISION ENGINE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
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
}

// ── PROFILE HERO CARD ──────────────────────────────────────────────────────
class _ProfileHeroCard extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onEditAvatar;

  const _ProfileHeroCard({required this.user, required this.onEditAvatar});

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            // Avatar — reactive với ValueListenableBuilder
            Stack(
              clipBehavior: Clip.none,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: session.avatarUrlNotifier,
                  builder: (_, rawUrl, _) {
                    // FIX: prefix base URL vì session lưu path "/Uploads/..."
                    final url = _buildAvatarUrl(rawUrl);
                    return Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: url != null
                            ? Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _avatarFallback(),
                              )
                            : _avatarFallback(),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditAvatar,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5C6BC0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              user?.fullName ?? session.fullName ?? '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${user?.email ?? session.email ?? ''}  •  ${user?.phone ?? session.phone ?? ''}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Divider(
              color: Colors.white.withValues(alpha: 0.20),
              indent: 24,
              endIndent: 24,
              height: 1,
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    value: user?.role ?? session.role ?? '—',
                    label: 'VAI TRÒ',
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  _StatItem(
                    value: user?.status ?? session.status ?? '—',
                    label: 'TRẠNG THÁI',
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  _StatItem(
                    value: 'ID ${user?.userId ?? session.userId ?? '—'}',
                    label: 'TÀI KHOẢN',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: const Color(0xFF8D6E63),
        child: const Icon(Icons.person, color: Colors.white54, size: 52),
      );
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ── SECTION LABEL ──────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textLight,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── MENU GROUP ─────────────────────────────────────────────────────────────
class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  final ValueChanged<String> onTap;
  const _MenuGroup({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final isLast = i == items.length - 1;
          return Column(
            children: [
              _MenuRow(item: items[i], onTap: () => onTap(items[i].route)),
              if (!isLast)
                const Divider(
                  height: 1,
                  color: Color(0xFFF0F2EF),
                  indent: 60,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  const _MenuRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryUltraLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── LOGOUT BUTTON ──────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _LogoutButton({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.logoutBg,
          borderRadius: BorderRadius.circular(AppSpacing.btnRadius),
          border: Border.all(color: AppColors.logoutBorder),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.logoutText,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: AppColors.logoutText,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'ĐĂNG XUẤT',
                    style: TextStyle(
                      color: AppColors.logoutText,
                      fontSize: 15,
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