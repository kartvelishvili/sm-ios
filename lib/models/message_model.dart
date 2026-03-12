class MessageItem {
  final int id;
  final String subject;
  final String body;
  final String senderName;
  final String senderType;
  final String recipientType;
  final String status;
  final bool isRead;
  final String? readAt;
  final int replyCount;
  final int unreadReplies;
  final String? lastReplyBody;
  final String? lastReplyAt;
  final bool canReply;
  final String createdAt;

  MessageItem({
    required this.id,
    required this.subject,
    required this.body,
    required this.senderName,
    this.senderType = 'admin',
    this.recipientType = 'user',
    this.status = 'open',
    this.isRead = false,
    this.readAt,
    this.replyCount = 0,
    this.unreadReplies = 0,
    this.lastReplyBody,
    this.lastReplyAt,
    this.canReply = true,
    required this.createdAt,
  });

  bool get isClosed => status == 'closed';
  bool get hasUnread => !isRead || unreadReplies > 0;

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? 'admin',
      recipientType: json['recipient_type'] as String? ?? 'user',
      status: json['status'] as String? ?? 'open',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      readAt: json['read_at'] as String?,
      replyCount: json['reply_count'] as int? ?? 0,
      unreadReplies: json['unread_replies'] as int? ?? 0,
      lastReplyBody: json['last_reply_body'] as String?,
      lastReplyAt: json['last_reply_at'] as String?,
      canReply: json['can_reply'] == true,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class MessageThread {
  final MessageDetail message;
  final List<MessageReply> replies;

  MessageThread({required this.message, required this.replies});

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      message: MessageDetail.fromJson(
          json['message'] as Map<String, dynamic>? ?? {}),
      replies: (json['replies'] as List?)
              ?.map((r) => MessageReply.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MessageDetail {
  final int id;
  final String subject;
  final String body;
  final String senderName;
  final String senderType;
  final String recipientType;
  final String status;
  final bool canReply;
  final String createdAt;
  final String? closedAt;

  MessageDetail({
    required this.id,
    required this.subject,
    required this.body,
    required this.senderName,
    this.senderType = 'admin',
    this.recipientType = 'user',
    this.status = 'open',
    this.canReply = true,
    required this.createdAt,
    this.closedAt,
  });

  bool get isClosed => status == 'closed';

  factory MessageDetail.fromJson(Map<String, dynamic> json) {
    return MessageDetail(
      id: json['id'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      senderName: json['sender_name'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? 'admin',
      recipientType: json['recipient_type'] as String? ?? 'user',
      status: json['status'] as String? ?? 'open',
      canReply: json['can_reply'] == true,
      createdAt: json['created_at'] as String? ?? '',
      closedAt: json['closed_at'] as String?,
    );
  }
}

class MessageReply {
  final int id;
  final String senderType;
  final String senderName;
  final String body;
  final String createdAt;

  MessageReply({
    required this.id,
    required this.senderType,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  bool get isAdmin => senderType == 'admin';

  factory MessageReply.fromJson(Map<String, dynamic> json) {
    return MessageReply(
      id: json['id'] as int? ?? 0,
      senderType: json['sender_type'] as String? ?? 'user',
      senderName: json['sender_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
