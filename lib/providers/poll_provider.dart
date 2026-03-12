import 'package:flutter/material.dart';
import '../models/poll_model.dart';
import '../services/api_client.dart';

class PollProvider extends ChangeNotifier {
  final ApiClient _api;

  List<PollItem> _polls = [];
  bool _isLoading = false;
  String? _error;

  // Detail
  PollDetail? _currentPoll;
  bool _detailLoading = false;
  String? _detailError;
  bool _voting = false;

  PollProvider(this._api);

  List<PollItem> get polls => _polls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PollDetail? get currentPoll => _currentPoll;
  bool get detailLoading => _detailLoading;
  String? get detailError => _detailError;
  bool get voting => _voting;

  List<PollItem> get activePolls => _polls.where((p) => p.isActive).toList();
  List<PollItem> get endedPolls => _polls.where((p) => p.isEnded).toList();

  Future<void> loadPolls({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;

      final response = await _api.get('/polls/list.php', queryParams: params);

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _polls = (data['polls'] as List?)
                ?.map((p) => PollItem.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'გამოკითხვების ჩატვირთვა ვერ მოხერხდა';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPollDetail(int pollId) async {
    _detailLoading = true;
    _detailError = null;
    notifyListeners();

    try {
      final response = await _api.get('/polls/detail.php', queryParams: {
        'poll_id': pollId,
      });

      if (response.success && response.data != null) {
        _currentPoll = PollDetail.fromJson(response.data as Map<String, dynamic>);
      } else {
        _detailError = response.message;
      }
    } catch (e) {
      _detailError = 'ჩატვირთვა ვერ მოხერხდა';
    }

    _detailLoading = false;
    notifyListeners();
  }

  Future<bool> vote(int pollId, int optionId) async {
    _voting = true;
    notifyListeners();

    try {
      final response = await _api.post('/polls/vote.php', data: {
        'poll_id': pollId,
        'option_id': optionId,
      });

      if (response.success) {
        // Reload detail to get updated results
        await loadPollDetail(pollId);
        // Also update list
        await loadPolls();
        _voting = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _voting = false;
    notifyListeners();
    return false;
  }

  void clearDetail() {
    _currentPoll = null;
    _detailError = null;
  }
}
