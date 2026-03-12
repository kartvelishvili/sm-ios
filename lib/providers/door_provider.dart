import 'package:flutter/material.dart';
import '../models/door_model.dart';
import '../services/api_client.dart';
import '../core/constants.dart';

class DoorProvider extends ChangeNotifier {
  final ApiClient _api;

  List<DoorItem> _doors = [];
  String? _complexName;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  final Map<int, DateTime> _lastOpenTime = {};

  // PIN
  ElevatorPin? _elevatorPin;
  bool _pinLoading = false;
  String? _pinError;
  int? _pinStatusCode;

  DoorProvider(this._api);

  List<DoorItem> get doors => _doors;
  String? get complexName => _complexName;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  ElevatorPin? get elevatorPin => _elevatorPin;
  bool get pinLoading => _pinLoading;
  String? get pinError => _pinError;
  int? get pinStatusCode => _pinStatusCode;
  bool get hasElevator => _doors.any((d) => d.isElevator);

  bool canOpenDoor(int doorId) {
    final lastTime = _lastOpenTime[doorId];
    if (lastTime == null) return true;
    return DateTime.now().difference(lastTime).inSeconds >=
        AppConstants.doorCooldownSeconds;
  }

  int getCooldownRemaining(int doorId) {
    final lastTime = _lastOpenTime[doorId];
    if (lastTime == null) return 0;
    final elapsed = DateTime.now().difference(lastTime).inSeconds;
    final remaining = AppConstants.doorCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> loadDoors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/doors/list.php');

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _complexName = data['complex_name'] as String?;
        _doors = (data['doors'] as List?)
                ?.map((d) => DoorItem.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        _error = response.message ?? 'კარების ჩატვირთვა ვერ მოხერხდა';
      }
    } catch (e) {
      _error = 'კარების ჩატვირთვა ვერ მოხერხდა. სცადეთ მოგვიანებით.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> openDoor(int doorId) async {
    if (!canOpenDoor(doorId)) {
      _error = 'გთხოვთ დაიცადოთ ${getCooldownRemaining(doorId)} წამი';
      notifyListeners();
      return false;
    }

    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _api.post('/doors/open.php', data: {
        'door_id': doorId,
      });

      if (response.success) {
        _lastOpenTime[doorId] = DateTime.now();
        _successMessage = response.message ?? 'კარი გაიხსნა';
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'კარის გახსნა ვერ მოხერხდა';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'კარის გახსნა ვერ მოხერხდა. სცადეთ მოგვიანებით.';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadPin() async {
    _pinLoading = true;
    _pinError = null;
    _pinStatusCode = null;
    notifyListeners();

    try {
      final response = await _api.get('/doors/pin.php');

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        _elevatorPin = ElevatorPin.fromJson(data);
        _pinError = null;
      } else {
        _pinError = response.message ?? 'PIN ვერ ჩაიტვირთა';
        _pinStatusCode = response.statusCode;
      }
    } catch (e) {
      _pinError = 'PIN ვერ ჩაიტვირთა';
    }

    _pinLoading = false;
    notifyListeners();
  }
}
