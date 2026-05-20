// lib/screens/booking/booking_confirmation_screen.dart
//
// extra: { 'field': FieldModel, 'date': DateTime, 'slots': List<SlotModel> }
//
// FLOW:
//   1. Hiển thị thông tin sân + slot đã chọn
//   2. Chọn dịch vụ đi kèm (optional)
//   3. Nhập mã giảm giá (optional)
//   4. Tick "Thanh toán toàn bộ" nếu muốn trả full 1 lần qua VNPay
//      (mặc định = false → chỉ cọc qua VNPay, phần còn lại trả tại sân)
//   5. Bấm XÁC NHẬN:
//        holdSlots → createBooking(isFullPayment) → createVnPayPayment
//        → launchUrl VNPay → deep link xử lý kết quả cuối

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/field.dart';
import '../../models/service.dart';
import '../../models/promotion.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── UTILS ──────────────────────────────────────────────────────────────────────
String _fmtMoney(double amount) {
  if (amount == 0) return '0đ';
  final s = amount.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '$bufđ';
}

// ──────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ──────────────────────────────────────────────────────────────────────────────
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  // ── Input từ extra ──────────────────────────────────────────────────────────
  late FieldModel _field;
  late DateTime _date;
  late List<SlotModel> _slots;
  bool _extraLoaded = false;

  // ── Services ────────────────────────────────────────────────────────────────
  List<ServiceModel> _services = [];
  bool _isLoadingServices = false;

  // ── Selection ───────────────────────────────────────────────────────────────
  final Map<int, int> _serviceQty = {}; // serviceId → quantity

  // ── Payment mode ────────────────────────────────────────────────────────────
  // false = chỉ cọc qua VNPay, còn lại trả tại sân (Flow 1 — mặc định)
  // true  = trả toàn bộ ngay qua VNPay                (Flow 2)
  bool _isFullPayment = false;

  // ── Voucher ─────────────────────────────────────────────────────────────────
  final _voucherCtrl = TextEditingController();
  PromotionModel? _promotion;
  bool _isCheckingVoucher = false;
  String? _voucherError;

  // ── Booking ─────────────────────────────────────────────────────────────────
  bool _isProcessing = false;
  String? _bookingError;

  // ── Derived ─────────────────────────────────────────────────────────────────
  double get _slotTotal => _slots.fold(0.0, (s, slot) => s + slot.price);

  double get _serviceTotal => _services.fold(0.0, (s, svc) {
    final qty = _serviceQty[svc.serviceId] ?? 0;
    return s + svc.price * qty;
  });

  double get _subTotal => _slotTotal + _serviceTotal;
  double get _discount => _promotion?.calcDiscount(_subTotal) ?? 0;
  double get _total => (_subTotal - _discount).clamp(0, double.infinity);

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_extraLoaded) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (extra != null) {
        _field = extra['field'] as FieldModel;
        _date = extra['date'] as DateTime;
        _slots = List<SlotModel>.from(extra['slots'] as List);
        _extraLoaded = true;
        _loadServices();
      }
    }
  }

  @override
  void dispose() {
    _voucherCtrl.dispose();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────────────────
  Future<void> _loadServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final list = await BookingService.instance.getServices(isAvailable: true);
      if (!mounted) return;
      setState(() {
        _services = list;
        _isLoadingServices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _checkVoucher() async {
    final code = _voucherCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isCheckingVoucher = true;
      _voucherError = null;
      _promotion = null;
    });
    try {
      final promo = await BookingService.instance.getPromotion(code);
      if (!mounted) return;
      setState(() {
        _promotion = promo;
        _isCheckingVoucher = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voucherError = e.toString();
        _isCheckingVoucher = false;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _isProcessing = true;
      _bookingError = null;
    });

    try {
      final slotIds = _slots.map((s) => s.fieldSlotId).toList();

      // 1. Build service items (chỉ những item có qty > 0)
      final serviceItems = _services
          .where((s) => (_serviceQty[s.serviceId] ?? 0) > 0)
          .map(
            (s) => ServiceRequestItem(
              serviceId: s.serviceId,
              quantity: _serviceQty[s.serviceId]!,
            ),
          )
          .toList();

      // 2. Tạo booking
      final booking = await BookingService.instance.createBooking(
        fieldSlotIds: slotIds,
        services: serviceItems,
        promotionCode: _promotion?.code,
        isFullPayment: _isFullPayment,
      );

      if (!mounted) return;

      final paymentUrl = await PaymentService.instance.createVnPayPayment(
        booking.bookingId,
      );

      if (!mounted) return;

      // 4. Mở VNPay
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        context.go('/booking_history');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bookingError = e.toString();
        _isProcessing = false;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_extraLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          title: const Text('Xác nhận đặt sân'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        bottomNavigationBar: _CtaBar(
          total: _fmtMoney(_total),
          isLoading: _isProcessing,
          onConfirm: _confirm,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadH,
            16,
            AppSpacing.pagePadH,
            24,
          ),
          children: [
            // ── Hero sân ────────────────────────────────────────────────────
            _FieldHeroCard(field: _field),
            const SizedBox(height: 14),

            // ── Chi tiết slot ───────────────────────────────────────────────
            _SlotDetailCard(slots: _slots, date: _date),
            const SizedBox(height: 20),

            // ── Dịch vụ đi kèm ─────────────────────────────────────────────
            const _SectionLabel('Dịch vụ đi kèm'),
            const SizedBox(height: 10),
            if (_isLoadingServices)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_services.isEmpty)
              const _EmptyServices()
            else
              ..._services.map(
                (svc) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceTile(
                    service: svc,
                    quantity: _serviceQty[svc.serviceId] ?? 0,
                    onChanged: (qty) =>
                        setState(() => _serviceQty[svc.serviceId] = qty),
                  ),
                ),
              ),

            // ── Mã giảm giá ─────────────────────────────────────────────────
            const SizedBox(height: 6),
            const _SectionLabel('Mã giảm giá'),
            const SizedBox(height: 10),
            _VoucherRow(
              controller: _voucherCtrl,
              isLoading: _isCheckingVoucher,
              promotion: _promotion,
              error: _voucherError,
              onApply: _checkVoucher,
              onRemove: () => setState(() {
                _promotion = null;
                _voucherError = null;
                _voucherCtrl.clear();
              }),
            ),

            // ── Tổng tiền ───────────────────────────────────────────────────
            const SizedBox(height: 20),
            _PriceSummaryCard(
              slotTotal: _slotTotal,
              serviceTotal: _serviceTotal,
              discount: _discount,
              total: _total,
              promotion: _promotion,
            ),

            // ── Tùy chọn thanh toán ─────────────────────────────────────────
            const SizedBox(height: 20),
            const _SectionLabel('Tùy chọn thanh toán'),
            const SizedBox(height: 10),
            _FullPaymentToggle(
              value: _isFullPayment,
              onChanged: (v) => setState(() => _isFullPayment = v),
            ),
            const SizedBox(height: 12),
            _PaymentNote(isFullPayment: _isFullPayment),

            // ── Error banner ────────────────────────────────────────────────
            if (_bookingError != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _bookingError!),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── FIELD HERO CARD ────────────────────────────────────────────────────────────
class _FieldHeroCard extends StatelessWidget {
  final FieldModel field;
  const _FieldHeroCard({required this.field});

  Color get _placeholderColor {
    const palette = [
      Color(0xFF1B5E20),
      Color(0xFF0D47A1),
      Color(0xFF4A148C),
      Color(0xFF00695C),
      Color(0xFF4E342E),
    ];
    return palette[field.name.codeUnits.fold(0, (a, b) => a + b) %
        palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: SizedBox(
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            field.imageUrl != null
                ? Image.network(
                    field.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _Placeholder(color: _placeholderColor),
                  )
                : _Placeholder(color: _placeholderColor),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Tên sân + loại
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      field.fieldType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    field.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
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

class _Placeholder extends StatelessWidget {
  final Color color;
  const _Placeholder({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    child: const Center(
      child: Icon(Icons.sports_soccer, color: Colors.white12, size: 64),
    ),
  );
}

// ── SLOT DETAIL CARD ───────────────────────────────────────────────────────────
class _SlotDetailCard extends StatelessWidget {
  final List<SlotModel> slots;
  final DateTime date;
  const _SlotDetailCard({required this.slots, required this.date});

  String get _dateStr =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  String get _timeRange {
    if (slots.isEmpty) return '--';
    if (slots.length == 1) return slots.first.displayTime;
    return '${slots.first.startTime} - ${slots.last.endTime}';
  }

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT ĐẶT SÂN',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailCell(
                  icon: Icons.calendar_today_outlined,
                  label: 'NGÀY',
                  value: _dateStr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetailCell(
                  icon: Icons.access_time_rounded,
                  label: slots.length > 1
                      ? 'KHUNG GIỜ (${slots.length} slot)'
                      : 'KHUNG GIỜ',
                  value: _timeRange,
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          if (slots.length > 1) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: slots
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryUltraLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${s.displayTime}  ${s.isPeakHour ? '⚡ ' : ''}${s.priceFmt}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailCell({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── SERVICE TILE ───────────────────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _ServiceTile({
    required this.service,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.fieldBorder,
          width: selected ? 1.8 : 1,
        ),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sports_soccer_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty)
                  Text(
                    service.description!,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12.5,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            service.priceFmt,
            style: const TextStyle(
              color: AppColors.textMid,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepBtn(
                icon: Icons.remove,
                onTap: quantity > 0 ? () => onChanged(quantity - 1) : null,
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _StepBtn(icon: Icons.add, onTap: () => onChanged(quantity + 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : AppColors.textHint,
          size: 16,
        ),
      ),
    );
  }
}

class _EmptyServices extends StatelessWidget {
  const _EmptyServices();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadow.card,
      ),
      child: const Center(
        child: Text(
          'Không có dịch vụ nào',
          style: TextStyle(color: AppColors.textLight, fontSize: 13.5),
        ),
      ),
    );
  }
}

// ── VOUCHER ROW ────────────────────────────────────────────────────────────────
class _VoucherRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final PromotionModel? promotion;
  final String? error;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _VoucherRow({
    required this.controller,
    required this.isLoading,
    required this.promotion,
    required this.error,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (promotion != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryUltraLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion!.code,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Giảm ${promotion!.discountLabel}',
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                color: AppColors.textLight,
                size: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: error != null
                        ? AppColors.errorRed
                        : AppColors.fieldBorder,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isLoading ? null : onApply,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Áp dụng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.errorRed, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}

// ── PRICE SUMMARY CARD ─────────────────────────────────────────────────────────
class _PriceSummaryCard extends StatelessWidget {
  final double slotTotal;
  final double serviceTotal;
  final double discount;
  final double total;
  final PromotionModel? promotion;

  const _PriceSummaryCard({
    required this.slotTotal,
    required this.serviceTotal,
    required this.discount,
    required this.total,
    this.promotion,
  });

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        children: [
          _PriceRow('Tiền sân', _fmtMoney(slotTotal)),
          if (serviceTotal > 0) ...[
            const SizedBox(height: 6),
            _PriceRow('Dịch vụ', _fmtMoney(serviceTotal)),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _PriceRow(
              'Giảm giá${promotion != null ? ' (${promotion!.code})' : ''}',
              '-${_fmtMoney(discount)}',
              valueColor: AppColors.badgeCancelText,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.fieldBorder),
          ),
          _PriceRow('Tổng cộng', _fmtMoney(total), isTotal: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;
  const _PriceRow(
    this.label,
    this.value, {
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.textDark : AppColors.textMid,
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                (isTotal ? AppColors.primary : AppColors.textDark),
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── FULL PAYMENT TOGGLE ────────────────────────────────────────────────────────
// Toggle đơn giản thay cho _RemainderMethodCard 2 lựa chọn cũ
class _FullPaymentToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FullPaymentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryUltraLight : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: value
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.fieldBorder,
            width: value ? 1.8 : 1,
          ),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.fieldBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: value ? Colors.white : AppColors.textHint,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thanh toán toàn bộ qua VNPay',
                    style: TextStyle(
                      color: value ? AppColors.textDark : AppColors.textMid,
                      fontSize: 14.5,
                      fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value
                        ? 'Thanh toán 100% ngay bây giờ — không cần trả thêm'
                        : 'Tắt: chỉ cọc qua VNPay, còn lại trả tại sân',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PAYMENT NOTE ───────────────────────────────────────────────────────────────
// Hiển thị ghi chú khác nhau tùy flow được chọn
class _PaymentNote extends StatelessWidget {
  final bool isFullPayment;
  const _PaymentNote({required this.isFullPayment});

  @override
  Widget build(BuildContext context) {
    final text = isFullPayment
        ? 'Bạn sẽ thanh toán toàn bộ ${''} qua VNPay ngay sau khi xác nhận. '
              'Slot được xác nhận ngay khi thanh toán thành công.'
        : 'Bạn sẽ cọc qua VNPay ngay sau khi xác nhận. '
              'Phần còn lại thanh toán tại sân trước khi thi đấu.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warningOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warningOrange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.warningOrange,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ERROR BANNER ───────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.badgeCancelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.badgeCancelText.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.badgeCancelText,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.badgeCancelText,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA BAR ────────────────────────────────────────────────────────────────────
class _CtaBar extends StatelessWidget {
  final String total;
  final bool isLoading;
  final VoidCallback onConfirm;
  const _CtaBar({
    required this.total,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: isLoading ? null : onConfirm,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: isLoading
                    ? AppColors.primary.withValues(alpha: 0.7)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isLoading ? [] : AppShadow.btn,
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'XÁC NHẬN  •  $total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── SECTION LABEL ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }
}
