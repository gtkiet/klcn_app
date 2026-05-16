// lib/screens/booking/booking_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/field.dart';
// import '../../models/booking.dart';
import '../../models/service.dart';
import '../../models/promotion.dart';
import '../../services/booking_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── UTILS ─────────────────────────────────────
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

// methodId theo server: 1=Cash | 2=Transfer | 3=MoMo
class _PayMethod {
  final int methodId;
  final String label;
  final IconData icon;
  const _PayMethod(this.methodId, this.label, this.icon);
}

const _payMethods = [
  _PayMethod(3, 'MoMo',               Icons.account_balance_wallet_outlined),
  _PayMethod(2, 'Chuyển khoản',       Icons.qr_code_outlined),
  _PayMethod(1, 'Thanh toán tại sân', Icons.payments_outlined),
];

// ─────────────────────────────────────────────
//  BOOKING CONFIRMATION SCREEN
//
//  extra: { 'field': FieldModel, 'date': DateTime, 'slots': List<SlotModel> }
// ─────────────────────────────────────────────
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends State<BookingConfirmationScreen> {
  // ── Input từ extra ─────────────────────────
  late final FieldModel _field;
  late final DateTime   _date;
  late final List<SlotModel> _slots;

  // ── Services ───────────────────────────────
  List<ServiceModel> _services    = [];
  bool _isLoadingServices         = false;

  // ── Selection ──────────────────────────────
  final Map<int, int> _serviceQty = {}; // serviceId → quantity
  int _selectedMethodId           = 3;  // mặc định MoMo

  // ── Voucher ────────────────────────────────
  final _voucherCtrl = TextEditingController();
  PromotionModel? _promotion;
  bool _isCheckingVoucher         = false;
  String? _voucherError;

  // ── Booking ────────────────────────────────
  bool _isBooking                 = false;
  String? _bookingError;

  // ── Derived ────────────────────────────────
  double get _slotTotal =>
      _slots.fold(0, (s, slot) => s + slot.price);

  double get _serviceTotal =>
      _services.fold(0, (s, svc) {
        final qty = _serviceQty[svc.serviceId] ?? 0;
        return s + svc.price * qty;
      });

  double get _subTotal  => _slotTotal + _serviceTotal;
  double get _discount  => _promotion?.calcDiscount(_subTotal) ?? 0;
  double get _total     => (_subTotal - _discount).clamp(0, double.infinity);

  // ── Lifecycle ──────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null) {
      _field = extra['field'] as FieldModel;
      _date  = extra['date']  as DateTime;
      _slots = extra['slots'] as List<SlotModel>;
      _loadServices();
    }
  }

  @override
  void dispose() {
    _voucherCtrl.dispose();
    super.dispose();
  }

  // ── API ────────────────────────────────────
  Future<void> _loadServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final list = await BookingService.instance.getServices(isAvailable: true);
      if (!mounted) return;
      setState(() { _services = list; _isLoadingServices = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingServices = false);
    }
  }

  Future<void> _checkVoucher() async {
    final code = _voucherCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _isCheckingVoucher = true; _voucherError = null; _promotion = null; });
    try {
      final promo = await BookingService.instance.getPromotion(code);
      if (!mounted) return;
      setState(() { _promotion = promo; _isCheckingVoucher = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _voucherError = e.toString(); _isCheckingVoucher = false; });
    }
  }

  Future<void> _confirm() async {
    setState(() { _isBooking = true; _bookingError = null; });
    try {
      final slotIds = _slots.map((s) => s.fieldSlotId).toList();

      // Hold slots trước
      await BookingService.instance.holdSlots(slotIds);

      // Build service list
      final serviceItems = _services
          .where((s) => (_serviceQty[s.serviceId] ?? 0) > 0)
          .map((s) => ServiceRequestItem(
                serviceId: s.serviceId,
                quantity:  _serviceQty[s.serviceId]!,
              ))
          .toList();

      // Tạo booking
      final booking = await BookingService.instance.createBooking(
        fieldSlotIds:  slotIds,
        services:      serviceItems,
        promotionCode: _promotion?.code,
      );

      if (!mounted) return;

      // Xử lý theo phương thức thanh toán
      if (_selectedMethodId == 3) {
        // MoMo — lấy payment URL rồi push
        final payUrl = await BookingService.instance
            .createMoMoPayment(booking.bookingId);
        if (!mounted) return;
        context.push('/fields/booking_confirm/booking_success', extra: {
          'booking': booking,
          'payUrl':  payUrl,
        });
      } else {
        // Cash / Transfer — submit payment ngay
        await BookingService.instance.submitPayment(
          bookingId: booking.bookingId,
          methodId:  _selectedMethodId,
        );
        if (!mounted) return;
        context.push('/fields/booking_confirm/booking_success', extra: {
          'booking': booking,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _bookingError = e.toString(); _isBooking = false; });
      context.push('/fields/booking_confirm/booking_failure', extra: {
        'error': e.toString(),
      });
    }
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
          total:     _fmtMoney(_total),
          isLoading: _isBooking,
          onConfirm: _confirm,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadH),
          children: [
            // Hero sân
            _FieldHeroCard(field: _field),
            const SizedBox(height: 14),

            // Chi tiết slot
            _SlotDetailCard(slots: _slots, date: _date),
            const SizedBox(height: 20),

            // Dịch vụ đi kèm
            _SectionLabel('Dịch vụ đi kèm'),
            const SizedBox(height: 10),
            if (_isLoadingServices)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2,
                  ),
                ),
              )
            else
              ..._services.map((svc) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceTile(
                  service: svc,
                  quantity: _serviceQty[svc.serviceId] ?? 0,
                  onChanged: (qty) => setState(
                    () => _serviceQty[svc.serviceId] = qty,
                  ),
                ),
              )),

            // Voucher
            const SizedBox(height: 6),
            _SectionLabel('Mã giảm giá'),
            const SizedBox(height: 10),
            _VoucherRow(
              controller:    _voucherCtrl,
              isLoading:     _isCheckingVoucher,
              promotion:     _promotion,
              error:         _voucherError,
              onApply:       _checkVoucher,
              onRemove: () => setState(() {
                _promotion   = null;
                _voucherError = null;
                _voucherCtrl.clear();
              }),
            ),

            // Phương thức thanh toán
            const SizedBox(height: 20),
            _SectionLabel('Phương thức thanh toán'),
            const SizedBox(height: 10),
            _PaymentMethodCard(
              methods:        _payMethods,
              selectedId:     _selectedMethodId,
              onChanged: (id) => setState(() => _selectedMethodId = id),
            ),

            // Tổng tiền
            const SizedBox(height: 14),
            _PriceSummaryCard(
              slotTotal:    _slotTotal,
              serviceTotal: _serviceTotal,
              discount:     _discount,
              total:        _total,
              promotion:    _promotion,
            ),

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

