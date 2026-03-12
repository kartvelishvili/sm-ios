import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/notification_service.dart';
import '../../providers/message_provider.dart';
import '../messages/message_thread_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    NotificationService().addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages(refresh: true);
    });
  }

  @override
  void dispose() {
    NotificationService().removeListener(_onUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final service = NotificationService();
    final msgProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifTitle),
        actions: [
          if (service.history.isNotEmpty && _tabController.index == 0)
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
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.adaptiveTextMuted(context),
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(s.notifTitle),
                  if (service.unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${service.unreadCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(s.navMessages),
                  if (msgProvider.unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${msgProvider.unreadCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Notifications
          _NotificationsTab(),
          // Tab 2: Messages
          _MessagesTab(),
        ],
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

// ─── Notifications Tab ───
class _NotificationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final items = NotificationService().history;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none,
                size: 64, color: AppColors.adaptiveTextMuted(context)),
            const SizedBox(height: 12),
            Text(
              s.notifEmpty,
              style:
                  TextStyle(color: AppColors.adaptiveTextSecondary(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final n = items[i];
        final isUnread = !n.read;
        final icon = _iconForType(n.type);
        final color = _colorForType(n.type);
        final timeAgo = _formatTimeAgo(n.createdAt, context);

        return Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppColors.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) =>
              NotificationService().removeNotification(n.id),
          child: InkWell(
            onTap: () {
              if (isUnread) NotificationService().markRead(n.id);
              _navigateForPayload(context, n.payload);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w500,
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
                                color:
                                    AppColors.adaptiveTextMuted(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.adaptiveTextSecondary(
                                context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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
      },
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
    }
  }
}

// ─── Messages Tab ───
class _MessagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final s = AppStrings.of(context);

    if (provider.isLoading && provider.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(provider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadMessages(refresh: true),
              child: Text(s.retryBtn),
            ),
          ],
        ),
      );
    }

    if (provider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline_rounded,
                size: 64, color: AppColors.adaptiveTextMuted(context)),
            const SizedBox(height: 16),
            Text(s.messagesEmpty,
                style: TextStyle(
                    color: AppColors.adaptiveTextMuted(context))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMessages(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.pixels >=
                  scroll.metrics.maxScrollExtent - 200 &&
              provider.hasMore) {
            provider.loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final msg = provider.messages[index];
            return _InboxMessageTile(
              message: msg,
              onTap: () {
                provider.clearThread();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MessageThreadScreen(messageId: msg.id),
                  ),
                ).then((_) {
                  provider.loadMessages(refresh: true);
                  provider.loadUnreadCount();
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class _InboxMessageTile extends StatelessWidget {
  final dynamic message;
  final VoidCallback onTap;

  const _InboxMessageTile({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final hasUnread = message.hasUnread;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.primary.withAlpha(8)
              : AppColors.adaptiveSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withAlpha(40)
                : AppColors.adaptiveBorder(context),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _typeColor(message.recipientType).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mail_outline,
                size: 18,
                color: _typeColor(message.recipientType),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hasUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          message.subject,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.adaptiveTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.replyCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.repliesCount(message.replyCount),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.adaptiveTextMuted(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'direct':
        return AppColors.info;
      case 'complex':
        return AppColors.accent;
      default:
        return AppColors.success;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${d.day}.${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
