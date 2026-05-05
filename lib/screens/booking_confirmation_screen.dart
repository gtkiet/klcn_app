// lib/screens/booking_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// TODO: Replace Navigator with go_router when integrating real navigation
// TODO: Connect BookingService, PaymentService

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  // static const appBarTitle = Color(0xFF1A1A1A);
  static const bgPage = Color(0xFFF2F5F0);
  static const cardBg = Colors.white;

  static const heroBadgeBg = Color(0xFF2E7D32);

  static const cellBg = Color(0xFFF7F8F6);
  static const cellBorder = Color(0xFFE4E7E4);

  static const addonBorderOff = Color(0xFFE0E3E0);
  static const addonBorderOn = Color(0xFF2E7D32);
  static const addonIconBgBlue = Color(0xFFE8EAF6);
  static const addonIconBgPink = Color(0xFFFCE4EC);
  // static const checkboxOn = Color(0xFF2E7D32);

  // static const radioOn = Color(0xFF2E7D32);
  // static const radioOff = Color(0xFFCCCCCC);

  // static const dashedLine = Color(0xFFD0D4D0);
  // static const priceTotal = Color(0xFF2E7D32);
  // static const vatLabel = Color(0xFF888888);

  // static const ctaBg = Color(0xFF2E7D32);

  static const textDark = Color(0xFF1A1A1A);
  // static const textMid = Color(0xFF555555);
  static const textLight = Color(0xFF888888);
  static const textCellLabel = Color(0xFF999999);
}

abstract class _S {
  // static const pagePadH = 16.0;
  static const cardRadius = 14.0;
  static const heroHeight = 200.0;
  static const btnRadius = 14.0;
}

// ─────────────────────────────────────────────
//  UTILS
// ─────────────────────────────────────────────
class _Money {
  static String format(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return '$bufferđ';
  }
}

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────
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

enum PaymentMethod { online, atVenue }

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  static const _basePrice = 450000;

  final List<_AddonService> _addons = [
    _AddonService(
      id: 'water',
      name: 'Nước uống',
      description: 'Aquafina 500ml',
      priceValue: 20000,
      priceDisplay: '20k/chai',
      iconBg: _C.addonIconBgBlue,
      icon: Icons.water_drop_outlined,
      iconColor: Color(0xFF5C6BC0),
      selected: true,
    ),
    _AddonService(
      id: 'ball',
      name: 'Thuê bóng',
      description: 'Bóng Động Lực',
      priceValue: 50000,
      priceDisplay: '50k/quả',
      iconBg: _C.addonIconBgPink,
      icon: Icons.sports_soccer,
      iconColor: Color(0xFFE53935),
      selected: true,
    ),
  ];

  PaymentMethod _paymentMethod = PaymentMethod.online;

  int get _addonTotal =>
      _addons.where((e) => e.selected).fold(0, (s, e) => s + e.priceValue);

  int get _total => _basePrice + _addonTotal;

  void _toggleAddon(int index) {
    setState(() => _addons[index].selected = !_addons[index].selected);
  }

  void _confirm() {
    // TODO: call BookingService
    if (_paymentMethod == PaymentMethod.online) {
      Navigator.pushNamed(context, '/payment');
    } else {
      Navigator.pushNamed(context, '/booking_success');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bgPage,
        appBar: const _ConfirmAppBar(),

        bottomNavigationBar: _CtaBar(
          total: _Money.format(_total),
          onConfirm: _confirm,
        ),

        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _StadiumHeroCard(),
            const SizedBox(height: 14),
            const _LocationCard(),
            const SizedBox(height: 16),
            const _BookingDetailCard(),

            const SizedBox(height: 20),
            const _SectionTitle('Dịch vụ đi kèm'),

            ..._addons.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _AddonTile(
                  addon: e.value,
                  onTap: () => _toggleAddon(e.key),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const _SectionTitle('Thanh toán'),

            _PaymentMethodCard(
              selected: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),

            const SizedBox(height: 16),

            _PriceSummaryCard(
              base: _Money.format(_basePrice),
              addon: _Money.format(_addonTotal),
              total: _Money.format(_total),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/booking_failure'),
          child: const Icon(Icons.error),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  COMPONENTS
// ─────────────────────────────────────────────

class _ConfirmAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ConfirmAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.bgPage,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _C.primary),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Xác nhận đặt sân',
        style: TextStyle(color: _C.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ADDON TILE (IMPROVED UX)
// ─────────────────────────────────────────────
class _AddonTile extends StatelessWidget {
  final _AddonService addon;
  final VoidCallback onTap;

  const _AddonTile({required this.addon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_S.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(_S.cardRadius),
          border: Border.all(
            color: addon.selected ? _C.addonBorderOn : _C.addonBorderOff,
            width: addon.selected ? 1.8 : 1,
          ),
          boxShadow: _cardShadow,
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    addon.description,
                    style: const TextStyle(color: _C.textLight),
                  ),
                ],
              ),
            ),

            Text(addon.priceDisplay),
            const SizedBox(width: 10),

            Icon(
              addon.selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: addon.selected ? _C.primary : _C.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRICE SUMMARY (CLEAN)
// ─────────────────────────────────────────────
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          _row('Tiền sân', base),
          _row('Dịch vụ', addon),
          const Divider(),
          _row('Tổng', total, isTotal: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? _C.primary : _C.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CTA
// ─────────────────────────────────────────────
class _CtaBar extends StatelessWidget {
  final String total;
  final VoidCallback onConfirm;

  const _CtaBar({required this.total, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_S.btnRadius),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: onConfirm,
          child: Text('XÁC NHẬN • $total'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHADOW
// ─────────────────────────────────────────────
const _cardShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
];

class _StadiumHeroCard extends StatelessWidget {
  const _StadiumHeroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_S.cardRadius),
      child: SizedBox(
        height: _S.heroHeight,
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

            // overlay
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
                      color: _C.heroBadgeBg,
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

class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on_outlined, color: _C.primary),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phú Nhuận, TP.HCM',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text('Sân đạt chuẩn FIFA', style: TextStyle(color: _C.textLight)),
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
        color: _C.cellBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.cellBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _C.textCellLabel,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? _C.textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailCard extends StatelessWidget {
  const _BookingDetailCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT ĐẶT SÂN',
            style: TextStyle(color: _C.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: const [
              Expanded(
                child: _DetailCell(label: 'NGÀY', value: '20/10/2026'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _DetailCell(label: 'GIỜ', value: '18:00-19:00'),
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
                  valueColor: _C.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod?> onChanged;

  const _PaymentMethodCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          _item(context, PaymentMethod.online, 'Thanh toán online'),
          const Divider(height: 1),
          _item(context, PaymentMethod.atVenue, 'Thanh toán tại sân'),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, PaymentMethod value, String title) {
    final isSelected = value == selected;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? _C.primary : _C.textLight,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}