// ── FIELD HERO CARD ───────────────────────────
class _FieldHeroCard extends StatelessWidget {
  final FieldModel field;
  const _FieldHeroCard({required this.field});

  Color get _placeholderColor {
    const palette = [
      Color(0xFF1B5E20), Color(0xFF0D47A1), Color(0xFF4A148C),
      Color(0xFF00695C), Color(0xFF4E342E),
    ];
    return palette[field.name.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            field.imageUrl != null
                ? Image.network(
                    field.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: _placeholderColor,
                          child: const Center(child: Icon(Icons.sports_soccer, color: Colors.white12, size: 64))),
                  )
                : Container(
                    color: _placeholderColor,
                    child: const Center(child: Icon(Icons.sports_soccer, color: Colors.white12, size: 64)),
                  ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14, right: 14, bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      field.fieldType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    field.name,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
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

// ── SLOT DETAIL CARD ──────────────────────────
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
              color: AppColors.textHint, fontSize: 10.5,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
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
                  label: slots.length > 1 ? 'KHUNG GIỜ (${slots.length} slot)' : 'KHUNG GIỜ',
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
              children: slots.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryUltraLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s.displayTime}  ${s.isPeakHour ? '⚡' : ''}${s.priceFmt}',
                  style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
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
  const _DetailCell({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMid),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 9.5,
                  fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                color: valueColor ?? AppColors.textDark,
                fontSize: 13.5, fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

// ── SERVICE TILE ──────────────────────────────
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
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_soccer_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                if (service.description != null)
                  Text(service.description!,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12.5)),
              ],
            ),
          ),
          Text(
            service.priceFmt,
            style: const TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          // Stepper
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
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                onTap: () => onChanged(quantity + 1),
              ),
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
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: onTap != null ? Colors.white : AppColors.textHint, size: 16),
      ),
    );
  }
}

