/// Smart Luxy API Constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Luxy';
  static const String baseUrl = 'https://pay.smartluxy.ge/apps';
  static const String apiKey = 'smlx_app_29f8c4e1a7b3d560e8f21094c6d7ba53';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String userKey = 'user_data';

  // Timeouts
  static const int connectTimeout = 15; // seconds
  static const int receiveTimeout = 15;

  // Door open cooldown
  static const int doorCooldownSeconds = 3;
}
