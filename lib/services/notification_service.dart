import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Notification types ───
enum NotifType { approval, payment, debt, access, general }

// ─── In-app notification model ───
class AppNotification {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final String? payload;
  final DateTime createdAt;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    required this.createdAt,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotifType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotifType.general,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      payload: json['payload'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] == true,
    );
  }
}

/// Full-featured notification service with in-app history, rich OS
/// notifications, grouping, vibration patterns, and tap-to-navigate.
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── In-app notification history ──
  static const _kHistoryKey = 'notification_history';
  static const _maxHistory = 50;
  List<AppNotification> _history = [];
  List<AppNotification> get history => List.unmodifiable(_history);
  int get unreadCount => _history.where((n) => !n.read).length;

  // ── Tap handling ──
  String? _pendingPayload;
  String? consumePendingPayload() {
    final p = _pendingPayload;
    _pendingPayload = null;
    return p;
  }

  // ── Listeners (for badge count updates) ──
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  /// Initialize plugin + load history from SharedPreferences.
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _loadHistory();
    _initialized = true;
    debugPrint(
        'NotificationService initialized (${_history.length} history items)');
  }

  void _onTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    _pendingPayload = response.payload;

    // Mark matching notification as read
    if (response.payload != null) {
      for (final n in _history) {
        if (n.payload == response.payload && !n.read) {
          n.read = true;
          break;
        }
      }
      _saveHistory();
      _notify();
    }
  }

  // ──────────────────────────────────────────────
  //  Channel definitions (rich)
  // ──────────────────────────────────────────────
  static const _goldColor = Color(0xFFD4AF37);

  AndroidNotificationDetails _approvalDetails({bool grouped = false}) {
    return AndroidNotificationDetails(
      'approval_requests',
      'Approval Requests',
      channelDescription: 'New apartment registration requests',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: _goldColor,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      enableLights: true,
      ledColor: _goldColor,
      ledOnMs: 1000,
      ledOffMs: 500,
      category: AndroidNotificationCategory.social,
      groupKey: grouped ? 'approval_group' : null,
    );
  }

  AndroidNotificationDetails _approvalGroupSummary(int count) {
    return AndroidNotificationDetails(
      'approval_requests',
      'Approval Requests',
      channelDescription: 'New apartment registration requests',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: _goldColor,
      groupKey: 'approval_group',
      setAsGroupSummary: true,
      styleInformation: InboxStyleInformation(
        [],
        contentTitle: '$count new requests',
        summaryText: 'SmartLuxy',
      ),
    );
  }

  static final _paymentDetails = AndroidNotificationDetails(
    'payments',
    'Payments',
    channelDescription: 'Payment notifications',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: const Color(0xFF4CAF50),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
    enableLights: true,
    ledColor: const Color(0xFF4CAF50),
    ledOnMs: 1000,
    ledOffMs: 500,
    category: AndroidNotificationCategory.status,
  );

  static final _debtDetails = AndroidNotificationDetails(
    'debt_reminders',
    'Debt Reminders',
    channelDescription: 'Outstanding debt reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: const Color(0xFFFF5722),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 400, 200, 400, 200, 400]),
    enableLights: true,
    ledColor: const Color(0xFFFF5722),
    ledOnMs: 1000,
    ledOffMs: 500,
    category: AndroidNotificationCategory.reminder,
  );

  static final _accessDetails = AndroidNotificationDetails(
    'access_changes',
    'Access Changes',
    channelDescription: 'Door/elevator access status changes',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    color: const Color(0xFFFF9800),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 300, 500]),
    enableLights: true,
    ledColor: const Color(0xFFFF9800),
    ledOnMs: 1000,
    ledOffMs: 500,
    category: AndroidNotificationCategory.status,
  );

  static const _generalDetails = AndroidNotificationDetails(
    'general',
    'General',
    channelDescription: 'General notifications',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
    color: _goldColor,
  );

  // ──────────────────────────────────────────────
  //  Public show methods
  // ──────────────────────────────────────────────
  int _nextId = 1000;
  int _genId() => _nextId++;

  /// Add a pending approval to history silently (no OS notification).
  /// Returns true if added, false if duplicate.
  bool addApprovalSilently({
    required String title,
    required String body,
    required int requestId,
  }) {
    final notifId = 'approval_$requestId';
    if (_history.any((n) => n.id == notifId)) return false;

    _addToHistory(AppNotification(
      id: notifId,
      type: NotifType.approval,
      title: title,
      body: body,
      payload: 'approval:$requestId',
      createdAt: DateTime.now(),
    ));
    return true;
  }

  /// Show approval request notification (rich grouped style).
  Future<void> showApprovalRequest({
    required String title,
    required String body,
    int? requestId,
    int totalNew = 1,
  }) async {
    final id = requestId ?? _genId();
    final grouped = totalNew > 1;
    final details = _approvalDetails(grouped: grouped);

    final richDetails = AndroidNotificationDetails(
      details.channelId,
      details.channelName,
      channelDescription: details.channelDescription,
      importance: details.importance,
      priority: details.priority,
      icon: details.icon,
      color: details.color,
      enableVibration: details.enableVibration ?? true,
      vibrationPattern: details.vibrationPattern,
      enableLights: details.enableLights ?? true,
      ledColor: details.ledColor ?? _goldColor,
      ledOnMs: details.ledOnMs ?? 1000,
      ledOffMs: details.ledOffMs ?? 500,
      category: details.category,
      groupKey: details.groupKey,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: richDetails),
      payload: 'approval:$id',
    );

    if (grouped) {
      await _plugin.show(
        9999,
        'SmartLuxy',
        '$totalNew new requests',
        NotificationDetails(android: _approvalGroupSummary(totalNew)),
      );
    }

    _addToHistory(AppNotification(
      id: 'approval_$id',
      type: NotifType.approval,
      title: title,
      body: body,
      payload: 'approval:$id',
      createdAt: DateTime.now(),
    ));
  }

  /// Show payment status change notification.
  Future<void> showPaymentNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = _genId();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _paymentDetails.channelId,
          _paymentDetails.channelName,
          channelDescription: _paymentDetails.channelDescription,
          importance: _paymentDetails.importance,
          priority: _paymentDetails.priority,
          icon: _paymentDetails.icon,
          color: _paymentDetails.color,
          enableVibration: _paymentDetails.enableVibration ?? true,
          vibrationPattern: _paymentDetails.vibrationPattern,
          enableLights: _paymentDetails.enableLights ?? true,
          ledColor: _paymentDetails.ledColor ?? _goldColor,
          ledOnMs: _paymentDetails.ledOnMs ?? 1000,
          ledOffMs: _paymentDetails.ledOffMs ?? 500,
          category: _paymentDetails.category,
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        ),
      ),
      payload: payload ?? 'payment:$id',
    );

    _addToHistory(AppNotification(
      id: 'payment_$id',
      type: NotifType.payment,
      title: title,
      body: body,
      payload: payload ?? 'payment:$id',
      createdAt: DateTime.now(),
    ));
  }

  /// Show debt reminder notification.
  Future<void> showDebtReminder({
    required String title,
    required String body,
    String? apartmentNumber,
  }) async {
    final id = _genId();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _debtDetails.channelId,
          _debtDetails.channelName,
          channelDescription: _debtDetails.channelDescription,
          importance: _debtDetails.importance,
          priority: _debtDetails.priority,
          icon: _debtDetails.icon,
          color: _debtDetails.color,
          enableVibration: _debtDetails.enableVibration ?? true,
          vibrationPattern: _debtDetails.vibrationPattern,
          enableLights: _debtDetails.enableLights ?? true,
          ledColor: _debtDetails.ledColor ?? const Color(0xFFFF5722),
          ledOnMs: _debtDetails.ledOnMs ?? 1000,
          ledOffMs: _debtDetails.ledOffMs ?? 500,
          category: _debtDetails.category,
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        ),
      ),
      payload: 'debt:${apartmentNumber ?? id}',
    );

    _addToHistory(AppNotification(
      id: 'debt_$id',
      type: NotifType.debt,
      title: title,
      body: body,
      payload: 'debt:${apartmentNumber ?? id}',
      createdAt: DateTime.now(),
    ));
  }

  /// Show access status change notification.
  Future<void> showAccessChange({
    required String title,
    required String body,
  }) async {
    final id = _genId();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: _accessDetails),
      payload: 'access:$id',
    );

    _addToHistory(AppNotification(
      id: 'access_$id',
      type: NotifType.access,
      title: title,
      body: body,
      payload: 'access:$id',
      createdAt: DateTime.now(),
    ));
  }

  /// Show generic notification.
  Future<void> showGeneral({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = _genId();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: _generalDetails),
      payload: payload,
    );

    _addToHistory(AppNotification(
      id: 'general_$id',
      type: NotifType.general,
      title: title,
      body: body,
      payload: payload,
      createdAt: DateTime.now(),
    ));
  }

  // ──────────────────────────────────────────────
  //  History management
  // ──────────────────────────────────────────────
  void _addToHistory(AppNotification notif) {
    _history.insert(0, notif);
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }
    _saveHistory();
    _notify();
  }

  void markAllRead() {
    bool changed = false;
    for (final n in _history) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) {
      _saveHistory();
      _notify();
    }
  }

  void markRead(String notifId) {
    for (final n in _history) {
      if (n.id == notifId && !n.read) {
        n.read = true;
        _saveHistory();
        _notify();
        break;
      }
    }
  }

  void clearHistory() {
    _history.clear();
    _saveHistory();
    _notify();
  }

  void removeNotification(String notifId) {
    _history.removeWhere((n) => n.id == notifId);
    _saveHistory();
    _notify();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHistoryKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _history = list
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load notification history: $e');
      _history = [];
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_history.map((n) => n.toJson()).toList());
      await prefs.setString(_kHistoryKey, raw);
    } catch (e) {
      debugPrint('Failed to save notification history: $e');
    }
  }

  /// Cancel all OS notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
