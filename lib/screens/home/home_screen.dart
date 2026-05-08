// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

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
  _NearbyField(
    'Sân Phú Nhuận',
    '1.1 km',
    'Phú Nhuận',
    '420k/h',
    Color(0xFF2E7D32),
  ),
  _NearbyField(
    'Sân Bình Thạnh',
    '3.2 km',
    'Bình Thạnh',
    '380k/h',
    Color(0xFF00695C),
  ),
];

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  void _onNavTap(int i) {
    if (_tab == i) return;
    setState(() => _tab = i);
    switch (i) {
      case 1:
        Navigator.pushReplacementNamed(context, '/fields');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/booking_history');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

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
                  onAction: () => Navigator.pushNamed(context, '/fields'),
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
                  onAction: () => Navigator.pushNamed(context, '/fields'),
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
                  onBookTap: () =>
                      Navigator.pushNamed(context, '/field_detail'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        bottomNavigationBar: SpBottomNav(currentIndex: _tab, onTap: _onNavTap),
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
    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Xin chào 👋',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'Tuấn Kiệt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
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
        onTap: () {}, // TODO: navigate to search
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
              Positioned(
                right: 20,
                top: 20,
                child: const Icon(
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
          onTap: () => Navigator.pushNamed(context, '/field_detail'),
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
            // Placeholder image
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
          // Placeholder image
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
