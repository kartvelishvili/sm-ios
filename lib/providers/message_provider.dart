import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/api_client.dart';

class MessageProvider extends ChangeNotifier {
  final ApiClient _api;

  List<MessageItem> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  // Thread
  MessageThread? _currentThread;
  bool _threadLoading = false;
  String? _threadError;
  bool _sending = false;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _loadingMore = false;

  MessageProvider(this._api);

  List<MessageItem> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  MessageThread? get currentThread => _currentThread;
  bool get threadLoading => _threadLoading;
  String? get threadError => _threadError;
  bool get sending => _sending;
  bool get hasMore => _currentPage < _totalPages;

  Future<void> loadMessages({bool refresh = false}) async {
    if (refresh) _currentPage = 1;
    if (_currentPage == 1) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _api.get('/messages/list.php', queryParams: {
        'page': _currentPage,
        'per_page': 20,
      });

      if (response.success && response.data != null) {
        final list = (response.data as List)
            .map((m) => MessageItem.fromJson(m as Map<String, dynamic>))
            .toList();

        if (_currentPage == 1) {
          _messages = list;
        } else {
          _messages.addAll(list);
        }

        if (response.pagination != null) {
          _totalPages = response.pagination!['total_pages'] as int? ?? 1;
        }
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'შეტყობინებების ჩატვირთვა ვერ მოხერხდა';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    _currentPage++;
    await loadMessages();
    _loadingMore = false;
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _api.get('/messages/unread-count.php');
      if (response.success && response.data != null) {
        _unreadCount = (response.data as Map<String, dynamic>)['unread_count'] as int? ?? 0;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadThread(int messageId, {int? afterId}) async {
    if (afterId == null) {
      _threadLoading = true;
      _threadError = null;
      notifyListeners();
    }

    try {
      final params = <String, dynamic>{'message_id': messageId};
      if (afterId != null) params['after_id'] = afterId;

      final response = await _api.get('/messages/thread.php', queryParams: params);

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (afterId != null && _currentThread != null) {
          // Append new replies
          final newReplies = (data['replies'] as List?)
                  ?.map((r) => MessageReply.fromJson(r as Map<String, dynamic>))
                  .toList() ??
              [];
          if (newReplies.isNotEmpty) {
            _currentThread = MessageThread(
              message: _currentThread!.message,
              replies: [..._currentThread!.replies, ...newReplies],
            );
          }
        } else {
          _currentThread = MessageThread.fromJson(data);
        }
      } else {
        _threadError = response.message;
      }
    } catch (e) {
      if (afterId == null) _threadError = 'ჩატვირთვა ვერ მოხერხდა';
    }

    _threadLoading = false;
    notifyListeners();
  }

  Future<bool> sendReply(int messageId, String body) async {
    _sending = true;
    notifyListeners();

    try {
      final response = await _api.post('/messages/reply.php', data: {
        'message_id': messageId,
        'body': body,
      });

      if (response.success && response.data != null) {
        final replyData = (response.data as Map<String, dynamic>)['reply'] as Map<String, dynamic>?;
        if (replyData != null && _currentThread != null) {
          _currentThread = MessageThread(
            message: _currentThread!.message,
            replies: [
              ..._currentThread!.replies,
              MessageReply.fromJson(replyData),
            ],
          );
        }
        _sending = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _sending = false;
    notifyListeners();
    return false;
  }

  Future<void> markRead(int messageId) async {
    try {
      await _api.post('/messages/mark-read.php', data: {
        'message_id': messageId,
      });
      // Update local state
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1 && _messages[idx].hasUnread) {
        loadUnreadCount();
        loadMessages(refresh: true);
      }
    } catch (_) {}
  }

  void clearThread() {
    _currentThread = null;
    _threadError = null;
  }
}
