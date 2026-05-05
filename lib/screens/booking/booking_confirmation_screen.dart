// lib/screens/booking/booking_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── MODELS ────────────────────────────────────
class _AddonService {
  final String id;
  final String name;
  final String description;
  final int priceValue;
  final String priceDisplay;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  bool selected;

  _AddonService({
    required this.id,
    required this.name,
    required this.description,
    required this.priceValue,
    required this.priceDisplay,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    this.selected = false,
  });
}

enum _PaymentMethod { online, atVenue }

// ── UTILS ─────────────────────────────────────
String _fmtMoney(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '$bufđ';
}

// ─────────────────────────────────────────────
//  BOOKING CONFIRMATION SCREEN
// ─────────────────────────────────────────────
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  static const int _basePrice = 450000;

  final List<_AddonService> _addons = [
    _AddonService(
      id: 'water',
      name: 'Nước uống',
      description: 'Aquafina 500ml',
      priceValue: 20000,
      priceDisplay: '20k/chai',
      iconBg: const Color(0xFFE8EAF6),
      icon: Icons.water_drop_outlined,
      iconColor: const Color(0xFF5C6BC0),
      selected: true,
    ),
    _AddonService(
      id: 'ball',
      name: 'Thuê bóng',
      description: 'Bóng Động Lực',
      priceValue: 50000,
      priceDisplay: '50k/quả',
      iconBg: const Color(0xFFFCE4EC),
      icon: Icons.sports_soccer,
      iconColor: const Color(0xFFE53935),
      selected: true,
    ),
  ];

  _PaymentMethod _paymentMethod = _PaymentMethod.online;

  int get _addonTotal =>
      _addons.where((e) => e.selected).fold(0, (s, e) => s + e.priceValue);
  int get _total => _basePrice + _addonTotal;

  void _confirm() {
    // TODO: call BookingService
    if (_paymentMethod == _PaymentMethod.online) {
      Navigator.pushNamed(context, '/booking_success');
    } else {
      Navigator.pushNamed(context, '/booking_success');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Xác nhận đặt sân'),
        ),
        bottomNavigationBar: _CtaBar(
          total: _fmtMoney(_total),
          onConfirm: _confirm,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadH),
          children: [
            // Hero card
            const _StadiumHeroCard(),
            const SizedBox(height: 12),

            // Location
            const _LocationCard(),
            const SizedBox(height: 14),

            // Booking detail
            const _BookingDetailCard(),
            const SizedBox(height: 20),

            // Add-ons
            const Text(
              'Dịch vụ đi kèm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ..._addons.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AddonTile(
                  addon: e.value,
                  onTap: () => setState(
                    () => _addons[e.key].selected = !_addons[e.key].selected,
                  ),
                ),
              ),
            ),

            // Payment method
            const SizedBox(height: 6),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            _PaymentMethodCard(
              selected: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),

            // Price summary
            const SizedBox(height: 14),
            _PriceSummaryCard(
              base: _fmtMoney(_basePrice),
              addon: _fmtMoney(_addonTotal),
              total: _fmtMoney(_total),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── STADIUM HERO CARD ─────────────────────────
class _StadiumHeroCard extends StatelessWidget {
  const _StadiumHeroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: SizedBox(
        height: 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1B5E20)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Colors.white12,
                ),
              ),
            ),
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
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SÂN CAO CẤP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Arena Santiago',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
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

// ── LOCATION CARD ─────────────────────────────
class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    return SpCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phú Nhuận, TP.HCM',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Sân đạt chuẩn FIFA',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── BOOKING DETAIL CARD ───────────────────────
class _BookingDetailCard extends StatelessWidget {
  const _BookingDetailCard();

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT ĐẶT SÂN',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _DetailCell(label: 'NGÀY', value: '20/10/2026'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DetailCell(label: 'GIỜ', value: '18:00 - 19:00'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(
                child: _DetailCell(label: 'THỜI LƯỢNG', value: '1 giờ'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DetailCell(
                  label: 'GIÁ',
                  value: '450.000đ',
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ADDON TILE ────────────────────────────────
class _AddonTile extends StatelessWidget {
  final _AddonService addon;
  final VoidCallback onTap;
  const _AddonTile({required this.addon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: addon.selected ? AppColors.primary : AppColors.fieldBorder,
            width: addon.selected ? 1.8 : 1,
          ),
          boxShadow: AppShadow.card,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: addon.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(addon.icon, color: addon.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addon.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    addon.description,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              addon.priceDisplay,
              style: const TextStyle(
                color: AppColors.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              addon.selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: addon.selected ? AppColors.primary : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PAYMENT METHOD CARD ───────────────────────
class _PaymentMethodCard extends StatelessWidget {
  final _PaymentMethod selected;
  final ValueChanged<_PaymentMethod?> onChanged;
  const _PaymentMethodCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PaymentItem(
            value: _PaymentMethod.online,
            label: 'Thanh toán online',
            icon: Icons.account_balance_wallet_outlined,
            selected: selected,
            onChanged: onChanged,
          ),
          const Divider(height: 1, color: AppColors.fieldBorder),
          _PaymentItem(
            value: _PaymentMethod.atVenue,
            label: 'Thanh toán tại sân',
            icon: Icons.payments_outlined,
            selected: selected,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final _PaymentMethod value;
  final String label;
  final IconData icon;
  final _PaymentMethod selected;
  final ValueChanged<_PaymentMethod?> onChanged;

  const _PaymentItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: AppColors.textMid, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: AppColors.textDark, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PRICE SUMMARY ─────────────────────────────
class _PriceSummaryCard extends StatelessWidget {
  final String base;
  final String addon;
  final String total;
  const _PriceSummaryCard({
    required this.base,
    required this.addon,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        children: [
          _PriceRow(label: 'Tiền sân', value: base),
          const SizedBox(height: 6),
          _PriceRow(label: 'Dịch vụ', value: addon),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.fieldBorder),
          ),
          _PriceRow(label: 'Tổng cộng', value: total, isTotal: true),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
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
            fontWeight: FontWeight.w800,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? AppColors.primary : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

// ── CTA BAR ───────────────────────────────────
class _CtaBar extends StatelessWidget {
  final String total;
  final VoidCallback onConfirm;
  const _CtaBar({required this.total, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SpPrimaryButton(
          label: 'XÁC NHẬN  •  $total',
          onTap: onConfirm,
          trailingIcon: null,
        ),
      ),
    );
  }
}
