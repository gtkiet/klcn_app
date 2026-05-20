// lib/screens/notification/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _svc = NotificationService.instance;
  final _scrollCtrl = ScrollController();

  List<NotificationModel> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  int _page = 1;
  String? _errorMsg;

  // Optimistic unread count cho badge header
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load(refresh: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  // ── Load / refresh ─────────────────────────────────────────────

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
        _page = 1;
      });
    }

    try {
      final result = await _svc.getNotifications(page: _page, pageSize: 20);
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _items = result.items;
        } else {
          _items = [..._items, ...result.items];
        }
        _hasNextPage = result.hasNextPage;
        _unreadCount = _items.where((n) => !n.isRead).length;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    try {
      final result = await _svc.getNotifications(page: _page, pageSize: 20);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _hasNextPage = result.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _page--;
        _isLoadingMore = false;
      });
    }
  }

  // ── Mark single read (optimistic) ──────────────────────────────

  Future<void> _markRead(NotificationModel notif) async {
    if (notif.isRead) {
      _navigateToRef(notif);
      return;
    }

    // Optimistic update
    setState(() {
      final idx = _items.indexWhere(
        (n) => n.notificationId == notif.notificationId,
      );
      if (idx != -1) {
        _items = [..._items];
        _items[idx] = _items[idx].markRead();
        _unreadCount = (_unreadCount - 1).clamp(0, _items.length);
      }
    });

    try {
      await _svc.markAsRead(notif.notificationId);
    } catch (_) {
      // Rollback nếu API lỗi
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere(
          (n) => n.notificationId == notif.notificationId,
        );
        if (idx != -1) {
          _items = [..._items];
          _items[idx] = NotificationModel(
            notificationId: notif.notificationId,
            title: notif.title,
            body: notif.body,
            type: notif.type,
            refId: notif.refId,
            isRead: false,
            createdAt: notif.createdAt,
          );
          _unreadCount = _items.where((n) => !n.isRead).length;
        }
      });
    }

    _navigateToRef(notif);
  }

  // ── Mark all read ───────────────────────────────────────────────

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;

    // Optimistic update
    setState(() {
      _items = _items.map((n) => n.isRead ? n : n.markRead()).toList();
      _unreadCount = 0;
    });

    try {
      await _svc.markAllAsRead();
    } catch (e) {
      if (!mounted) return;
      // Rollback đơn giản: reload lại từ server
      _load(refresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  // ── Navigate to booking detail if refId exists ──────────────────

  void _navigateToRef(NotificationModel notif) {
    if (notif.refId == null) return;
    if (notif.type == 'booking' || notif.type == 'payment') {
      context.push(
        '/booking_history/detail',
        extra: {'bookingId': notif.refId},
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Thông báo'),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.errorRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Đọc tất cả',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMsg != null && _items.isEmpty) {
      return _ErrorView(
        message: _errorMsg!,
        onRetry: () => _load(refresh: true),
      );
    }

    if (_items.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }
          final notif = _items[i];
          return _NotificationTile(notif: notif, onTap: () => _markRead(notif));
        },
      ),
    );
  }
}

// ── NOTIFICATION TILE ─────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;

  const _NotificationTile({required this.notif, required this.onTap});

  // Icon + màu theo type
  (IconData, Color) get _typeStyle => switch (notif.type) {
    'booking' => (Icons.sports_soccer_rounded, AppColors.primary),
    'payment' => (Icons.payment_rounded, AppColors.infoBlue),
    'system' => (Icons.campaign_rounded, AppColors.warningOrange),
    _ => (Icons.notifications_rounded, AppColors.textMid),
  };

  String get _timeAgo {
    final diff = DateTime.now().difference(notif.createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    final d = notif.createdAt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeStyle;
    final isUnread = !notif.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.primaryUltraLight.withValues(alpha: 0.6)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadH,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon badge ─────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),

            // ── Content ────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Body
                  Text(
                    notif.body,
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Timestamp
                  Text(
                    _timeAgo,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11.5,
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

// ── EMPTY VIEW ────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Các thông báo về đặt sân và\nthanh toán sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ERROR VIEW ────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMid, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
