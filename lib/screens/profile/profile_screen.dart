// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── MOCK DATA ─────────────────────────────────
class _UserData {
  final String name;
  final String email;
  final String phone;
  final int bookingCount;
  final double rating;
  final String memberTier;

  const _UserData({
    required this.name,
    required this.email,
    required this.phone,
    required this.bookingCount,
    required this.rating,
    required this.memberTier,
  });
}

const _mockUser = _UserData(
  name: 'Nguyễn Văn A',
  email: 'nguyenvana@email.com',
  phone: '090 123 4567',
  bookingCount: 12,
  rating: 4.9,
  memberTier: 'MVP',
);

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  const _MenuItem(this.icon, this.label, this.route);
}

final _accountItems = [
  const _MenuItem(Icons.person_outline_rounded,  'Thông tin cá nhân', '/edit_profile'),
  const _MenuItem(Icons.lock_outline_rounded,    'Đổi mật khẩu',     '/change_password'),
  const _MenuItem(Icons.history_rounded,         'Lịch sử đặt sân',  '/booking_history'),
];

final _supportItems = [
  const _MenuItem(Icons.help_outline_rounded,    'Hỗ trợ & Liên hệ',         '/support'),
  const _MenuItem(Icons.description_outlined,    'Điều khoản & Chính sách',  '/terms'),
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
  int _currentNav = 3;

  void _onNavTap(int i) {
    setState(() => _currentNav = i);
    switch (i) {
      case 0: Navigator.pushReplacementNamed(context, '/home'); break;
      case 1: Navigator.pushReplacementNamed(context, '/fields'); break;
      case 2: Navigator.pushReplacementNamed(context, '/booking_history'); break;
    }
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: AuthService.logout()
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: AppColors.logoutText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          title: const Text('Hồ sơ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Hero card
              _ProfileHeroCard(
                user: _mockUser,
                onEditAvatar: () {},
              ),
              const SizedBox(height: 24),

              // Account menu
              _SectionLabel('TÀI KHOẢN & THIẾT LẬP'),
              const SizedBox(height: 8),
              _MenuGroup(items: _accountItems, onTap: (r) => Navigator.pushNamed(context, r)),
              const SizedBox(height: 20),

              // Support menu
              _SectionLabel('THÔNG TIN HỖ TRỢ'),
              const SizedBox(height: 8),
              _MenuGroup(items: _supportItems, onTap: (r) => Navigator.pushNamed(context, r)),
              const SizedBox(height: 24),

              // Logout
              _LogoutButton(onTap: _onLogout),
              const SizedBox(height: 28),

              // Footer
              Column(
                children: [
                  Icon(Icons.sports_soccer, size: 20,
                      color: AppColors.textHint.withValues(alpha: 0.5)),
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
        bottomNavigationBar: SpBottomNav(currentIndex: _currentNav, onTap: _onNavTap),
      ),
    );
  }
}

// ── PROFILE HERO CARD ─────────────────────────
class _ProfileHeroCard extends StatelessWidget {
  final _UserData user;
  final VoidCallback onEditAvatar;
  const _ProfileHeroCard({required this.user, required this.onEditAvatar});

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
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                    child: Container(
                      color: const Color(0xFF8D6E63),
                      child: const Icon(Icons.person, color: Colors.white54, size: 52),
                    ),
                  ),
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
                      child: const Icon(Icons.edit, color: Colors.white, size: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(user.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              '${user.email}  •  ${user.phone}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80), fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Divider(color: Colors.white.withValues(alpha: 0.20), indent: 24, endIndent: 24, height: 1),
            const SizedBox(height: 20),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(value: '${user.bookingCount}', label: 'LƯỢT ĐẶT'),
                  Container(width: 1, height: 36,
                      color: Colors.white.withValues(alpha: 0.25)),
                  _StatItem(value: '${user.rating}',      label: 'ĐÁNH GIÁ'),
                  Container(width: 1, height: 36,
                      color: Colors.white.withValues(alpha: 0.25)),
                  _StatItem(value: user.memberTier,       label: 'THÀNH VIÊN'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            )),
      ],
    );
  }
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
                const Divider(height: 1, color: Color(0xFFF0F2EF), indent: 60, endIndent: 16),
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
              child: Text(item.label,
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── LOGOUT BUTTON ─────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.logoutText, size: 20),
            SizedBox(width: 10),
            Text('ĐĂNG XUẤT',
                style: TextStyle(
                  color: AppColors.logoutText,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                )),
          ],
        ),
      ),
    );
  }
}
