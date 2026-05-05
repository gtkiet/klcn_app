// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Import UserService, AuthService khi kết nối backend

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  // static const primaryDark = Color(0xFF1B5E20);
  // static const appBarBg = Color(0xFF2E7D32);
  // static const heroCardBg = Color(0xFF2E7D32);
  // static const heroCardBgLight = Color(0xFF388E3C);
  static const bgPage = Color(0xFFF2F5F0);
  static const cardBg = Colors.white;
  static const editBadge = Color(0xFF5C6BC0); // indigo/purple badge
  static const statDivider = Colors.white24;
  static const menuIcon = Color(0xFF2E7D32);
  static const menuIconBg = Color(0xFFE8F5E9);
  static const menuArrow = Color(0xFFBBBBBB);
  static const menuDivider = Color(0xFFF0F2EF);
  static const sectionLabel = Color(0xFF888888);
  static const logoutBg = Color(0xFFFFF0EE);
  static const logoutText = Color(0xFFE53935);
  static const logoutBorder = Color(0xFFFFCDD2);
  static const footerText = Color(0xFFAAAAAA);
  static const navUnselected = Color(0xFF9E9E9E);
  static const textDark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF555555);
  // static const textLight = Color(0xFF888888);
  // static const white = Colors.white;
}

abstract class _S {
  static const double pagePadH = 16.0;
  static const double cardRadius = 18.0;
  static const double menuRadius = 16.0;
  static const double avatarSize = 96.0;
  static const double btnRadius = 14.0;
}

// ─────────────────────────────────────────────
//  MOCK USER DATA
// ─────────────────────────────────────────────
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

// Menu item model
class _MenuItem {
  final IconData icon;
  final String label;
  final String route;

  const _MenuItem(this.icon, this.label, this.route);
}

final _accountMenuItems = [
  const _MenuItem(
    Icons.person_outline_rounded,
    'Thông tin cá nhân',
    '/edit_profile',
  ),
  const _MenuItem(
    Icons.lock_outline_rounded,
    'Đổi mật khẩu',
    '/change_password',
  ),
  const _MenuItem(Icons.history_rounded, 'Lịch sử đặt sân', '/booking_history'),
];

