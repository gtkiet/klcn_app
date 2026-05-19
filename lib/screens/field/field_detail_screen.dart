// lib/screens/field/field_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/field.dart';
import '../../models/review.dart';
import '../../services/booking_service.dart';
import '../../services/field_service.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── CONSTANTS ──────────────────────────────────────────────────────────────────
const _kDateCount = 7;
const _kDayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

// ──────────────────────────────────────────────────────────────────────────────
//  FIELD DETAIL SCREEN
// ──────────────────────────────────────────────────────────────────────────────
class FieldDetailScreen extends StatefulWidget {
  const FieldDetailScreen({super.key});

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  // ── Field data ──────────────────────────────────────────────────────────────
  FieldModel? _field;
  bool    _isRefreshing = false;
  String? _detailError;

  // ── Schedule ────────────────────────────────────────────────────────────────
  late final List<DateTime> _dates;
  int _selectedDateIdx = 0;

  List<SlotModel> _slots       = [];
  bool    _isLoadingSlots      = false;
  String? _slotError;

  // ── Selection ───────────────────────────────────────────────────────────────
  final Set<int> _selectedSlotIds = {}; // fieldSlotId

  // ── Hold state ──────────────────────────────────────────────────────────────
  bool    _isHolding  = false;  // đang gọi holdSlots API
  String? _holdError;           // lỗi hold nếu có

  // ── Reviews ─────────────────────────────────────────────────────────────────
  FieldReviewSummary? _reviewSummary;
  bool    _isLoadingReviews = false;
  String? _reviewError;

  // ── Derived ─────────────────────────────────────────────────────────────────
  DateTime get _selectedDate => _dates[_selectedDateIdx];

