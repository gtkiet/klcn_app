// lib/screens/field_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

// ── MODELS ────────────────────────────────────
class _Amenity {
  final IconData icon;
  final Color color;
  final String label;
  const _Amenity(this.icon, this.color, this.label);
}

class _DateItem {
  final String label;
  final int date;
  const _DateItem(this.label, this.date);
}

class _TimeSlot {
  final String start;
  final String end;
  final bool booked;
  final int price;
  const _TimeSlot({required this.start, required this.end, this.booked = false, this.price = 450000});
  String get time => '$start - $end';
}

// ── MOCK DATA ─────────────────────────────────
final _amenities = [
  const _Amenity(Icons.lightbulb_outline,   Colors.green,      'Đèn chiếu sáng'),
  const _Amenity(Icons.checkroom,            Colors.indigo,     'Phòng thay đồ'),
  const _Amenity(Icons.local_parking,        Colors.deepOrange, 'Bãi đỗ xe'),
  const _Amenity(Icons.wifi,                 Colors.blue,       'Wifi miễn phí'),
];

final _dates = List.generate(7, (i) => _DateItem('T${i + 2}', 20 + i));

final _slots = [
  const _TimeSlot(start: '17:00', end: '18:00'),
  const _TimeSlot(start: '18:00', end: '19:00'),
  const _TimeSlot(start: '19:00', end: '20:00', booked: true),
  const _TimeSlot(start: '20:00', end: '21:00'),
  const _TimeSlot(start: '21:00', end: '22:00'),
  const _TimeSlot(start: '06:00', end: '07:00', price: 360000),
];

// ─────────────────────────────────────────────
//  FIELD DETAIL SCREEN
// ─────────────────────────────────────────────
class FieldDetailScreen extends StatefulWidget {
  const FieldDetailScreen({super.key});

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  int _selectedDate = 0;
  int? _selectedSlot;
  bool _isFavorite = false;

  int get _totalPrice => _selectedSlot != null ? _slots[_selectedSlot!].price : 0;

  void _onBook() {
    if (_selectedSlot == null) return;
    Navigator.pushNamed(context, '/booking_confirm',
        arguments: {'date': _dates[_selectedDate], 'slot': _slots[_selectedSlot!]});
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          title: const Text('Chi tiết sân'),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : AppColors.primary),
              onPressed: () => setState(() => _isFavorite = !_isFavorite),
            ),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          price: _totalPrice,
          enabled: _selectedSlot != null,
          onTap: _onBook,
        ),
        body: ListView(
          children: [
            // Hero image
            Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.sports_soccer, color: Colors.white24, size: 80),
              ),
            ),

            const SizedBox(height: 16),

            // Info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
              child: SpCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Arena Santiago',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                        SizedBox(width: 4),
                        Text('Phú Nhuận, TP.HCM', style: TextStyle(color: AppColors.textLight)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('450.000đ / giờ',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryUltraLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.star_rounded, size: 14, color: AppColors.ratingGold),
                              SizedBox(width: 3),
                              Text('4.8', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Amenities
            _SectionTitle('Tiện ích sân'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _amenities.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3.2,
                ),
                itemBuilder: (_, i) {
                  final item = _amenities[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.label,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Date picker
            _SectionTitle('Chọn ngày'),
            SizedBox(
              height: 74,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH, vertical: 6),
                itemCount: _dates.length,
                itemBuilder: (_, i) {
                  final selected = i == _selectedDate;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 58,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: selected ? AppShadow.card : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_dates[i].label,
                              style: TextStyle(
                                  color: selected ? Colors.white : AppColors.textMid,
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${_dates[i].date}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: selected ? Colors.white : AppColors.textDark)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Time slots
            _SectionTitle('Chọn giờ'),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadH),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_slots.length, (i) {
                  final slot = _slots[i];
                  final isSelected = _selectedSlot == i;
                  return GestureDetector(
                    onTap: slot.booked ? null : () => setState(() => _selectedSlot = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : slot.booked
                                ? AppColors.fieldBg
                                : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.fieldBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        slot.time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: slot.booked
                              ? AppColors.textHint
                              : isSelected
                                  ? Colors.white
                                  : AppColors.textDark,
                          decoration: slot.booked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadH, 0, AppSpacing.pagePadH, 16),
              child: Row(
                children: [
                  _LegendDot(color: AppColors.primary, label: 'Đã chọn'),
                  const SizedBox(width: 20),
                  _LegendDot(color: AppColors.fieldBg, label: 'Đã đặt', border: true),
                  const SizedBox(width: 20),
                  _LegendDot(color: Colors.white, label: 'Còn trống', border: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION TITLE ─────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

// ── LEGEND DOT ────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool border;
  const _LegendDot({required this.color, required this.label, this.border = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border ? Border.all(color: AppColors.fieldBorder) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
      ],
    );
  }
}

// ── BOTTOM BAR ────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int price;
  final bool enabled;
  final VoidCallback onTap;

  const _BottomBar({required this.price, required this.enabled, required this.onTap});

  String _fmt(int p) => p == 0 ? '--' : '${(p / 1000).toStringAsFixed(0)}k';

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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TỔNG',
                      style: TextStyle(fontSize: 10, color: AppColors.textLight,
                          fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(_fmt(price),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: enabled ? AppShadow.btn : [],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ĐẶT SÂN NGAY',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