final _supportMenuItems = [
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
  int _currentNav = 3; // "HỒ SƠ" active

  void _onNavTap(int i) {
    setState(() => _currentNav = i);
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/fields');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/booking_history');
        break;
      default:
        break;
    }
  }

  void _onSettings() {
    // TODO: Navigator.pushNamed(context, '/settings');
    Navigator.pushNamed(context, '/settings');
  }

  void _onEditAvatar() {
    // TODO: ImagePicker → upload avatar → UserService.updateAvatar(file)
  }

  void _onMenuTap(String route) {
    // TODO: go_router context.push(route)
    Navigator.pushNamed(context, route);
  }

  void _onLogout() {
    // TODO: AuthService.logout() → clear token → context.go('/login')
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: _C.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: AuthService.logout()
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: _C.logoutText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bgPage,

        // ── AppBar ──────────────────────────────
        appBar: _ProfileAppBar(onSettings: _onSettings),

        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: _S.pagePadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // ── Hero profile card ────────────
              _ProfileHeroCard(user: _mockUser, onEditAvatar: _onEditAvatar),

              const SizedBox(height: 24),

              // ── Account & Settings group ─────
              _MenuSectionLabel(label: 'TÀI KHOẢN & THIẾT LẬP'),
              const SizedBox(height: 8),
              _MenuGroup(items: _accountMenuItems, onTap: _onMenuTap),

              const SizedBox(height: 20),

              // ── Support group ────────────────
              _MenuSectionLabel(label: 'THÔNG TIN HỖ TRỢ'),
              const SizedBox(height: 8),
              _MenuGroup(items: _supportMenuItems, onTap: _onMenuTap),

              const SizedBox(height: 24),

              // ── Logout button ────────────────
              _LogoutButton(onTap: _onLogout),

              const SizedBox(height: 28),

              // ── Footer version text ──────────
              const _FooterVersion(),

              const SizedBox(height: 32),
            ],
          ),
        ),

        // ── Bottom Nav ──────────────────────────
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentNav,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR  (green bg + settings icon)
// ─────────────────────────────────────────────
class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSettings;
  const _ProfileAppBar({required this.onSettings});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bgPage,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _C.primary),
        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
      ),
      title: const Text(
        'Hồ sơ',
        style: TextStyle(
          color: _C.primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      titleSpacing: 0,
      actions: [
        GestureDetector(
          onTap: onSettings,
          child: const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.settings_outlined, color: _C.primary, size: 24),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE HERO CARD  (green card)
// ─────────────────────────────────────────────
class _ProfileHeroCard extends StatelessWidget {
  final _UserData user;
  final VoidCallback onEditAvatar;

  const _ProfileHeroCard({required this.user, required this.onEditAvatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_S.cardRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
        ),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            // ── Avatar + edit badge ───────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Avatar circle
                Container(
                  width: _S.avatarSize,
                  height: _S.avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    // TODO: Thay bằng Image.network(user.avatarUrl, fit: BoxFit.cover)
                    child: Container(
                      color: const Color(0xFF8D6E63),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 52,
                      ),
                    ),
                  ),
                ),

                // Edit badge (bottom-right)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditAvatar,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: _C.editBadge,
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

            // ── Name ─────────────────────────
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            // ── Email | Phone ─────────────────
            Text(
              '${user.email} | ${user.phone}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // ── Divider ───────────────────────
            Divider(
              color: Colors.white.withValues(alpha: 0.2),
              indent: 24,
              endIndent: 24,
              height: 1,
            ),

            const SizedBox(height: 20),

            // ── Stats row ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    value: user.bookingCount.toString(),
                    label: 'LƯỢT ĐẶT',
                  ),
                  _StatDivider(),
                  _StatItem(value: user.rating.toString(), label: 'ĐÁNH GIÁ'),
                  _StatDivider(),
                  _StatItem(value: user.memberTier, label: 'THÀNH VIÊN'),
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
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: _C.statDivider);
  }
}

// ─────────────────────────────────────────────
//  MENU SECTION LABEL
// ─────────────────────────────────────────────
class _MenuSectionLabel extends StatelessWidget {
  final String label;
  const _MenuSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _C.sectionLabel,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MENU GROUP  (white card with dividers)
// ─────────────────────────────────────────────
class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  final ValueChanged<String> onTap;

  const _MenuGroup({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.menuRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;

          return Column(
            children: [
              _MenuRow(item: item, onTap: () => onTap(item.route)),
              if (!isLast)
                const Divider(
                  height: 1,
                  color: _C.menuDivider,
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

// ─────────────────────────────────────────────
//  MENU ROW
// ─────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.menuIconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: _C.menuIcon, size: 20),
            ),

            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: _C.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: _C.menuArrow, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LOGOUT BUTTON
// ─────────────────────────────────────────────
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
          color: _C.logoutBg,
          borderRadius: BorderRadius.circular(_S.btnRadius),
          border: Border.all(color: _C.logoutBorder, width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: _C.logoutText, size: 20),
            SizedBox(width: 10),
            Text(
              'ĐĂNG XUẤT',
              style: TextStyle(
                color: _C.logoutText,
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

// ─────────────────────────────────────────────
//  FOOTER VERSION TEXT
// ─────────────────────────────────────────────
class _FooterVersion extends StatelessWidget {
  const _FooterVersion();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.sports_soccer,
          size: 20,
          color: _C.footerText.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'SPORT PLUS V2.4.0 • PITCH PRECISION ENGINE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.footerText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: _C.primary,
      unselectedItemColor: _C.navUnselected,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Fields'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
