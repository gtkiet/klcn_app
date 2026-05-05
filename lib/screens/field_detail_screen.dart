// lib/screens/field_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────
abstract class _C {
  static const primary = Color(0xFF2E7D32);
  static const bgPage = Color(0xFFF2F5F0);
  static const cardBg = Colors.white;
  // static const textDark = Color(0xFF1A1A1A);
  static const textLight = Color(0xFF888888);
  static const divider = Color(0xFFEAEDEA);

  static const slotSelected = primary;
  static const slotBooked = Color(0xFFF5F5F5);
  static const slotBorder = Color(0xFFD5D8D5);
}

abstract class _S {
  static const double pad = 16;
  static const double radius = 16;
  static const double heroHeight = 240;
}

// ─────────────────────────────────────────────
// MODELS (READY FOR API)
// ─────────────────────────────────────────────
class Amenity {
  final IconData icon;
  final Color color;
  final String label;

  const Amenity(this.icon, this.color, this.label);
}

class DateItem {
  final String label;
  final int date;

  const DateItem(this.label, this.date);
}

class TimeSlot {
  final String start;
  final String end;
  final bool booked;
  final int price;

  const TimeSlot({
    required this.start,
    required this.end,
    this.booked = false,
    this.price = 450000,
  });

  String get time => '$start - $end';
}

// ─────────────────────────────────────────────
// MOCK DATA (REPLACE WITH API)
// ─────────────────────────────────────────────
final amenities = [
  const Amenity(Icons.lightbulb_outline, Colors.green, 'Đèn chiếu sáng'),
  const Amenity(Icons.checkroom, Colors.indigo, 'Phòng thay đồ'),
  const Amenity(Icons.local_parking, Colors.deepOrange, 'Bãi xe'),
  const Amenity(Icons.wifi, Colors.blue, 'Wifi'),
];

final dates = List.generate(7, (i) => DateItem('T${i + 2}', 20 + i));

final slots = [
  const TimeSlot(start: '17:00', end: '18:00'),
  const TimeSlot(start: '18:00', end: '19:00'),
  const TimeSlot(start: '19:00', end: '20:00', booked: true),
  const TimeSlot(start: '20:00', end: '21:00'),
];

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────
class FieldDetailScreen extends StatefulWidget {
  const FieldDetailScreen({super.key});

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  int selectedDate = 0;
  int? selectedSlot;
  bool isFavorite = false;

  int get totalPrice => selectedSlot != null ? slots[selectedSlot!].price : 0;

  void onBook() {
    if (selectedSlot == null) return;

    Navigator.pushNamed(
      context,
      '/booking_confirm',
      arguments: {'date': dates[selectedDate], 'slot': slots[selectedSlot!]},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bgPage,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: _C.primary,
          title: const Text('Chi tiết sân'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: () => setState(() => isFavorite = !isFavorite),
            ),
          ],
        ),

        bottomNavigationBar: _BottomBar(
          price: totalPrice,
          enabled: selectedSlot != null,
          onTap: onBook,
        ),

        body: ListView(
          // padding: const EdgeInsets.only(bottom: 16),
          children: [
            _Hero(),

            const SizedBox(height: 16),

            _InfoCard(),

            const SizedBox(height: 16),

            _Section('Tiện ích sân'),
            const SizedBox(height: 8),
            _AmenityGrid(items: amenities),

            const SizedBox(height: 16),

            _Section('Chọn ngày'),
            _DateList(
              selected: selectedDate,
              onTap: (i) => setState(() => selectedDate = i),
            ),

            const SizedBox(height: 16),

            _Section('Chọn giờ'),
            _SlotGrid(
              selected: selectedSlot,
              onTap: (i) {
                if (slots[i].booked) return;
                setState(() => selectedSlot = i);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────
class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: _S.heroHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue, Colors.green]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INFO CARD
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _S.pad),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(_S.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Arena Santiago',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('Phú Nhuận, TP.HCM'),
          SizedBox(height: 8),
          Divider(),
          SizedBox(height: 8),
          Text(
            '450.000đ / giờ',
            style: TextStyle(
              color: _C.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _S.pad),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────
// AmenityGrid
// ─────────────────────────────────────────────

class _AmenityGrid extends StatelessWidget {
  final List<Amenity> items;

  const _AmenityGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _S.pad),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3,
        ),
        itemBuilder: (_, i) {
          final item = items[i];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.divider),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: item.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATE LIST
// ─────────────────────────────────────────────
class _DateList extends StatelessWidget {
  final int selected;
  final Function(int) onTap;

  const _DateList({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (_, i) {
          final isSelected = i == selected;

          return Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected ? _C.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dates[i].label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${dates[i].date}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SLOT GRID
// ─────────────────────────────────────────────
class _SlotGrid extends StatelessWidget {
  final int? selected;
  final Function(int) onTap;

  const _SlotGrid({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(_S.pad),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (_, i) {
        final slot = slots[i];
        final isSelected = selected == i;

        return InkWell(
          onTap: slot.booked ? null : () => onTap(i),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _C.slotSelected
                  : slot.booked
                  ? _C.slotBooked
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.slotBorder),
            ),
            child: Center(
              child: Text(
                slot.time,
                style: TextStyle(
                  color: slot.booked
                      ? Colors.grey
                      : isSelected
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int price;
  final bool enabled;
  final VoidCallback onTap;

  const _BottomBar({
    required this.price,
    required this.enabled,
    required this.onTap,
  });

  String _formatPrice(int p) => p == 0 ? '--' : '${p ~/ 1000}k';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── PRICE ─────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỔNG',
                    style: TextStyle(
                      fontSize: 11,
                      color: _C.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _C.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // ── BUTTON ────────────────────────
              Expanded(
                child: Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: Material(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: enabled ? onTap : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: enabled
                              ? [
                                  BoxShadow(
                                    color: _C.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ĐẶT SÂN NGAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
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
