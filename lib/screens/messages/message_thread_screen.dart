import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../models/message_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class MessageThreadScreen extends StatefulWidget {
  final int messageId;

  const MessageThreadScreen({super.key, required this.messageId});

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessageProvider>();
      provider.loadThread(widget.messageId);
      provider.markRead(widget.messageId);
    });
    // Poll for new replies every 7 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      final provider = context.read<MessageProvider>();
      final thread = provider.currentThread;
      if (thread != null && thread.replies.isNotEmpty) {
        provider.loadThread(widget.messageId,
            afterId: thread.replies.last.id);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;

    final provider = context.read<MessageProvider>();
    final success = await provider.sendReply(widget.messageId, body);
    if (success) {
      _replyController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).messageSendFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    final thread = provider.currentThread;
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          thread?.message.subject ?? s.messagesTitle,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: provider.threadLoading && thread == null
          ? const Center(child: CircularProgressIndicator())
          : provider.threadError != null && thread == null
              ? Center(child: Text(provider.threadError!))
              : thread == null
                  ? const SizedBox()
                  : Column(
                      children: [
                        // Messages list
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: 1 + thread.replies.length,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _OriginalMessageBubble(
                                    message: thread.message);
                              }
                              return _ReplyBubble(
                                  reply: thread.replies[index - 1]);
                            },
                          ),
                        ),

                        // Reply input or closed indicator
                        if (thread.message.canReply && !thread.message.isClosed)
                          _ReplyInput(
                            controller: _replyController,
                            sending: provider.sending,
                            onSend: _sendReply,
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: AppColors.adaptiveSurface(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    size: 16,
                                    color: AppColors.adaptiveTextMuted(context)),
                                const SizedBox(width: 8),
                                Text(
                                  s.messageTicketClosed,
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextMuted(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _OriginalMessageBubble extends StatelessWidget {
  final MessageDetail message;

  const _OriginalMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.info.withAlpha(25),
                child: Icon(Icons.admin_panel_settings_rounded,
                    size: 16, color: AppColors.info),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.info,
                  ),
                ),
              ),
              Text(
                _formatDateTime(message.createdAt),
                style: TextStyle(
                  color: AppColors.adaptiveTextMuted(context),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.body,
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _ReplyBubble extends StatelessWidget {
  final MessageReply reply;

  const _ReplyBubble({required this.reply});

  @override
  Widget build(BuildContext context) {
    final isAdmin = reply.isAdmin;
    final alignment =
        isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final color = isAdmin
        ? AppColors.adaptiveSurface(context)
        : AppColors.primary.withAlpha(15);
    final borderColor =
        isAdmin ? AppColors.adaptiveBorder(context) : AppColors.primary.withAlpha(40);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reply.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isAdmin
                            ? AppColors.info
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(reply.createdAt),
                      style: TextStyle(
                        color: AppColors.adaptiveTextMuted(context),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reply.body,
                  style: TextStyle(
                    color: AppColors.adaptiveTextPrimary(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ReplyInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.adaptiveSurface(context),
        border: Border(
          top: BorderSide(
            color: AppColors.adaptiveBorder(context).withAlpha(80),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: s.messageWriteReply,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
