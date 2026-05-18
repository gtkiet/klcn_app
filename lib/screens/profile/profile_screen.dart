// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/profile_service.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';

// ── MENU CONFIG ───────────────────────────────
class _MenuItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String route;
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.route,
  });
}

final _accountItems = [
  _MenuItem(
    icon: Icons.person_outline_rounded,
    iconBg: AppColors.primaryUltraLight,
    iconColor: AppColors.primary,
    label: 'Thông tin cá nhân',
    route: 'edit_profile',
  ),
  _MenuItem(
    icon: Icons.lock_outline_rounded,
    iconBg: AppColors.primaryUltraLight,
    iconColor: AppColors.primary,
    label: 'Đổi mật khẩu',
    route: 'change_password',
  ),
  _MenuItem(
    icon: Icons.history_rounded,
    iconBg: AppColors.primaryUltraLight,
    iconColor: AppColors.primary,
    label: 'Lịch sử đặt sân',
    route: '/booking_history',
  ),
];

final _supportItems = [
  _MenuItem(
    icon: Icons.help_outline_rounded,
    iconBg: const Color(0xFFE3F2FD),
    iconColor: AppColors.infoBlue,
    label: 'Hỗ trợ & Liên hệ',
    route: '',
  ),
  _MenuItem(
    icon: Icons.description_outlined,
    iconBg: const Color(0xFFF3E5F5),
    iconColor: const Color(0xFF7B1FA2),
    label: 'Điều khoản & Chính sách',
    route: '',
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
  final _service = ProfileService.instance;

  UserModel? _user;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Hiển thị ngay từ session
    setState(() {
      _user = _service.getCachedUser();
      _isLoading = false;
    });

    // Fetch fresh data ở background
    try {
      final user = await ProfileService.instance.getProfile();
      if (mounted) setState(() => _user = user);
    } catch (_) {
      // Giữ dữ liệu session nếu API lỗi
    }
  }

  void _onMenuItem(String route) {
    if (route.isEmpty) return; // menu chưa có route thật
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
      await ProfileService.instance.logout();
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

                      // ── Hero card ────────────────────────────────
                      _ProfileHeroCard(
                        user: _user,
                        onEditTap: () => context.push('/profile/edit_profile'),
                        avatarUrlNotifier: _service.avatarUrlNotifier,
                      ),
                      const SizedBox(height: 24),

                      // ── Account section ──────────────────────────
                      _SectionLabel('TÀI KHOẢN & THIẾT LẬP'),
                      const SizedBox(height: 8),
                      _MenuGroup(items: _accountItems, onTap: _onMenuItem),
                      const SizedBox(height: 20),

                      // ── Support section ──────────────────────────
                      _SectionLabel('THÔNG TIN & HỖ TRỢ'),
                      const SizedBox(height: 8),
                      _MenuGroup(items: _supportItems, onTap: _onMenuItem),
                      const SizedBox(height: 24),

                      // ── Logout ───────────────────────────────────
                      _LogoutButton(
                        onTap: _isLoggingOut ? () {} : _onLogout,
                        isLoading: _isLoggingOut,
                      ),
                      const SizedBox(height: 28),

                      // ── Footer ───────────────────────────────────
                      Column(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 20,
                            color: AppColors.textHint.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'SPORT PLUS V1.0.0  •  PITCH PRECISION ENGINE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textHint.withValues(alpha: 0.7),
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

// ── PROFILE HERO CARD ─────────────────────────
class _ProfileHeroCard extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onEditTap;
  final ValueNotifier<String?> avatarUrlNotifier;

  const _ProfileHeroCard({
    required this.user,
    required this.onEditTap,
    required this.avatarUrlNotifier,
  });

  @override
  Widget build(BuildContext context) {
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
            // ── Avatar ─────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: avatarUrlNotifier,
                  builder: (_, avatarUrl, _) => Container(
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
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _avatarFallback(),
                            )
                          : _avatarFallback(),
                    ),
                  ),
                ),

                // Edit avatar shortcut
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditTap,
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

            // ── Name ───────────────────────────────────
            Text(
              user?.fullName ?? '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),

            // ── Email + Phone ──────────────────────────
            Text(
              [
                user?.email ?? '',
                user?.phone ?? '',
              ].where((s) => s.isNotEmpty).join('  •  '),
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

            // ── Stats row ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(value: user?.role ?? '—', label: 'VAI TRÒ'),
                  _Divider(),
                  _StatItem(value: user?.status ?? '—', label: 'TRẠNG THÁI'),
                  _Divider(),
                  _StatItem(
                    value: 'ID ${user?.userId ?? '—'}',
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
            fontSize: 13,
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: Colors.white.withValues(alpha: 0.25),
  );
}

// ── SECTION LABEL ─────────────────────────────
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

// ── MENU GROUP ────────────────────────────────
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
                color: item.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
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

// ── LOGOUT BUTTON ─────────────────────────────
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
