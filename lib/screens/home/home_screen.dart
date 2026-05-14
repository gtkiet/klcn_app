// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';

import '../../session/user_session.dart';
import '../../network/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── HELPER ────────────────────────────────────
String? buildAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '${ApiClient.baseUrl}$path';
}

// ── MOCK DATA ─────────────────────────────────
class _FeaturedField {
  final String name;
  final double rating;
  final String price;
  final Color color;
  const _FeaturedField(this.name, this.rating, this.price, this.color);
}

class _NearbyField {
  final String name;
  final String distance;
  final String district;
  final String price;
  final Color color;
  const _NearbyField(
    this.name,
    this.distance,
    this.district,
    this.price,
    this.color,
  );
}

const _featuredFields = [
  _FeaturedField('Arena Santiago', 4.8, '450k/h', Color(0xFF388E3C)),
  _FeaturedField('Sport Center Q7', 4.6, '520k/h', Color(0xFF1565C0)),
  _FeaturedField('Green Field BT', 4.7, '390k/h', Color(0xFF00695C)),
];

const _nearbyFields = [
  _NearbyField('Sân Hoa Lư', '2.4 km', 'Quận 1', '350k/h', Color(0xFF43A047)),
  _NearbyField('Sân Phú Nhuận', '1.1 km', 'Phú Nhuận', '420k/h', Color(0xFF2E7D32)),
  _NearbyField('Sân Bình Thạnh', '3.2 km', 'Bình Thạnh', '380k/h', Color(0xFF00695C)),
];

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: _HomeAppBar(),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Search bar
            SliverToBoxAdapter(child: _SearchBar()),

            // Promo banner
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: _PromoBanner()),

            // Featured fields
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadH,
                ),
                child: SpSectionHeader(
                  title: 'Sân nổi bật',
                  actionLabel: 'Xem tất cả',
                  onAction: () {}, // TODO: navigate to fields
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _FeaturedRow()),

            // Nearby fields
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadH,
                ),
                child: SpSectionHeader(
                  title: 'Gần bạn',
                  actionLabel: 'Xem tất cả',
                  onAction: () {}, // TODO: navigate to fields
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadH,
              ),
              sliver: SliverList.builder(
                itemCount: _nearbyFields.length,
                itemBuilder: (_, i) => _NearbyCard(
                  field: _nearbyFields[i],
                  onBookTap: () {}, // TODO: navigate to field detail
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        // Không có bottomNavigationBar — đã được MainScreen quản lý
      ),
    );
  }
}

// ── APP BAR ───────────────────────────────────
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    final avatarUrl = buildAvatarUrl(session.avatarUrl);
    final displayName = session.fullName ?? 'Bạn';

    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,

      // QUAN TRỌNG
      leadingWidth: MediaQuery.of(context).size.width,

      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _AvatarPlaceholder(),
                      )
                    : const _AvatarPlaceholder(),
              ),
            ),

            const SizedBox(width: 10),

            // Greeting + name
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào 👋',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),

      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ── AVATAR PLACEHOLDER ────────────────────────
class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      color: Colors.white24,
      child: const Icon(Icons.person, size: 20, color: Colors.white),
    );
  }
}

// ── SEARCH BAR ────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
      child: GestureDetector(
        onTap: () {}, // TODO: search
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadow.card,
          ),
          child: const Row(
            children: [
              SizedBox(width: 14),
              Icon(Icons.search, color: AppColors.textHint),
              SizedBox(width: 10),
              Text(
                'Tìm sân theo tên, quận...',
                style: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PROMO BANNER ──────────────────────────────
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          height: 148,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D3B1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Positioned(
                right: 20,
                top: 20,
                child: Icon(
                  Icons.sports_soccer,
                  color: Colors.white12,
                  size: 80,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ƯU ĐÃI HÔM NAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Giảm 20% sân sáng sớm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đặt sân từ 6:00 – 9:00 sáng mỗi ngày',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FEATURED ROW ──────────────────────────────
class _FeaturedRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
        itemCount: _featuredFields.length,
        itemBuilder: (_, i) => _FeaturedCard(
          field: _featuredFields[i],
          onTap: () {}, // TODO: navigate to field detail
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final _FeaturedField field;
  final VoidCallback onTap;
  const _FeaturedCard({required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 178,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: AppShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.cardRadius),
                  ),
                  child: Container(
                    height: 112,
                    color: field.color,
                    child: const Center(
                      child: Icon(
                        Icons.sports_soccer,
                        color: Colors.white24,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppColors.ratingGold,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          field.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    field.price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryUltraLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Đặt ngay',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── NEARBY CARD ───────────────────────────────
class _NearbyCard extends StatelessWidget {
  final _NearbyField field;
  final VoidCallback onBookTap;
  const _NearbyCard({required this.field, required this.onBookTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 88,
              height: 88,
              color: field.color,
              child: const Center(
                child: Icon(
                  Icons.sports_soccer,
                  color: Colors.white30,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${field.distance} • ${field.district}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      field.price,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: onBookTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Đặt ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}