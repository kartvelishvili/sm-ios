import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService().addListener(_onUpdate);
  }

  @override
  void dispose() {
    NotificationService().removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final service = NotificationService();
    final items = service.history;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(s.notifTitle),
            if (service.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${service.unreadCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'read') {
                  service.markAllRead();
                } else if (val == 'clear') {
                  _confirmClear(context, service, s);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all, size: 18),
                      const SizedBox(width: 8),
                      Text(s.notifMarkAllRead),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, size: 18),
                      const SizedBox(width: 8),
                      Text(s.notifClearAll),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: AppColors.adaptiveTextMuted(context)),
                  const SizedBox(height: 12),
                  Text(
                    s.notifEmpty,
                    style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) =>
                  _NotificationTile(notification: items[i]),
            ),
    );
  }

  void _confirmClear(
      BuildContext context, NotificationService service, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.notifClearAll),
        content: Text(s.notifClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              service.clearHistory();
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.notifClearAll),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final icon = _iconForType(notification.type);
    final color = _colorForType(notification.type);
    final timeAgo = _formatTimeAgo(notification.createdAt, context);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        NotificationService().removeNotification(notification.id);
      },
      child: InkWell(
        onTap: () {
          if (isUnread) {
            NotificationService().markRead(notification.id);
          }
          _navigateForPayload(context, notification.payload);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.primary.withAlpha(12)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isUnread ? color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.adaptiveTextMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.adaptiveTextSecondary(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(NotifType type) {
    switch (type) {
      case NotifType.approval:
        return Icons.person_add;
      case NotifType.payment:
        return Icons.payment;
      case NotifType.debt:
        return Icons.warning_amber;
      case NotifType.access:
        return Icons.lock_open;
      case NotifType.general:
        return Icons.notifications;
    }
  }

  Color _colorForType(NotifType type) {
    switch (type) {
      case NotifType.approval:
        return AppColors.primary;
      case NotifType.payment:
        return AppColors.success;
      case NotifType.debt:
        return const Color(0xFFFF5722);
      case NotifType.access:
        return const Color(0xFFFF9800);
      case NotifType.general:
        return AppColors.info;
    }
  }

  String _formatTimeAgo(DateTime dt, BuildContext context) {
    final diff = DateTime.now().difference(dt);
    final s = AppStrings.of(context);
    if (diff.inMinutes < 1) return s.notifJustNow;
    if (diff.inMinutes < 60) return s.notifMinsAgo(diff.inMinutes);
    if (diff.inHours < 24) return s.notifHoursAgo(diff.inHours);
    if (diff.inDays < 7) return s.notifDaysAgo(diff.inDays);
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }

  void _navigateForPayload(BuildContext context, String? payload) {
    if (payload == null) return;
    if (payload.startsWith('approval:')) {
      Navigator.of(context).pushNamed('/residents');
    } else if (payload.startsWith('payment:')) {
      // Could navigate to payment history
    }
    // For other types, just marking read is enough
  }
}
