import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/api_client.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiClient _api;

  List<PaymentItem> _history = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isProcessing = false;

  PaymentProvider(this._api);

  List<PaymentItem> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isProcessing => _isProcessing;
  bool get hasMore => _currentPage < _totalPages;

  // --- Payment History ---
  Future<void> loadHistory({
    int page = 1,
    int perPage = 20,
    int? apartmentId,
    String? status,
    bool append = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (apartmentId != null) params['apartment_id'] = apartmentId;
    if (status != null) params['status'] = status;

    final response =
        await _api.get('/payments/history.php', queryParams: params);

    if (response.success && response.data != null) {
      final items = (response.data as List)
          .map((p) => PaymentItem.fromJson(p as Map<String, dynamic>))
          .toList();

      if (append) {
        _history.addAll(items);
      } else {
        _history = items;
      }

      if (response.pagination != null) {
        _currentPage = response.pagination!['page'] as int? ?? 1;
        _totalPages = response.pagination!['total_pages'] as int? ?? 1;
      }
    } else {
      _error = response.message ?? 'ისტორიის ჩატვირთვა ვერ მოხერხდა';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || _isLoading) return;
    await loadHistory(page: _currentPage + 1, append: true);
  }

  // --- Process Payment ---
  Future<PaymentProcessResult?> processPayment(List<String> months) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    final response = await _api.post('/payments/process.php', data: {
      'months': months,
    });

    _isProcessing = false;

    if (response.success && response.data != null) {
      final result = PaymentProcessResult.fromJson(
          response.data as Map<String, dynamic>);
      notifyListeners();
      return result;
    } else {
      _error = response.message ?? 'გადახდის ინიცირება ვერ მოხერხდა';
      notifyListeners();
      return null;
    }
  }

  // --- Check Payment Status ---
  Future<Map<String, dynamic>?> checkStatus(String orderId) async {
    final response = await _api.get('/payments/status.php',
        queryParams: {'order_id': orderId});

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