// ── VOUCHER ROW ───────────────────────────────
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
            const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion!.code,
                    style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14,
                    ),
                  ),
                  Text(
                    'Giảm ${promotion!.discountLabel}',
                    style: const TextStyle(color: AppColors.textMid, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, color: AppColors.textLight, size: 18),
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
                    color: error != null ? AppColors.errorRed : AppColors.fieldBorder,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã giảm giá',
                    hintStyle: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.normal),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    prefixIcon: Icon(Icons.local_offer_outlined, color: AppColors.textHint, size: 18),
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
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Áp dụng',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(error!, style: const TextStyle(color: AppColors.errorRed, fontSize: 12.5)),
          ),
      ],
    );
  }
}

// ── PAYMENT METHOD CARD ───────────────────────
class _PaymentMethodCard extends StatelessWidget {
  final List<_PayMethod> methods;
  final int selectedId;
  final ValueChanged<int> onChanged;

  const _PaymentMethodCard({
    required this.methods,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SpCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: methods.asMap().entries.map((e) {
          final method = e.value;
          final isLast = e.key == methods.length - 1;
          final selected = method.methodId == selectedId;
          return Column(
            children: [
              InkWell(
                onTap: () => onChanged(method.methodId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selected ? AppColors.primary : AppColors.textLight,
                      ),
                      const SizedBox(width: 12),
                      Icon(method.icon, color: AppColors.textMid, size: 20),
                      const SizedBox(width: 10),
                      Text(method.label,
                          style: TextStyle(
                            color: selected ? AppColors.textDark : AppColors.textMid,
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, color: AppColors.fieldBorder),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── PRICE SUMMARY CARD ────────────────────────
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
          _Row('Tiền sân',    _fmtMoney(slotTotal)),
          if (serviceTotal > 0) ...[
            const SizedBox(height: 6),
            _Row('Dịch vụ',  _fmtMoney(serviceTotal)),
          ],
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _Row(
              'Giảm giá${promotion != null ? ' (${promotion!.code})' : ''}',
              '-${_fmtMoney(discount)}',
              valueColor: AppColors.badgeCancelText,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.fieldBorder),
          ),
          _Row('Tổng cộng', _fmtMoney(total), isTotal: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.isTotal = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: isTotal ? AppColors.textDark : AppColors.textMid,
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            )),
        Text(value,
            style: TextStyle(
              color: valueColor ?? (isTotal ? AppColors.primary : AppColors.textDark),
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

// ── MISC WIDGETS ──────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark,
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.badgeCancelBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.badgeCancelText.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.badgeCancelText, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(color: AppColors.badgeCancelText, fontSize: 13)),
        ),
      ],
    ),
  );
}

// ── CTA BAR ───────────────────────────────────
class _CtaBar extends StatelessWidget {
  final String total;
  final bool isLoading;
  final VoidCallback onConfirm;
  const _CtaBar({required this.total, required this.isLoading, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, -3)),
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadow.btn,
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        'XÁC NHẬN  •  $total',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w900, letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}