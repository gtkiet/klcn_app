// lib/screens/booking/booking_detail_screen.dart
//
// extra: BookingSummary (từ history) | BookingModel (từ success screen)
//        | Map{'bookingId': int} (từ deep link handler)
// Luôn gọi API để lấy full detail sau khi nhận extra.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:klcn_app/navigation/app_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/booking.dart';
import '../../models/field.dart';
import '../../models/invoice.dart';
import '../../services/booking_service.dart';
import '../../services/field_service.dart';
import '../../services/invoice_service.dart';
import '../../services/payment_service.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

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

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  int? _bookingId;
  BookingModel? _booking;

  bool _isLoading = false;
  bool _isCancelling = false;
  bool _isPayingVnPay = false;
  bool _isRescheduling = false;
  bool _isSubmittingReview = false;
  bool _isLoadingInvoice = false;
  // Mỗi index tương ứng 1 payment đã thanh toán (sắp xếp cũ → mới):
  //   invoices[0] = hóa đơn cọc (nếu có)
  //   invoices[1] = hóa đơn thanh toán còn lại (hoặc hóa đơn full ở [0])
  List<InvoiceModel> _invoices = [];
  // Theo dõi trạng thái "đang mở PDF" cho từng hóa đơn theo paymentId
  final Map<int, bool> _isOpeningPdfMap = {};
  String? _errorMsg;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingId == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is BookingSummary) {
        _bookingId = extra.bookingId;
      } else if (extra is BookingModel) {
        _booking = extra;
        _bookingId = extra.bookingId;
      } else if (extra is Map<String, dynamic>) {
        _bookingId = extra['bookingId'] as int?;
      }
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    if (_bookingId == null) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final detail = await BookingService.instance.getBookingDetail(
        _bookingId!,
      );
      if (!mounted) return;
      setState(() {
        _booking = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Thanh toán VNPay ─────────────────────────────────────────
  // Dùng cho cả 2 trường hợp:
  Future<void> _onPayVnPay() async {
    if (_bookingId == null) return;
    setState(() => _isPayingVnPay = true);
    try {
      final paymentUrl = await PaymentService.instance.createVnPayPayment(
        _bookingId!,
      );
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack('Không thể mở trang thanh toán VNPay', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isPayingVnPay = false);
    }
  }

  // ── Hủy đơn ──────────────────────────────────────────────────
  Future<void> _onCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận hủy',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Bạn có chắc muốn hủy đơn đặt sân này không?\n'
          'Tiền cọc sẽ được hoàn theo chính sách.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Không',
              style: TextStyle(color: AppColors.textMid),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy đặt sân',
              style: TextStyle(
                color: AppColors.badgeCancelText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await BookingService.instance.cancelBooking(bookingId: _bookingId!);
      if (!mounted) return;
      _showSnack('Đã hủy đơn đặt sân');
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  // ── Đổi lịch (Reschedule) ────────────────────────────────────
  Future<void> _onReschedule(BookingDetailItem detail) async {
    if (_bookingId == null || _booking == null) return;

    final slotDate = detail.slotDate;
    final schedules = await FieldService.instance.getSchedule(
      date: slotDate,
      fieldId: detail.fieldId,
    );

    final fieldSchedule = schedules.isEmpty ? null : schedules.first;
    if (fieldSchedule == null || !mounted) return;

    final availableSlots = fieldSchedule.slots
        .where((s) => s.isAvailable)
        .toList();

    if (availableSlots.isEmpty) {
      _showSnack('Không có slot trống cho sân này vào ngày đó', isError: true);
      return;
    }

    final selected = await showModalBottomSheet<SlotModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RescheduleSheet(
        fieldName: detail.fieldName,
        currentTime: detail.displayTime,
        slots: availableSlots,
      ),
    );

    if (selected == null || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận đổi lịch',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Đổi sang khung giờ ${selected.startTime} – ${selected.endTime}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: AppColors.textMid),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _isRescheduling = true);
    try {
      await BookingService.instance.reschedule(
        bookingId: _bookingId!,
        bookingDetailId: detail.bookingDetailId,
        newFieldSlotId: selected.fieldSlotId,
      );
      if (!mounted) return;
      _showSnack('Đổi lịch thành công');
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isRescheduling = false);
    }
  }

  // ── Gửi đánh giá ─────────────────────────────────────────────
  Future<void> _onSubmitReview({
    required int rating,
    required String comment,
    String? imagePath,
  }) async {
    if (_bookingId == null) return;
    setState(() => _isSubmittingReview = true);
    try {
      await ReviewService.instance.createReview(
        bookingId: _bookingId!,
        rating: rating,
        comment: comment.trim().isEmpty ? null : comment.trim(),
        imagePath: imagePath,
      );
      if (!mounted) return;
      _showSnack('Cảm ơn bạn đã đánh giá!');
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewSheet(
        isSubmitting: _isSubmittingReview,
        onSubmit: _onSubmitReview,
      ),
    );
  }

  Future<void> _onRebook() async {
    final fieldId = _booking?.details.firstOrNull?.fieldId;
    if (fieldId == null) {
      AppNavigation.goFields();
      return;
    }
    try {
      final field = await FieldService.instance.getFieldDetail(fieldId);
      if (!mounted) return;
      context.push('/fields/detail', extra: field);
    } catch (_) {
      if (!mounted) return;
      AppNavigation.goFields();
    }
  }

  // ── Tải hóa đơn ──────────────────────────────────────────────
  // Lấy danh sách payments → lấy TẤT CẢ payments đã thanh toán thành công
  // → fetch song song toàn bộ invoice, sắp xếp cũ → mới (cọc trước, còn lại sau).
  // Cache vào _invoices để không gọi lại.
  Future<List<InvoiceModel>> _loadInvoices() async {
    if (_invoices.isNotEmpty) return _invoices;
    if (_bookingId == null) return [];
    setState(() => _isLoadingInvoice = true);
    try {
      final payments = await BookingService.instance.getPayments(_bookingId!);
      // Lấy tất cả payments thành công (statusId == 2 = Paid), sắp xếp cũ → mới
      final paid = payments.where((p) => p.statusId == 2).toList()
        ..sort(
          (a, b) =>
              (a.paidAt ?? a.createdAt).compareTo(b.paidAt ?? b.createdAt),
        );
      if (paid.isEmpty) {
        _showSnack('Chưa có hóa đơn cho đơn đặt này', isError: true);
        return [];
      }
      // Fetch tất cả invoice song song
      final results = await Future.wait(
        paid.map((p) => InvoiceService.instance.getInvoice(p.paymentId)),
      );
      if (!mounted) return [];
      setState(() => _invoices = results);
      return results;
    } catch (e) {
      if (!mounted) return [];
      _showSnack('Không tải được hóa đơn: $e', isError: true);
      return [];
    } finally {
      if (mounted) setState(() => _isLoadingInvoice = false);
    }
  }

  Future<void> _onViewInvoice(int index) async {
    final invList = await _loadInvoices();
    if (invList.isEmpty || index >= invList.length || !mounted) return;
    final inv = invList[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => _InvoiceSheet(
          invoice: inv,
          isOpeningPdf: _isOpeningPdfMap[inv.paymentId] ?? false,
          onOpenPdf: () => _onOpenPdf(inv.paymentId),
        ),
      ),
    );
  }

  Future<void> _onOpenPdf(int paymentId) async {
    if (_isOpeningPdfMap[paymentId] == true) return;
    setState(() => _isOpeningPdfMap[paymentId] = true);
    try {
      await InvoiceService.instance.openInvoicePdf(paymentId);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Không thể mở PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isOpeningPdfMap[paymentId] = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          title: const Text('Chi tiết đơn đặt'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _booking != null
            ? _ActionBar(
                booking: _booking!,
                isPayingVnPay: _isPayingVnPay,
                isCancelling: _isCancelling,
                onPayVnPay: _onPayVnPay,
                onCancel: _onCancel,
                onRebook: _onRebook,
                onReview: _showReviewSheet,
              )
            : null,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _booking == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMsg != null && _booking == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMid, fontSize: 14),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loadDetail,
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking;
    if (booking == null) return const SizedBox.shrink();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDetail,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH,
                16,
                AppSpacing.pagePadH,
                0,
              ),
              child: _HeroCard(booking: booking),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH,
                14,
                AppSpacing.pagePadH,
                0,
              ),
              child: _StatusCard(booking: booking),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH,
                14,
                AppSpacing.pagePadH,
                0,
              ),
              child: _SlotCard(booking: booking),
            ),
          ),
          if (booking.services.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH,
                  14,
                  AppSpacing.pagePadH,
                  0,
                ),
                child: _ServicesCard(booking: booking),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadH,
                14,
                AppSpacing.pagePadH,
                0,
              ),
              child: _PaymentCard(booking: booking),
            ),
          ),
          // Hóa đơn — chỉ hiện khi đã có payment thành công
          if (booking.isConfirmed || booking.isCompleted)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH,
                  14,
                  AppSpacing.pagePadH,
                  0,
                ),
                child: _InvoicesSection(
                  isLoading: _isLoadingInvoice,
                  invoices: _invoices,
                  isOpeningPdfMap: _isOpeningPdfMap,
                  onView: _onViewInvoice,
                  onOpenPdf: _onOpenPdf,
                ),
              ),
            ),
          if (booking.deposit != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH,
                  14,
                  AppSpacing.pagePadH,
                  0,
                ),
                child: _DepositCard(deposit: booking.deposit!),
              ),
            ),
          if (booking.cancelReason != null && booking.cancelReason!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH,
                  14,
                  AppSpacing.pagePadH,
                  0,
                ),
                child: _CancelReasonCard(reason: booking.cancelReason!),
              ),
            ),
          if (booking.isConfirmed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH,
                  14,
                  AppSpacing.pagePadH,
                  0,
                ),
                child: _RescheduleCard(
                  booking: booking,
                  isRescheduling: _isRescheduling,
                  onReschedule: _onReschedule,
                ),
              ),
            ),
          if (booking.isCompleted)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadH,
                  14,
                  AppSpacing.pagePadH,
                  0,
                ),
                child: _ReviewCard(onWriteReview: _showReviewSheet),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── HERO CARD ─────────────────────────────────
