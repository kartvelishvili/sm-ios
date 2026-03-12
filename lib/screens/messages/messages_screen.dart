import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import 'message_thread_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.messagesTitle)),
      body: provider.isLoading && provider.messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                )
              : provider.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline_rounded,
                              size: 64,
                              color: AppColors.adaptiveTextMuted(context)),
                          const SizedBox(height: 16),
                          Text(s.messagesEmpty,
                              style: TextStyle(
                                  color: AppColors.adaptiveTextMuted(context))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            final msg = provider.messages[index];
                            return _MessageTile(
                              message: msg,
                              onTap: () => _openThread(msg.id),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }

  void _openThread(int messageId) {
    final provider = context.read<MessageProvider>();
    provider.clearThread();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageThreadScreen(messageId: messageId),
      ),
    ).then((_) {
      provider.loadMessages(refresh: true);
      provider.loadUnreadCount();
    });
  }
}

class _MessageTile extends StatelessWidget {
  final dynamic message;
  final VoidCallback onTap;

  const _MessageTile({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final hasUnread = message.hasUnread;

    String typeLabel;
    Color typeColor;
    switch (message.recipientType) {
      case 'user':
        typeLabel = s.messageDirectLabel;
        typeColor = AppColors.info;
        break;
      case 'complex':
        typeLabel = s.messageComplexLabel;
        typeColor = AppColors.primary;
        break;
      default:
        typeLabel = s.messageAllLabel;
        typeColor = AppColors.adaptiveTextMuted(context);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: hasUnread
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                )
              : null,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: type badge + time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (message.isClosed) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.lock_rounded, size: 12,
                        color: AppColors.adaptiveTextMuted(context)),
                  ],
                  const Spacer(),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.unreadLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(message.lastReplyAt ?? message.createdAt),
                    style: TextStyle(
                      color: AppColors.adaptiveTextMuted(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Subject
              Text(
                message.subject,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Preview body
              Text(
                message.lastReplyBody ?? message.body,
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (message.replyCount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  s.repliesCount(message.replyCount),
                  style: TextStyle(
                    color: AppColors.adaptiveTextMuted(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'ახლა';
      if (diff.inHours < 1) return '${diff.inMinutes} წთ';
      if (diff.inDays < 1) return '${diff.inHours} სთ';
      if (diff.inDays < 7) return '${diff.inDays} დღე';

      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