  double get _totalPrice => _slots
      .where((s) => _selectedSlotIds.contains(s.fieldSlotId))
      .fold(0, (sum, s) => sum + s.price);

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(_kDateCount, (i) => today.add(Duration(days: i)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_field == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is FieldModel) {
        _field = extra;
        _refreshDetail();
        _loadSlots();
        _loadReviews();
      }
    }
  }

  // ── API calls ───────────────────────────────────────────────────────────────
  Future<void> _refreshDetail() async {
    if (_field == null) return;
    setState(() {
      _isRefreshing = true;
      _detailError  = null;
    });
    try {
      final fresh = await FieldService.instance.getFieldDetail(_field!.fieldId);
      if (!mounted) return;
      setState(() {
        _field        = fresh;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError  = e.toString();
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    if (_field == null) return;
    setState(() {
      _isLoadingSlots = true;
      _slotError      = null;
      _selectedSlotIds.clear();
      _holdError      = null;   // xoá lỗi hold khi đổi ngày
    });
    try {
      final schedules = await FieldService.instance.getSchedule(
        date:    _selectedDate,
        fieldId: _field!.fieldId,
      );
      if (!mounted) return;
      final match = schedules
          .where((s) => s.fieldId == _field!.fieldId)
          .firstOrNull;
      setState(() {
        _slots          = match?.slots ?? [];
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slotError      = e.toString();
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    if (_field == null) return;
    setState(() {
      _isLoadingReviews = true;
      _reviewError      = null;
    });
    try {
      final summary =
          await ReviewService.instance.getFieldReviews(_field!.fieldId);
      if (!mounted) return;
      setState(() {
        _reviewSummary    = summary;
        _isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewError      = e.toString();
        _isLoadingReviews = false;
      });
    }
  }

  // ── Events ──────────────────────────────────────────────────────────────────
  void _onDateSelect(int idx) {
    if (_selectedDateIdx == idx) return;
    setState(() => _selectedDateIdx = idx);
    _loadSlots();
  }

  void _onSlotTap(SlotModel slot) {
    if (!slot.isAvailable) return;
    // Xoá lỗi hold khi user thay đổi lựa chọn
    setState(() {
      _holdError = null;
      if (_selectedSlotIds.contains(slot.fieldSlotId)) {
        _selectedSlotIds.remove(slot.fieldSlotId);
      } else {
        _selectedSlotIds.add(slot.fieldSlotId);
      }
    });
  }

  // ── Hold → Navigate ─────────────────────────────────────────────────────────
  //
  // Gọi POST /api/bookings/hold ngay tại đây, trước khi sang confirmation.
  // Lý do: slot cần được chiếm ngay khi user "có ý định đặt" để tránh bị
  // người khác cướp trong lúc user đang điền thông tin ở confirmation screen.
  //
  // Nếu hold thất bại (slot vừa bị đặt bởi người khác, hoặc lỗi mạng):
  //   → Hiển thị lỗi inline, reload lại lịch để UI sync.
  //   → KHÔNG navigate sang confirmation.
  //
  // Nếu hold thành công:
  //   → Navigate sang /fields/confirm, truyền field + date + slots.
  //   → BookingConfirmationScreen chỉ cần gọi createBooking + VNPay,
  //     KHÔNG gọi holdSlots nữa.
  Future<void> _onBook() async {
    if (_selectedSlotIds.isEmpty || _isHolding) return;

    final selectedSlots = _slots
        .where((s) => _selectedSlotIds.contains(s.fieldSlotId))
        .toList();
    final slotIds = selectedSlots.map((s) => s.fieldSlotId).toList();

    setState(() {
      _isHolding = true;
      _holdError = null;
    });

    try {
      await BookingService.instance.holdSlots(slotIds);

      if (!mounted) return;

      // Hold thành công → navigate
      context.push('/fields/confirm', extra: {
        'field': _field,
        'date':  _selectedDate,
        'slots': selectedSlots,
      });
    } catch (e) {
      if (!mounted) return;

      // Hold thất bại → có thể slot bị cướp → reload lịch
      await _loadSlots();

      if (!mounted) return;
      setState(() => _holdError = e.toString());
    } finally {
      if (mounted) setState(() => _isHolding = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_field == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final field = _field!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          title: const Text('Chi tiết sân'),
          leading: IconButton(
            icon:     const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_isRefreshing)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          totalPrice: _totalPrice,
          slotCount:  _selectedSlotIds.length,
          enabled:    _selectedSlotIds.isNotEmpty && !_isHolding,
          isLoading:  _isHolding,
          onTap:      _onBook,
        ),
        body: RefreshIndicator(
          color:     AppColors.primary,
          onRefresh: () async {
            await _refreshDetail();
            await _loadSlots();
            await _loadReviews();
          },
          child: ListView(
            children: [
              // ── Hero image ───────────────────────────────────────────────
              _FieldHeroImage(imageUrl: field.imageUrl, name: field.name),

              const SizedBox(height: 16),

              // ── Info card ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadH,
                ),
                child: SpCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              field.name,
                              style: const TextStyle(
                                fontSize:   20,
                                fontWeight: FontWeight.w800,
                                color:      AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TypeBadge(label: field.fieldType),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (field.avgRating != null)
                        _RatingRow(
                          rating:       field.avgRating!,
                          totalReviews: field.totalReviews,
                        ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _PriceItem(
                              label: 'Giờ thường',
                              value: field.basePriceFmt,
                              icon:  Icons.access_time_rounded,
                            ),
                          ),
                          if (field.peakPrice > field.basePrice) ...[
                            Container(
                              width: 1, height: 36,
                              color: AppColors.divider,
                            ),
                            Expanded(
                              child: _PriceItem(
                                label:  'Cao điểm',
                                value:  field.peakPriceFmt,
                                icon:   Icons.bolt_rounded,
                                isPeak: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Mô tả ────────────────────────────────────────────────────
              if (field.description != null &&
                  field.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _SectionTitle('Mô tả'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadH,
                  ),
                  child: SpCard(
                    child: Text(
                      field.description!,
                      style: const TextStyle(
                        color:  AppColors.textMid,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Date picker ──────────────────────────────────────────────
              const _SectionTitle('Chọn ngày'),
              const SizedBox(height: 10),
              _DatePicker(
                dates:       _dates,
                selectedIdx: _selectedDateIdx,
                onSelect:    _onDateSelect,
              ),

              const SizedBox(height: 20),

              // ── Slot grid ────────────────────────────────────────────────
              const _SectionTitle('Chọn giờ'),
              const SizedBox(height: 10),

              if (_isLoadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (_slotError != null)
                _SlotError(onRetry: _loadSlots)
              else if (_slots.isEmpty)
                const _SlotEmpty()
              else
                _SlotGrid(
                  slots:       _slots,
                  selectedIds: _selectedSlotIds,
                  onTap:       _onSlotTap,
                ),

              // ── Legend ───────────────────────────────────────────────────
              if (!_isLoadingSlots &&
                  _slotError == null &&
                  _slots.isNotEmpty)
                const _SlotLegend(),

              // ── Hold error banner ─────────────────────────────────────────
              // Hiển thị khi holdSlots thất bại — slot vừa bị đặt hoặc lỗi mạng.
              // Lịch đã được reload tự động để UI phản ánh trạng thái mới nhất.
              if (_holdError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadH, 14, AppSpacing.pagePadH, 0,
                  ),
                  child: _HoldErrorBanner(message: _holdError!),
                ),

              const SizedBox(height: 20),

              // ── Nhận xét ─────────────────────────────────────────────────
              const _SectionTitle('Nhận xét'),
              const SizedBox(height: 10),

              if (_isLoadingReviews)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (_reviewError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadH,
                  ),
                  child: _ReviewLoadError(onRetry: _loadReviews),
                )
              else if (_reviewSummary == null ||
                  _reviewSummary!.totalReviews == 0)
                const _ReviewEmpty()
              else ...[
                _ReviewSummaryCard(summary: _reviewSummary!),
                const SizedBox(height: 12),
                ..._reviewSummary!.reviews
                    .where((r) => r.isVisible)
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePadH, 0, AppSpacing.pagePadH, 10,
                        ),
                        child: _ReviewCard(review: r),
                      ),
                    ),
              ],

              // ── Detail error banner ──────────────────────────────────────
              if (_detailError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadH, 12, AppSpacing.pagePadH, 0,
                  ),
                  child: _WarningBanner(
                    message:
                        'Không thể tải dữ liệu mới nhất. Kéo để thử lại.',
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DATE PICKER ────────────────────────────────────────────────────────────────
class _DatePicker extends StatelessWidget {
  final List<DateTime>    dates;
  final int               selectedIdx;
  final ValueChanged<int> onSelect;

  const _DatePicker({
    required this.dates,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:     const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
        itemCount:   dates.length,
        itemBuilder: (_, i) {
          final date     = dates[i];
          final selected = i == selectedIdx;
          final isToday  = i == 0;
          final dayLabel = isToday ? 'Hôm nay' : _kDayLabels[date.weekday % 7];

          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width:  62,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color:        selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow:    selected ? AppShadow.card : [],
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.fieldBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color:      selected ? Colors.white70 : AppColors.textLight,
                      fontSize:   10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize:   18,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Th${date.month}',
                    style: TextStyle(
                      color:    selected ? Colors.white60 : AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── SLOT GRID ──────────────────────────────────────────────────────────────────
class _SlotGrid extends StatelessWidget {
  final List<SlotModel>        slots;
  final Set<int>               selectedIds;
  final ValueChanged<SlotModel> onTap;

  const _SlotGrid({
    required this.slots,
    required this.selectedIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
      child: GridView.builder(
        shrinkWrap:       true,
        physics:          const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   3,
          crossAxisSpacing: 8,
          mainAxisSpacing:  8,
          childAspectRatio: 2.2, // rộng hơn cao — vừa với "HH:mm - HH:mm"
        ),
        itemCount: slots.length,
        itemBuilder: (_, i) {
          final slot       = slots[i];
          final isSelected = selectedIds.contains(slot.fieldSlotId);
          return GestureDetector(
            onTap: () => onTap(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : slot.isAvailable
                        ? Colors.white
                        : AppColors.fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : slot.isPeakHour && slot.isAvailable
                          ? AppColors.warningOrange.withValues(alpha: 0.5)
                          : AppColors.fieldBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot.displayTime,
                    style: TextStyle(
                      fontSize:   12.5,
                      fontWeight: FontWeight.w700,
                      color: slot.isAvailable
                          ? isSelected
                              ? Colors.white
                              : AppColors.textDark
                          : AppColors.textHint,
                      decoration: slot.isBooked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (slot.isPeakHour &&
                          slot.isAvailable &&
                          !isSelected)
                        const Icon(
                          Icons.bolt_rounded,
                          size:  10,
                          color: AppColors.warningOrange,
                        ),
                      Text(
                        slot.isAvailable
                            ? slot.priceFmt
                            : _statusLabel(slot),
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white70
                              : slot.isAvailable
                                  ? slot.isPeakHour
                                      ? AppColors.warningOrange
                                      : AppColors.primary
                                  : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(SlotModel slot) {
    if (slot.isHolding) return 'Đang giữ';
    if (slot.isBooked)  return 'Đã đặt';
    return slot.status;
  }
}

// ── SLOT LEGEND ────────────────────────────────────────────────────────────────
class _SlotLegend extends StatelessWidget {
  const _SlotLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadH, 12, AppSpacing.pagePadH, 0,
      ),
      child: const Wrap(
        spacing:    16,
        runSpacing: 6,
        children: [
          _LegendDot(color: AppColors.primary,  label: 'Đã chọn'),
          _LegendDot(color: Colors.white,        label: 'Còn trống', border: true),
          _LegendDot(color: AppColors.fieldBg,  label: 'Không trống', border: true),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  final bool   border;
  const _LegendDot({
    required this.color,
    required this.label,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  12,
          height: 12,
          decoration: BoxDecoration(
            color:        color,
            borderRadius: BorderRadius.circular(3),
            border: border ? Border.all(color: AppColors.fieldBorder) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
        ),
      ],
    );
  }
}

// ── SLOT STATES ────────────────────────────────────────────────────────────────
class _SlotEmpty extends StatelessWidget {
  const _SlotEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          'Không có slot nào trong ngày này',
          style: TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
      ),
    );
  }
}

class _SlotError extends StatelessWidget {
  final VoidCallback onRetry;
  const _SlotError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20, horizontal: AppSpacing.pagePadH,
      ),
      child: Column(
        children: [
          const Text(
            'Không tải được lịch sân',
            style: TextStyle(color: AppColors.textMid, fontSize: 14),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Thử lại',
              style: TextStyle(
                color:      AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize:   14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HOLD ERROR BANNER ──────────────────────────────────────────────────────────
// Hiển thị khi POST /api/bookings/hold thất bại.
// Lịch slot được reload tự động — banner giải thích lý do để user chọn lại.
class _HoldErrorBanner extends StatelessWidget {
  final String message;
  const _HoldErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorRed,
            size:  18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Không thể giữ slot',
                  style: TextStyle(
                    color:      AppColors.errorRed,
                    fontWeight: FontWeight.w700,
                    fontSize:   13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color:    AppColors.errorRed,
                    fontSize: 12.5,
                    height:   1.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lịch đã được cập nhật. Vui lòng chọn lại slot.',
                  style: TextStyle(
                    color:    AppColors.textMid,
                    fontSize: 12,
                    height:   1.4,
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

// ── BOTTOM BAR ─────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final double       totalPrice;
  final int          slotCount;
  final bool         enabled;
  final bool         isLoading;  // đang gọi holdSlots
  final VoidCallback onTap;

  const _BottomBar({
    required this.totalPrice,
    required this.slotCount,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  String _fmt(double p) {
    if (p == 0)       return '--';
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M';
    return '${(p / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset:     const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Column(
                mainAxisSize:     MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slotCount > 0 ? 'TỔNG ($slotCount slot)' : 'TỔNG',
                    style: const TextStyle(
                      fontSize:   10,
                      color:      AppColors.textLight,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(totalPrice),
                    style: const TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.w900,
                      color:      AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.45,
                  child: GestureDetector(
                    onTap: enabled ? onTap : null,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color:        AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:    enabled ? AppShadow.btn : [],
                      ),
                      child: isLoading
                          // Spinner khi đang gọi holdSlots
                          ? const Center(
                              child: SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ĐẶT SÂN NGAY',
                                  style: TextStyle(
                                    color:         Colors.white,
                                    fontSize:      15,
                                    fontWeight:    FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── HERO IMAGE ─────────────────────────────────────────────────────────────────
class _FieldHeroImage extends StatelessWidget {
  final String? imageUrl;
  final String  name;
  const _FieldHeroImage({required this.imageUrl, required this.name});

  Color get _color {
    const palette = [
      Color(0xFF1B5E20), Color(0xFF0D47A1), Color(0xFF4A148C),
      Color(0xFF00695C), Color(0xFF4E342E), Color(0xFF37474F),
    ];
    return palette[name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit:          BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder,
            )
          : _placeholder,
    );
  }

  Widget get _placeholder => Container(
        color: _color,
        child: const Center(
          child: Icon(
            Icons.sports_soccer,
            color: Colors.white12,
            size:  80,
          ),
        ),
      );
}

// ── PRICE ITEM ─────────────────────────────────────────────────────────────────
class _PriceItem extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final bool     isPeak;

  const _PriceItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isPeak = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPeak ? AppColors.warningOrange : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            '$value/giờ',
            style: TextStyle(
              color:      color,
              fontWeight: FontWeight.w800,
              fontSize:   16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color:    AppColors.textLight,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── REVIEW SUMMARY CARD ────────────────────────────────────────────────────────
class _ReviewSummaryCard extends StatelessWidget {
  final FieldReviewSummary summary;
  const _ReviewSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
      child: SpCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Điểm trung bình
            Column(
              children: [
                Text(
                  summary.avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize:   40,
                    fontWeight: FontWeight.w900,
                    color:      AppColors.textDark,
                    height:     1,
                  ),
                ),
                const SizedBox(height: 4),
                _StarRow(rating: summary.avgRating.round(), size: 14),
                const SizedBox(height: 4),
                Text(
                  '${summary.totalReviews} đánh giá',
                  style: const TextStyle(
                    color:    AppColors.textLight,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Container(width: 1, height: 80, color: AppColors.divider),
            const SizedBox(width: 16),
            // Star bars
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textMid,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size:  12,
                          color: AppColors.ratingGold,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:           summary.starRatio(star),
                              minHeight:       6,
                              backgroundColor: AppColors.fieldBg,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.ratingGold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── REVIEW CARD ────────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + tên + ngày
          Row(
            children: [
              _Avatar(url: review.avatarUrl, name: review.userName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                        color:      AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        color:    AppColors.textLight,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              _StarRow(rating: review.rating, size: 13),
            ],
          ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: const TextStyle(
                color:    AppColors.textMid,
                fontSize: 13.5,
                height:   1.5,
              ),
            ),
          ],

          // Ảnh review
          if (review.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                review.imageUrl!,
                height:       160,
                width:        double.infinity,
                fit:          BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

// ── REVIEW STATES ──────────────────────────────────────────────────────────────
class _ReviewEmpty extends StatelessWidget {
  const _ReviewEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 20, horizontal: AppSpacing.pagePadH,
        ),
        child: Center(
          child: Text(
            'Chưa có nhận xét nào',
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
        ),
      );
}

class _ReviewLoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ReviewLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text(
              'Không tải được nhận xét',
              style: TextStyle(color: AppColors.textMid, fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color:      AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize:   14,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── SMALL WIDGETS ──────────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        AppColors.primaryUltraLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color:      AppColors.primary,
            fontSize:   12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int?   totalReviews;
  const _RatingRow({required this.rating, this.totalReviews});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(
            Icons.star_rounded,
            size:  16,
            color: AppColors.ratingGold,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (totalReviews != null) ...[
            const SizedBox(width: 4),
            Text(
              '($totalReviews đánh giá)',
              style: const TextStyle(
                color:    AppColors.textLight,
                fontSize: 13,
              ),
            ),
          ],
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize:   16,
            color:      AppColors.textDark,
          ),
        ),
      );
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.warningOrange.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warningOrange,
              size:  18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color:    AppColors.warningOrange,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String  name;
  const _Avatar({required this.url, required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return parts.last[0].toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius:          20,
      backgroundColor: AppColors.primaryUltraLight,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      onBackgroundImageError: url != null ? (_, _) {} : null,
      child: url == null
          ? Text(
              _initials,
              style: const TextStyle(
                color:      AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize:   14,
              ),
            )
          : null,
    );
  }
}

class _StarRow extends StatelessWidget {
  final int    rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size:  size,
          color: AppColors.ratingGold,
        ),
      ),
    );
  }
}