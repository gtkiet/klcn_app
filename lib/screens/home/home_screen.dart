// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:klcn_app/navigation/app_navigation.dart';

import '../../models/field.dart';
import '../../services/field_service.dart';
import '../../services/notification_service.dart';
import '../../session/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FieldModel> _fields = [];
  bool _isLoading = true;
  String? _errorMsg;

  // Badge thông báo chưa đọc
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFields();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.instance.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Badge lỗi → không hiện, không crash
    }
  }

  void _goToNotifications() async {
    await context.push('/notifications');
    // Refresh badge khi quay lại từ notification screen
    _loadUnreadCount();
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final result = await FieldService.instance.getFields(
        statusId: 1,
        page: 1,
        pageSize: 10,
      );
      if (mounted) {
        setState(() {
          _fields = result.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _goToFields() => AppNavigation.goFields();

  void _goToFieldDetail(FieldModel field) =>
      context.push('/fields/detail', extra: field);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: _HomeAppBar(
          onNotificationTap: _goToNotifications,
          unreadCount: _unreadCount,
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadFields,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Search bar ─────────────────────────────────
              SliverToBoxAdapter(child: _SearchBar(onTap: _goToFields)),

              // ── Promo banner ───────────────────────────────
              // const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // const SliverToBoxAdapter(child: _PromoBanner()),

              // ── Sân nổi bật ────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadH,
                  ),
                  child: SpSectionHeader(
                    title: 'Sân nổi bật',
                    actionLabel: 'Xem tất cả',
                    onAction: _goToFields,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _FeaturedRow(
                  fields: _fields.take(5).toList(),
                  isLoading: _isLoading,
                  errorMsg: _errorMsg,
                  onTap: _goToFieldDetail,
                  onRetry: _loadFields,
                ),
              ),

              // ── Tất cả sân ─────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadH,
                  ),
                  child: SpSectionHeader(
                    title: 'Tất cả sân',
                    actionLabel: 'Xem tất cả',
                    onAction: _goToFields,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (_errorMsg != null && _fields.isEmpty)
                SliverToBoxAdapter(
                  child: _ErrorBanner(
                    message: _errorMsg!,
                    onRetry: _loadFields,
                  ),
                )
              else if (_fields.isEmpty)
                const SliverToBoxAdapter(child: _EmptyBanner())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadH,
                  ),
                  sliver: SliverList.builder(
                    itemCount: _fields.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FieldListCard(
                        field: _fields[i],
                        onTap: () => _goToFieldDetail(_fields[i]),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── APP BAR ───────────────────────────────────
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onNotificationTap;
  final int unreadCount;

  const _HomeAppBar({
    required this.onNotificationTap,
    required this.unreadCount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;

    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      leadingWidth: MediaQuery.of(context).size.width,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            // Avatar reactive
            ValueListenableBuilder<String?>(
              valueListenable: session.avatarUrlNotifier,
              builder: (_, avatarUrl, _) => CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _AvatarFallback(),
                        )
                      : const _AvatarFallback(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
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
                    session.fullName ?? 'Bạn',
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
            ),
          ],
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: onNotificationTap,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();
  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    color: Colors.white24,
    child: const Icon(Icons.person, size: 20, color: Colors.white),
  );
}

// ── SEARCH BAR ────────────────────────────────
// Tap-only — navigate sang FieldListScreen để search thật
class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
      child: GestureDetector(
        onTap: onTap,
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
                'Tìm sân theo tên...',
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
// class _PromoBanner extends StatelessWidget {
//   const _PromoBanner();

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         child: Container(
//           height: 148,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF1565C0), Color(0xFF0D3B1A)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Stack(
//             children: [
//               Positioned(
//                 right: -20,
//                 top: -20,
//                 child: Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.05),
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//               const Positioned(
//                 right: 20,
//                 top: 20,
//                 child: Icon(
//                   Icons.sports_soccer,
//                   color: Colors.white12,
//                   size: 80,
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 3,
//                       ),
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryLight,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: const Text(
//                         'ƯU ĐÃI HÔM NAY',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 9,
//                           fontWeight: FontWeight.w900,
//                           letterSpacing: 0.8,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Giảm 20% sân sáng sớm',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Đặt sân từ 6:00 – 9:00 sáng mỗi ngày',
//                       style: TextStyle(
//                         color: Colors.white.withValues(alpha: 0.75),
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ── FEATURED ROW ──────────────────────────────
class _FeaturedRow extends StatelessWidget {
  final List<FieldModel> fields;
  final bool isLoading;
  final String? errorMsg;
  final ValueChanged<FieldModel> onTap;
  final VoidCallback onRetry;

  const _FeaturedRow({
    required this.fields,
    required this.isLoading,
    required this.errorMsg,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 210,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
          itemCount: 3,
          itemBuilder: (_, _) => const _FeaturedSkeleton(),
        ),
      );
    }

    if (errorMsg != null || fields.isEmpty) {
      return SizedBox(
        height: 210,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textLight,
                size: 36,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
        itemCount: fields.length,
        itemBuilder: (_, i) =>
            _FeaturedCard(field: fields[i], onTap: () => onTap(fields[i])),
      ),
    );
  }
}

// ── FEATURED CARD ─────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onTap;
  const _FeaturedCard({required this.field, required this.onTap});

  // Màu fallback khi không có ảnh — hash theo tên sân
  Color get _placeholderColor {
    const palette = [
      Color(0xFF1B5E20),
      Color(0xFF0D47A1),
      Color(0xFF4A148C),
      Color(0xFF00695C),
      Color(0xFF4E342E),
      Color(0xFF37474F),
    ];
    return palette[field.name.codeUnits.fold(0, (a, b) => a + b) %
        palette.length];
  }

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
            // ── Ảnh ──────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.cardRadius),
                  ),
                  child: SizedBox(
                    height: 112,
                    child: field.imageUrl != null
                        ? Image.network(
                            field.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) =>
                                _FieldColorBlock(color: _placeholderColor),
                          )
                        : _FieldColorBlock(color: _placeholderColor),
                  ),
                ),
                // Rating badge
                if (field.avgRating != null)
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
                            field.avgRating!.toStringAsFixed(1),
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

            // ── Info ──────────────────────────────────
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
                    '${field.basePriceFmt}/giờ',
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

// ── FEATURED SKELETON ─────────────────────────
class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadius),
            ),
            child: Container(height: 112, color: AppColors.fieldBg),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 72,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBg,
                    borderRadius: BorderRadius.circular(4),
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

