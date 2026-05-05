// lib/screens/field_list_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// TODO: Thay bằng go_router khi tích hợp navigation thật
// TODO: Import StadiumService, FilterService khi kết nối backend

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  static const appBarGreen = Color(0xFF1B6B38);
  static const bgPage = Color(0xFFF2F5F0);
  static const cardBg = Colors.white;
  static const searchBg = Colors.white;
  static const chipActive = Color(0xFF2E7D32);
  static const chipActiveTxt = Colors.white;
  static const chipInactiveBg = Colors.white;
  static const chipInactiveTxt = Color(0xFF444444);
  static const navUnselected = Color(0xFF9E9E9E);
}

abstract class _S {
  static const double pagePadH = 16.0;
  static const double cardRadius = 16.0;
  static const double chipRadius = 50.0;
  static const double imageH = 185.0;
}

// ─────────────────────────────────────────────
//  MOCK DATA
// ─────────────────────────────────────────────
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

const _filterChips = [
  'Gần đây',
  'Giá rẻ',
  '5 sao',
  'Sân cỏ nhân tạo',
  'Sân trong nhà',
];

final _stadiumList = const [
  _Stadium(
    name: 'Arena Santiago',
    address: 'Quận Phú Nhuận, TP. HCM',
    rating: 4.8,
    price: '450.000đ',
    placeholderColor: Color(0xFF1B5E20),
  ),
  _Stadium(
    name: 'Sporting Central',
    address: 'Quận 7, TP. HCM',
    rating: 4.9,
    price: '550.000đ',
    placeholderColor: Color(0xFF0D47A1),
  ),
  _Stadium(
    name: 'Victory Garden Park',
    address: 'Quận 2, TP. HCM',
    rating: 4.5,
    price: '380.000đ',
    placeholderColor: Color(0xFF33691E),
  ),
  _Stadium(
    name: 'Sunrise Football Arena',
    address: 'Quận Bình Thạnh, TP. HCM',
    rating: 4.3,
    price: '320.000đ',
    placeholderColor: Color(0xFF4E342E),
  ),
  _Stadium(
    name: 'Phú Nhuận Stadium',
    address: 'Quận Phú Nhuận, TP. HCM',
    rating: 4.7,
    price: '420.000đ',
    placeholderColor: Color(0xFF00695C),
  ),
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
  int _currentTab = 1;
  final _searchController = TextEditingController();

  Timer? _debounce;
  String _query = '';

  List<_Stadium> get _filtered {
    final list = _stadiumList;

    final q = _query.toLowerCase();
    final searched = q.isEmpty
        ? list
        : list.where((e) {
            return e.name.toLowerCase().contains(q) ||
                e.address.toLowerCase().contains(q);
          }).toList();

    switch (_selectedChip) {
      case 1:
        searched.sort(
          (a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)),
        );
        break;
      case 2:
        searched.sort((b, a) => a.rating.compareTo(b.rating));
        break;
    }

    return searched;
  }

  int _parsePrice(String p) {
    return int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _query = value);
    });
  }

  void _onTabTap(int index) {
    setState(() => _currentTab = index);
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/booking_history');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _onChipSelect(int i) {
    setState(() => _selectedChip = i);
  }

  void _onFilterTap() {
    Navigator.pushNamed(context, '/filter');
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bgPage,
        appBar: _FieldListAppBar(onFilterTap: _onFilterTap),
        body: Column(
          children: [
            _StickyHeader(
              controller: _searchController,
              selectedChip: _selectedChip,
              onChipSelect: _onChipSelect,
              onSearchChanged: _onSearchChanged,
            ),
            Expanded(
              child: RefreshIndicator(
                color: _C.primary,
                onRefresh: _onRefresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    _S.pagePadH,
                    16,
                    _S.pagePadH,
                    24,
                  ),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) => _StadiumCard(
                    stadium: _filtered[i],
                    onCardTap: () =>
                        Navigator.pushNamed(context, '/field_detail'),
                    onBookTap: () =>
                        Navigator.pushNamed(context, '/field_detail'),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentTab,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────
class _FieldListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onFilterTap;
  const _FieldListAppBar({required this.onFilterTap});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bgPage,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _C.appBarGreen),
        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
      ),
      centerTitle: true,
      title: const Text(
        'Danh sách sân',
        style: TextStyle(color: _C.appBarGreen, fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          onPressed: onFilterTap,
          icon: const Icon(Icons.tune_rounded, color: _C.appBarGreen),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  STICKY HEADER
// ─────────────────────────────────────────────
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
      color: _C.bgPage,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(_S.pagePadH),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm sân...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: _C.searchBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterChips.length,
              itemBuilder: (context, i) {
                final selected = selectedChip == i;
                return GestureDetector(
                  onTap: () => onChipSelect(i),
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _C.chipActive : _C.chipInactiveBg,
                      borderRadius: BorderRadius.circular(_S.chipRadius),
                    ),
                    child: Text(
                      _filterChips[i],
                      style: TextStyle(
                        color: selected ? _C.chipActiveTxt : _C.chipInactiveTxt,
                        fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────
//  STADIUM CARD
// ─────────────────────────────────────────────
class _StadiumCard extends StatelessWidget {
  final _Stadium stadium;
  final VoidCallback onCardTap;
  final VoidCallback onBookTap;

  const _StadiumCard({
    required this.stadium,
    required this.onCardTap,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(_S.cardRadius),
        ),
        child: Column(
          children: [
            Container(height: _S.imageH, color: stadium.placeholderColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    stadium.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stadium.address,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stadium.price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _C.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Chỉnh button 'Đặt ngay' giống Home Screen
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _C.primary,
                      borderRadius: BorderRadius.circular(_S.cardRadius),
                    ),
                    child: TextButton(
                      onPressed: onBookTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Đặt ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
