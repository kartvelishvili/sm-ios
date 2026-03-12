import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../core/localization.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api;

  DashboardData? _data;
  bool _isLoading = false;
  String? _error;
  int? _selectedApartmentId;

  // ── Polling ──
  Timer? _pollTimer;
  static const _foregroundInterval = Duration(minutes: 1);
  static const _backgroundInterval = Duration(minutes: 5);
  bool _isForeground = true;

  // ── Tracking known state to detect changes ──
  Set<int> _knownApprovalIds = {};
  String? _lastPaymentStatus;     // e.g. "paid" / "unpaid"
  bool? _lastAccessState;         // has_access
  double? _lastTotalDebt;

  // ── Debt reminder cooldown (max 1 per day) ──
  DateTime? _lastDebtReminder;

  // ── LocaleProvider reference for translated notification text ──
  LocaleProvider? _locale;
  void setLocale(LocaleProvider l) => _locale = l;
  AppStrings get _s =>
      _locale?.s ?? const AppStrings.forLanguage(AppLanguage.ka);

  DashboardProvider(this._api);

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedApartmentId => _selectedApartmentId;

  // ──────────────────────────────────────────────
  //  Lifecycle-aware polling
  // ──────────────────────────────────────────────

  void startPolling() {
    _isForeground = true;
    _restartTimer();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Call from WidgetsBindingObserver when app goes to background/foreground.
  void setForeground(bool fg) {
    if (_isForeground == fg) return;
    _isForeground = fg;
    if (_pollTimer != null) _restartTimer();
    // When coming back to foreground, poll immediately
    if (fg) _pollDashboard();
  }

  void _restartTimer() {
    _pollTimer?.cancel();
    final interval = _isForeground ? _foregroundInterval : _backgroundInterval;
    _pollTimer = Timer.periodic(interval, (_) => _pollDashboard());
  }

  // ──────────────────────────────────────────────
  //  Silent background poll
  // ──────────────────────────────────────────────

  Future<void> _pollDashboard() async {
    try {
      final params = <String, dynamic>{};
      if (_selectedApartmentId != null) {
        params['apt'] = _selectedApartmentId;
      }
      final response =
          await _api.get('/dashboard/index.php', queryParams: params);

      if (response.success && response.data != null) {
        final newData =
            DashboardData.fromJson(response.data as Map<String, dynamic>);

        _checkNewApprovals(newData.pendingApprovals);
        _checkPaymentChange(newData);
        _checkAccessChange(newData);
        _checkDebtReminder(newData);

        _data = newData;
        _error = null;
        notifyListeners();
      }
    } catch (_) {
      // Silent fail — don't disrupt the user
    }
  }

  // ──────────────────────────────────────────────
  //  Change detection + notifications
  // ──────────────────────────────────────────────

  void _checkNewApprovals(List<PendingApproval> approvals) {
    final notifService = NotificationService();
    final newOnes = <PendingApproval>[];

    for (final approval in approvals) {
      if (!_knownApprovalIds.contains(approval.id)) {
        newOnes.add(approval);
      }
    }

    for (final approval in newOnes) {
      notifService.showApprovalRequest(
        title: _s.notifNewRequest(approval.apartmentNumber ?? ''),
        body: _s.notifRequestBody(approval.fullName),
        requestId: approval.id,
        totalNew: newOnes.length,
      );
    }

    _knownApprovalIds = approvals.map((a) => a.id).toSet();
  }

  String _paymentStatusKey(PaymentStatusInfo ps) =>
      ps.isFullyPaid ? 'paid' : ps.isPartiallyPaid ? 'partial' : 'unpaid';

  void _checkPaymentChange(DashboardData newData) {
    final newStatus = _paymentStatusKey(newData.paymentStatus);
    if (_lastPaymentStatus != null && _lastPaymentStatus != newStatus) {
      final notifService = NotificationService();
      if (newStatus == 'paid') {
        notifService.showPaymentNotification(
          title: _s.paymentSuccess,
          body: _s.paymentSuccessMsg,
          payload: 'payment:success',
        );
      } else if (_lastPaymentStatus == 'paid' && newStatus != 'paid') {
        notifService.showPaymentNotification(
          title: _s.payment,
          body: _s.unpaid,
          payload: 'payment:status_change',
        );
      }
    }
    _lastPaymentStatus = newStatus;
  }

  void _checkAccessChange(DashboardData newData) {
    final newAccess = newData.accessStatus.hasAccess;
    if (_lastAccessState != null && _lastAccessState != newAccess) {
      final notifService = NotificationService();
      if (!newAccess) {
        notifService.showAccessChange(
          title: _s.accessBlocked,
          body: newData.accessStatus.reason ?? _s.blockedUnpaid,
        );
      } else {
        notifService.showAccessChange(
          title: _s.accessActive,
          body: _s.paidActive,
        );
      }
    }
    _lastAccessState = newAccess;
  }

  void _checkDebtReminder(DashboardData newData) {
    if (newData.totalDebt <= 0) return;

    // Max 1 debt reminder per day
    final now = DateTime.now();
    if (_lastDebtReminder != null &&
        now.difference(_lastDebtReminder!).inHours < 24) {
      return;
    }

    // Only notify if debt has increased
    if (_lastTotalDebt != null && newData.totalDebt > _lastTotalDebt!) {
      final notifService = NotificationService();
      notifService.showDebtReminder(
        title: _s.debt,
        body: _s.debtTotal(newData.totalDebt.toStringAsFixed(2)),
      );
      _lastDebtReminder = now;
    }
    _lastTotalDebt = newData.totalDebt;
  }

  // ──────────────────────────────────────────────
  //  Public API
  // ──────────────────────────────────────────────

  Future<void> loadDashboard({int? apartmentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = <String, dynamic>{};
    if (apartmentId != null) {
      params['apt'] = apartmentId;
      _selectedApartmentId = apartmentId;
    }

    try {
      final response =
          await _api.get('/dashboard/index.php', queryParams: params);

      if (response.success && response.data != null) {
        final newData = DashboardData.fromJson(
            response.data as Map<String, dynamic>);

        // Seed known state on first load (don't notify on app start)
        if (_data == null) {
          _knownApprovalIds =
              newData.pendingApprovals.map((a) => a.id).toSet();
          _lastPaymentStatus = _paymentStatusKey(newData.paymentStatus);
          _lastAccessState = newData.accessStatus.hasAccess;
          _lastTotalDebt = newData.totalDebt;

          // Add existing pending approvals to notification history (silently)
          final notifService = NotificationService();
          for (final approval in newData.pendingApprovals) {
            notifService.addApprovalSilently(
              title: _s.notifNewRequest(approval.apartmentNumber ?? ''),
              body: _s.notifRequestBody(approval.fullName),
              requestId: approval.id,
            );
          }
        } else {
          _checkNewApprovals(newData.pendingApprovals);
          _checkPaymentChange(newData);
          _checkAccessChange(newData);
          _checkDebtReminder(newData);
        }

        _data = newData;
        _error = null;
      } else {
        _error = response.message ?? _s.loadDashboardFailed;
      }
    } catch (e) {
      _error = _s.loadDashboardFailedRetry;
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectApartment(int apartmentId) {
    _selectedApartmentId = apartmentId;
    loadDashboard(apartmentId: apartmentId);
  }

  void clearData() {
    _data = null;
    _error = null;
    _selectedApartmentId = null;
    _knownApprovalIds = {};
    _lastPaymentStatus = null;
    _lastAccessState = null;
    _lastTotalDebt = null;
    _lastDebtReminder = null;
    stopPolling();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}