// lib/screens/field/field_list_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── MOCK DATA ─────────────────────────────────
class _Stadium {
  final String name;
  final String address;
  final double rating;
  final String price;
  final Color placeholderColor;

  const _Stadium({
    required this.name,
    required this.address,
    required this.rating,
    required this.price,
    required this.placeholderColor,
  });
}

const _filterChips = ['Gần đây', 'Giá rẻ', '5 sao', 'Sân cỏ nhân tạo', 'Sân trong nhà'];

final _stadiumList = const [
  _Stadium(name: 'Arena Santiago',       address: 'Quận Phú Nhuận, TP. HCM', rating: 4.8, price: '450.000đ', placeholderColor: Color(0xFF1B5E20)),
  _Stadium(name: 'Sporting Central',     address: 'Quận 7, TP. HCM',         rating: 4.9, price: '550.000đ', placeholderColor: Color(0xFF0D47A1)),
  _Stadium(name: 'Victory Garden Park',  address: 'Quận 2, TP. HCM',         rating: 4.5, price: '380.000đ', placeholderColor: Color(0xFF33691E)),
  _Stadium(name: 'Sunrise Football Arena',address: 'Quận Bình Thạnh, TP. HCM',rating: 4.3, price: '320.000đ', placeholderColor: Color(0xFF4E342E)),
  _Stadium(name: 'Phú Nhuận Stadium',    address: 'Quận Phú Nhuận, TP. HCM', rating: 4.7, price: '420.000đ', placeholderColor: Color(0xFF00695C)),
];

// ─────────────────────────────────────────────
//  FIELD LIST SCREEN
// ─────────────────────────────────────────────
class FieldListScreen extends StatefulWidget {
  const FieldListScreen({super.key});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  int _selectedChip = 0;
  // int _currentTab   = 1;
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  List<_Stadium> get _filtered {
    final q = _query.toLowerCase();
    var list = q.isEmpty
        ? List<_Stadium>.from(_stadiumList)
        : _stadiumList
            .where((e) =>
                e.name.toLowerCase().contains(q) ||
                e.address.toLowerCase().contains(q))
            .toList();

    switch (_selectedChip) {
      case 1:
        list.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
        break;
      case 2:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return list;
  }

  int _parsePrice(String p) =>
      int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350),
        () => setState(() => _query = value));
  }

  // void _onTabTap(int index) {
  //   setState(() => _currentTab = index);
  //   switch (index) {
  //     case 0: Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false); break;
  //     case 2: Navigator.pushReplacementNamed(context, '/booking_history'); break;
  //     case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
  //   }
  // }

  Future<void> _onRefresh() async =>
      await Future.delayed(const Duration(milliseconds: 800));

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
          title: const Text('Danh sách sân'),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => Navigator.pushNamed(context, '/filter'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Sticky header: search + chips
            _StickyHeader(
              controller: _searchController,
              selectedChip: _selectedChip,
              onChipSelect: (i) => setState(() => _selectedChip = i),
              onSearchChanged: _onSearchChanged,
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _onRefresh,
                child: _filtered.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePadH, 16, AppSpacing.pagePadH, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => _StadiumCard(
                          stadium: _filtered[i],
                          onTap: () => Navigator.pushNamed(context, '/field_detail'),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STICKY HEADER ─────────────────────────────
class _StickyHeader extends StatelessWidget {
  final TextEditingController controller;
  final int selectedChip;
  final ValueChanged<int> onChipSelect;
  final ValueChanged<String> onSearchChanged;

  const _StickyHeader({
    required this.controller,
    required this.selectedChip,
    required this.onChipSelect,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPage,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadH),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadow.card,
              ),
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Tìm sân theo tên, quận...',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: AppSpacing.pagePadH),
              itemCount: _filterChips.length,
              itemBuilder: (_, i) {
                final selected = selectedChip == i;
                return GestureDetector(
                  onTap: () => onChipSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.fieldBorder,
                      ),
                    ),
                    child: Text(
                      _filterChips[i],
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── STADIUM CARD ──────────────────────────────
class _StadiumCard extends StatelessWidget {
  final _Stadium stadium;
  final VoidCallback onTap;

  const _StadiumCard({required this.stadium, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SpCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Placeholder image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.cardRadius),
              ),
              child: Container(
                height: 180,
                color: stadium.placeholderColor,
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.sports_soccer, color: Colors.white12, size: 60),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.ratingGold),
                            const SizedBox(width: 3),
                            Text(
                              stadium.rating.toString(),
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
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stadium.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text(
                        stadium.address,
                        style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stadium.price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Đặt ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
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

// ── EMPTY STATE ───────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy sân phù hợp',
            style: TextStyle(color: AppColors.textLight, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