// ── FIELD LIST CARD (vertical list) ──────────
// Layout tương tự _NearbyCard gốc
class _FieldListCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onTap;
  const _FieldListCard({required this.field, required this.onTap});

  Color get _placeholderColor {
    const palette = [
      Color(0xFF43A047),
      Color(0xFF2E7D32),
      Color(0xFF00695C),
      Color(0xFF1565C0),
      Color(0xFF4A148C),
      Color(0xFF37474F),
    ];
    return palette[field.name.codeUnits.fold(0, (a, b) => a + b) %
        palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            // ── Thumbnail ───────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 88,
                height: 88,
                child: field.imageUrl != null
                    ? Image.network(
                        field.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _FieldColorBlock(color: _placeholderColor),
                      )
                    : _FieldColorBlock(color: _placeholderColor),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên + loại sân
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryUltraLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          field.fieldType,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating
                  if (field.avgRating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppColors.ratingGold,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          field.avgRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (field.totalReviews != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${field.totalReviews})',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 10),

                  // Giá + nút
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${field.basePriceFmt}/giờ',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: onTap,
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
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────
class _FieldColorBlock extends StatelessWidget {
  final Color color;
  const _FieldColorBlock({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    child: const Center(
      child: Icon(Icons.sports_soccer, color: Colors.white24, size: 36),
    ),
  );
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Text(
        'Chưa có sân nào',
        style: TextStyle(color: AppColors.textLight, fontSize: 15),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadH,
        vertical: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMid, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