class _HeroCard extends StatelessWidget {
  final BookingModel booking;
  const _HeroCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: SizedBox(
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_soccer,
                  color: Colors.white12,
                  size: 64,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.4, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Text(
                booking.primaryField,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STATUS CARD ───────────────────────────────
class _StatusCard extends StatelessWidget {
  final BookingModel booking;
  const _StatusCard({required this.booking});

  ({String text, Color textColor, Color bgColor}) get _badge =>
      switch (booking.statusId) {
        2 => (
          text: 'ĐÃ XÁC NHẬN',
          textColor: AppColors.badgeBookedText,
          bgColor: AppColors.badgeBookedBg,
        ),
        3 => (
          text: 'ĐÃ HỦY',
          textColor: AppColors.badgeCancelText,
          bgColor: AppColors.badgeCancelBg,
        ),
        4 => (
          text: 'HOÀN THÀNH',
          textColor: AppColors.badgeDoneText,
          bgColor: AppColors.badgeDoneBg,
        ),
        5 => (
          text: 'CHỜ THANH TOÁN',
          textColor: AppColors.warningOrange,
          bgColor: const Color(0xFFFFF3E0),
        ),
        _ => (
          text: booking.status.toUpperCase(),
          textColor: AppColors.textMid,
          bgColor: AppColors.fieldBg,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return SpCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MÃ ĐẶT SÂN',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#${booking.bookingId}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badge.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge.text,
              style: TextStyle(
                color: badge.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SLOT CARD ─────────────────────────────────
class _SlotCard extends StatelessWidget {
  final BookingModel booking;
  const _SlotCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT SLOT',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...booking.details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryUltraLight,
                      borderRadius: BorderRadius.circular(8),
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
                          d.fieldName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${d.displayDate}  •  ${d.displayTime}',
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    d.priceFmt,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SERVICES CARD ─────────────────────────────
class _ServicesCard extends StatelessWidget {
  final BookingModel booking;
  const _ServicesCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DỊCH VỤ ĐI KÈM',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...booking.services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.serviceName} ×${s.quantity}',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    s.totalFmt,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PAYMENT CARD ──────────────────────────────
class _PaymentCard extends StatelessWidget {
  final BookingModel booking;
  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        children: [
          if (booking.discountAmount > 0) ...[
            _PayRow('Tiền sân + dịch vụ', _fmtMoney(booking.subTotal)),
            const SizedBox(height: 6),
            _PayRow(
              'Giảm giá',
              '-${_fmtMoney(booking.discountAmount)}',
              valueColor: AppColors.badgeCancelText,
            ),
            const SizedBox(height: 6),
          ],
          if (booking.taxAmount > 0) ...[
            _PayRow('Thuế', _fmtMoney(booking.taxAmount)),
            const SizedBox(height: 6),
          ],
          const Divider(color: AppColors.fieldBorder),
          const SizedBox(height: 6),
          _PayRow('Tổng cộng', _fmtMoney(booking.totalAmount), isTotal: true),
          if (booking.promotionCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mã: ${booking.promotionCode}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;
  const _PayRow(
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

// ── DEPOSIT CARD ──────────────────────────────
class _DepositCard extends StatelessWidget {
  final DepositModel deposit;
  const _DepositCard({required this.deposit});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'THÔNG TIN ĐẶT CỌC',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deposit.isPaid
                      ? AppColors.badgeBookedBg
                      : AppColors.badgeCancelBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deposit.status,
                  style: TextStyle(
                    color: deposit.isPaid
                        ? AppColors.badgeBookedText
                        : AppColors.badgeCancelText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCell(
                  label: 'Cần đặt cọc',
                  value: _fmtMoney(deposit.requiredAmount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCell(
                  label: 'Đã thanh toán',
                  value: _fmtMoney(deposit.paidAmount),
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

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CANCEL REASON CARD ────────────────────────
class _CancelReasonCard extends StatelessWidget {
  final String reason;
  const _CancelReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.badgeCancelBg,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.badgeCancelText.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LÝ DO HỦY',
            style: TextStyle(
              color: AppColors.badgeCancelText,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ACTION BAR ────────────────────────────────
class _ActionBar extends StatelessWidget {
  final BookingModel booking;
  final bool isPayingVnPay;
  final bool isCancelling;
  final VoidCallback onPayVnPay;
  final VoidCallback onCancel;
  final VoidCallback onRebook;
  final VoidCallback onReview;

  const _ActionBar({
    required this.booking,
    required this.isPayingVnPay,
    required this.isCancelling,
    required this.onPayVnPay,
    required this.onCancel,
    required this.onRebook,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadH,
            vertical: 12,
          ),
          child: switch (booking.statusId) {
            // PendingDeposit (5) — chờ cọc
            5 => Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ActionBtn(
                    label: 'Thanh toán VNPay',
                    icon: Icons.payment_outlined,
                    isLoading: isPayingVnPay,
                    onTap: onPayVnPay,
                    color: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Hủy đặt',
                    icon: Icons.cancel_outlined,
                    isLoading: isCancelling,
                    onTap: onCancel,
                    color: AppColors.badgeCancelBg,
                    textColor: AppColors.badgeCancelText,
                    borderColor: const Color(0xFFFFCDD2),
                  ),
                ),
              ],
            ),

            // Confirmed (2) — đã xác nhận
            // Có 2 trường hợp:
            //   • Flow 1 (có cọc): deposit != null && deposit.isPaid == true
            //     → Còn nợ phần chênh lệch → hiện nút "Thanh toán còn lại"
            //   • Flow 2 (full): deposit == null
            //     → Đã trả hết → chỉ hiện hủy + đặt lại
            2 =>
              booking.deposit != null && booking.deposit!.isPaid
                  ? Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            label: 'Hủy đặt',
                            icon: Icons.cancel_outlined,
                            isLoading: isCancelling,
                            onTap: onCancel,
                            color: AppColors.badgeCancelBg,
                            textColor: AppColors.badgeCancelText,
                            borderColor: const Color(0xFFFFCDD2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _ActionBtn(
                            label: 'Thanh toán còn lại',
                            icon: Icons.payment_outlined,
                            isLoading: isPayingVnPay,
                            onTap: onPayVnPay,
                            color: AppColors.primary,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            label: 'Hủy đặt',
                            icon: Icons.cancel_outlined,
                            isLoading: isCancelling,
                            onTap: onCancel,
                            color: AppColors.badgeCancelBg,
                            textColor: AppColors.badgeCancelText,
                            borderColor: const Color(0xFFFFCDD2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            label: 'Đặt lại',
                            icon: Icons.refresh_rounded,
                            onTap: onRebook,
                            color: AppColors.primary,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

            // Completed (4)
            4 => Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Đặt lại sân này',
                    icon: Icons.refresh_rounded,
                    onTap: onRebook,
                    color: Colors.white,
                    textColor: AppColors.textDark,
                    borderColor: AppColors.fieldBorder,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Đánh giá',
                    icon: Icons.star_outline_rounded,
                    onTap: onReview,
                    color: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),

            // Cancelled (3) + default
            _ => _ActionBtn(
              label: 'Về trang chủ',
              icon: Icons.home_outlined,
              onTap: () => context.go('/home'),
              color: Colors.white,
              textColor: AppColors.textDark,
              borderColor: AppColors.fieldBorder,
            ),
          },
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.isLoading = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
          boxShadow: color == AppColors.primary ? AppShadow.btn : [],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: textColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── RESCHEDULE CARD ───────────────────────────
class _RescheduleCard extends StatelessWidget {
  final BookingModel booking;
  final bool isRescheduling;
  final Future<void> Function(BookingDetailItem) onReschedule;

  const _RescheduleCard({
    required this.booking,
    required this.isRescheduling,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ĐỔI LỊCH',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn slot muốn đổi, sau đó chọn giờ mới còn trống.',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...booking.details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.fieldName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${d.displayDate}  •  ${d.displayTime}',
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: isRescheduling ? null : () => onReschedule(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryUltraLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: isRescheduling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Text(
                              'Đổi giờ',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── RESCHEDULE SHEET ──────────────────────────
class _RescheduleSheet extends StatelessWidget {
  final String fieldName;
  final String currentTime;
  final List<SlotModel> slots;

  const _RescheduleSheet({
    required this.fieldName,
    required this.currentTime,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadH,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Giờ hiện tại: $currentTime',
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.fieldBorder),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height * 0.45 - bottomInset,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadH,
                  vertical: 12,
                ),
                itemCount: slots.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final slot = slots[i];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryUltraLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            slot.displayTime,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            slot.priceFmt,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── INVOICES SECTION ──────────────────────────────
// Hiển thị 1 hoặc 2 hóa đơn tuỳ theo số lượng payments đã thanh toán.
// Với Flow 1 (cọc + còn lại): 2 card riêng biệt, có label phân biệt.
// Với Flow 2 (full): 1 card duy nhất.
class _InvoicesSection extends StatelessWidget {
  final bool isLoading;
  final List<InvoiceModel> invoices;
  final Map<int, bool> isOpeningPdfMap;
  final Future<void> Function(int index) onView;
  final Future<void> Function(int paymentId) onOpenPdf;

  const _InvoicesSection({
    required this.isLoading,
    required this.invoices,
    required this.isOpeningPdfMap,
    required this.onView,
    required this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    // Chưa load hoặc chỉ có 1 hóa đơn — hiển thị card đơn giản
    if (invoices.length <= 1) {
      return _InvoiceCard(
        isLoading: isLoading,
        isOpeningPdf: invoices.isNotEmpty
            ? (isOpeningPdfMap[invoices.first.paymentId] ?? false)
            : false,
        invoice: invoices.isNotEmpty ? invoices.first : null,
        label: null,
        onView: () => onView(0),
        onOpenPdf: invoices.isNotEmpty
            ? () => onOpenPdf(invoices.first.paymentId)
            : () => onView(0),
      );
    }

    // 2 hóa đơn — Flow 1: cọc (index 0) + còn lại (index 1)
    return Column(
      children: [
        _InvoiceCard(
          isLoading: false,
          isOpeningPdf: isOpeningPdfMap[invoices[0].paymentId] ?? false,
          invoice: invoices[0],
          label: 'HÓA ĐƠN ĐẶT CỌC',
          labelColor: AppColors.warningOrange,
          labelBg: const Color(0xFFFFF3E0),
          onView: () => onView(0),
          onOpenPdf: () => onOpenPdf(invoices[0].paymentId),
        ),
        const SizedBox(height: 10),
        _InvoiceCard(
          isLoading: false,
          isOpeningPdf: isOpeningPdfMap[invoices[1].paymentId] ?? false,
          invoice: invoices[1],
          label: 'HÓA ĐƠN THANH TOÁN CÒN LẠI',
          labelColor: AppColors.badgeBookedText,
          labelBg: AppColors.badgeBookedBg,
          onView: () => onView(1),
          onOpenPdf: () => onOpenPdf(invoices[1].paymentId),
        ),
      ],
    );
  }
}

// ── INVOICE CARD ──────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final bool isLoading;
  final bool isOpeningPdf;
  final InvoiceModel? invoice;

  /// Nếu null → hiển thị label mặc định "HÓA ĐƠN THANH TOÁN"
  final String? label;
  final Color? labelColor;
  final Color? labelBg;
  final VoidCallback onView;
  final VoidCallback onOpenPdf;

  const _InvoiceCard({
    required this.isLoading,
    required this.isOpeningPdf,
    required this.invoice,
    required this.onView,
    required this.onOpenPdf,
    this.label,
    this.labelColor,
    this.labelBg,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? 'HÓA ĐƠN THANH TOÁN';
    return SpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF7C4DFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          effectiveLabel,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (label != null && labelBg != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: labelBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              invoice != null ? invoice!.amountFmt : '',
                              style: TextStyle(
                                color: labelColor ?? AppColors.textMid,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice != null
                          ? invoice!.invoiceCode
                          : 'Nhấn để xem hóa đơn',
                      style: TextStyle(
                        color: invoice != null
                            ? AppColors.textDark
                            : AppColors.textMid,
                        fontSize: 13.5,
                        fontWeight: invoice != null
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Quick info (khi đã load)
          if (invoice != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.fieldBorder),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InvoiceInfoCell(
                    label: 'Ngày thanh toán',
                    value: invoice!.paidAtFmt,
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvoiceInfoCell(
                    label: 'Tổng tiền',
                    value: invoice!.amountFmt,
                    icon: Icons.payments_outlined,
                    valueColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InvoiceInfoCell(
                    label: 'Phương thức',
                    value: invoice!.paymentMethod,
                    icon: Icons.credit_card_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InvoiceInfoCell(
                    label: 'Trạng thái',
                    value: invoice!.paymentStatus,
                    icon: Icons.check_circle_outline,
                    valueColor: AppColors.badgeBookedText,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _InvoiceActionBtn(
                  label: invoice != null ? 'Xem chi tiết' : 'Xem hóa đơn',
                  icon: Icons.visibility_outlined,
                  isLoading: isLoading && invoice == null,
                  onTap: onView,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InvoiceActionBtn(
                  label: 'Tải PDF',
                  icon: Icons.download_outlined,
                  isLoading: isOpeningPdf || (isLoading && invoice == null),
                  onTap: invoice != null ? onOpenPdf : onView,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceInfoCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InvoiceInfoCell({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isPrimary;
  final VoidCallback onTap;

  const _InvoiceActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isPrimary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary
        ? const Color(0xFF7C4DFF)
        : const Color(0xFFF3F0FF);
    final fgColor = isPrimary ? Colors.white : const Color(0xFF7C4DFF);
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary
              ? null
              : Border.all(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: fgColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fgColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── INVOICE SHEET ─────────────────────────────
class _InvoiceSheet extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isOpeningPdf;
  final VoidCallback onOpenPdf;

  const _InvoiceSheet({
    required this.invoice,
    required this.isOpeningPdf,
    required this.onOpenPdf,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fieldBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF7C4DFF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HÓA ĐƠN',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            invoice.invoiceCode,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // PDF button
                    GestureDetector(
                      onTap: isOpeningPdf ? null : onOpenPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isOpeningPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.download_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'PDF',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
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
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.fieldBorder),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
                  children: [
                    // Customer info
                    _SheetSection(
                      title: 'THÔNG TIN KHÁCH HÀNG',
                      child: Column(
                        children: [
                          _SheetRow('Họ tên', invoice.customerName),
                          const SizedBox(height: 8),
                          _SheetRow('Số điện thoại', invoice.customerPhone),
                          const SizedBox(height: 8),
                          _SheetRow('Email', invoice.customerEmail),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment info
                    _SheetSection(
                      title: 'THÔNG TIN THANH TOÁN',
                      child: Column(
                        children: [
                          _SheetRow('Ngày thanh toán', invoice.paidAtFmt),
                          const SizedBox(height: 8),
                          _SheetRow('Phương thức', invoice.paymentMethod),
                          const SizedBox(height: 8),
                          _SheetRow(
                            'Trạng thái',
                            invoice.paymentStatus,
                            valueColor: AppColors.badgeBookedText,
                          ),
                          if (invoice.transactionCode != null &&
                              invoice.transactionCode!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _SheetRow('Mã giao dịch', invoice.transactionCode!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Slot details
                    if (invoice.details.isNotEmpty) ...[
                      _SheetSection(
                        title: 'CHI TIẾT SLOT SÂN',
                        child: Column(
                          children: invoice.details
                              .map(
                                (d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryUltraLight,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.sports_soccer_outlined,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              d.fieldName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textDark,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            Text(
                                              '${d.displayDate}  •  ${d.displayTime}',
                                              style: const TextStyle(
                                                color: AppColors.textMid,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        d.priceFmt,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Services
                    if (invoice.services.isNotEmpty) ...[
                      _SheetSection(
                        title: 'DỊCH VỤ ĐI KÈM',
                        child: Column(
                          children: invoice.services
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${s.serviceName} ×${s.quantity}',
                                          style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        s.totalFmt,
                                        style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryUltraLight,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TỔNG THANH TOÁN',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            invoice.amountFmt,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Note
                    if (invoice.note != null && invoice.note!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SheetSection(
                        title: 'GHI CHÚ',
                        child: Text(
                          invoice.note!,
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _SheetSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SheetRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final VoidCallback onWriteReview;

  const _ReviewCard({required this.onWriteReview});

  @override
  Widget build(BuildContext context) {
    return SpCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.ratingGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá chuyến chơi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chia sẻ trải nghiệm của bạn về sân bóng',
                  style: TextStyle(color: AppColors.textMid, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onWriteReview,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Viết đánh giá',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── REVIEW SHEET ──────────────────────────────
class _ReviewSheet extends StatefulWidget {
  final bool isSubmitting;
  final Future<void> Function({
    required int rating,
    required String comment,
    String? imagePath,
  })
  onSubmit;

  const _ReviewSheet({required this.isSubmitting, required this.onSubmit});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(rating: _rating, comment: _commentCtrl.text);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đánh giá sân bóng',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.ratingGold,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              ['', 'Rất tệ', 'Tệ', 'Bình thường', 'Tốt', 'Xuất sắc'][_rating],
              style: const TextStyle(
                color: AppColors.ratingGold,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadH,
              ),
              child: TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhận xét của bạn về sân bóng (tuỳ chọn)',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadH,
              ),
              child: SpPrimaryButton(
                label: 'GỬI ĐÁNH GIÁ',
                isLoading: _isSubmitting,
                onTap: _submit,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
