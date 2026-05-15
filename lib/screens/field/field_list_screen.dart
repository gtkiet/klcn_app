// lib/screens/field/field_list_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/field.dart';
import '../../services/field_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── CONSTANTS ─────────────────────────────────
const _kPageSize = 10;

const _filterChips = [
  _ChipOption(label: 'Tất cả',  typeId: null),
  _ChipOption(label: 'Sân 5',   typeId: 1),
  _ChipOption(label: 'Sân 7',   typeId: 2),
];

class _ChipOption {
  final String label;
  final int? typeId;
  const _ChipOption({required this.label, required this.typeId});
}

// ─────────────────────────────────────────────
//  FIELD LIST SCREEN
// ─────────────────────────────────────────────
class FieldListScreen extends StatefulWidget {
  const FieldListScreen({super.key});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  // ── State ──────────────────────────────────
  final _searchCtrl   = TextEditingController();
  final _scrollCtrl   = ScrollController();
  Timer? _debounce;

  int  _selectedChip  = 0;
  String _query       = '';

  List<FieldModel> _fields    = [];
  bool _isLoading             = false;
  bool _isLoadingMore         = false;
  bool _hasNextPage           = false;
  int  _currentPage           = 1;
  String? _errorMsg;

  // ── Lifecycle ──────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadFields(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── API ────────────────────────────────────
  Future<void> _loadFields({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading  = true;
        _errorMsg   = null;
        _currentPage = 1;
        _fields     = [];
      });
    } else {
      if (_isLoadingMore || !_hasNextPage) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final page = reset ? 1 : _currentPage;
      final result = await FieldService.instance.getFields(
        search:   _query.isEmpty ? null : _query,
        typeId:   _filterChips[_selectedChip].typeId,
        statusId: 1, // chỉ hiển thị sân đang hoạt động
        page:     page,
        pageSize: _kPageSize,
      );

      if (!mounted) return;
      setState(() {
        if (reset) {
          _fields = result.items;
        } else {
          _fields.addAll(result.items);
        }
        _hasNextPage  = result.hasNextPage;
        _currentPage  = result.page + 1;
        _isLoading    = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg      = e.toString();
        _isLoading     = false;
        _isLoadingMore = false;
      });
    }
  }

  // ── Events ─────────────────────────────────
  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadFields();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () {
        _query = value.trim();
        _loadFields(reset: true);
      },
    );
  }

  void _onChipSelect(int index) {
    if (_selectedChip == index) return;
    setState(() => _selectedChip = index);
    _loadFields(reset: true);
  }

  void _onTapField(FieldModel field) {
    context.push('/fields/detail', extra: field);
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          title: const Text('Sân bóng'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Column(
          children: [
            _StickyHeader(
              controller:       _searchCtrl,
              selectedChip:     _selectedChip,
              onChipSelect:     _onChipSelect,
              onSearchChanged:  _onSearchChanged,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMsg != null && _fields.isEmpty) {
      return _ErrorState(
        message: _errorMsg!,
        onRetry: () => _loadFields(reset: true),
      );
    }

    if (_fields.isEmpty) {
      return _EmptyState(query: _query);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadFields(reset: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadH, 16, AppSpacing.pagePadH, 24,
        ),
        itemCount: _fields.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _fields.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FieldCard(
              field: _fields[i],
              onTap: () => _onTapField(_fields[i]),
            ),
          );
        },
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadH, 12, AppSpacing.pagePadH, 8,
            ),
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
                  hintText: 'Tìm sân theo tên...',
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color:  selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.fieldBorder,
                      ),
                    ),
                    child: Text(
                      _filterChips[i].label,
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── FIELD CARD ────────────────────────────────
class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onTap;

  const _FieldCard({required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SpCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.cardRadius),
              ),
              child: SizedBox(
                height: 175,
                child: field.imageUrl != null
                    ? Image.network(
                        field.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _FieldPlaceholder(name: field.name),
                      )
                    : _FieldPlaceholder(name: field.name),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryUltraLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          field.fieldType,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Rating + reviews
                  if (field.avgRating != null)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.ratingGold),
                        const SizedBox(width: 3),
                        Text(
                          field.avgRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13,
                          ),
                        ),
                        if (field.totalReviews != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${field.totalReviews} đánh giá)',
                            style: const TextStyle(
                              color: AppColors.textLight, fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 10),

                  // Giá + nút đặt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${field.basePriceFmt}/giờ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: 15,
                            ),
                          ),
                          if (field.peakPrice > field.basePrice)
                            Text(
                              'Cao điểm: ${field.peakPriceFmt}',
                              style: const TextStyle(
                                color: AppColors.textLight, fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
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

// ── FIELD PLACEHOLDER IMAGE ───────────────────
class _FieldPlaceholder extends StatelessWidget {
  final String name;
  const _FieldPlaceholder({required this.name});

  // Hash màu từ tên sân để mỗi sân có màu riêng nhất quán
  Color get _color {
    const palette = [
      Color(0xFF1B5E20), Color(0xFF0D47A1), Color(0xFF4A148C),
      Color(0xFF00695C), Color(0xFF4E342E), Color(0xFF37474F),
    ];
    return palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _color,
      child: const Center(
        child: Icon(Icons.sports_soccer, color: Colors.white12, size: 60),
      ),
    );
  }
}

// ── EMPTY STATE ───────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'Không có sân nào' : 'Không tìm thấy "$query"',
            style: const TextStyle(color: AppColors.textLight, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ── ERROR STATE ───────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMid, fontSize: 14),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14,
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