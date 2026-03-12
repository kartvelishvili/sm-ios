import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/localization.dart';
import 'services/storage_service.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/door_provider.dart';
import 'providers/resident_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/message_provider.dart';
import 'providers/poll_provider.dart';

import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/residents/residents_screen.dart';
import 'screens/settings/change_phone_screen.dart';
import 'screens/settings/change_password_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash/animated_splash_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/polls/polls_screen.dart';
import 'screens/inbox/inbox_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();

  final storage = StorageService();
  await storage.init();
  final apiClient = ApiClient(storage);

  // Initialize locale
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  // Initialize theme
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // Auth provider (created early so 401 handler can reference it)
  final authProvider = AuthProvider(apiClient, storage)..initialize();

  // Wire up automatic logout on 401
  apiClient.onUnauthorized = () {
    authProvider.forceLogout();
  };

  // Check if onboarding has been completed
  final onboardingDone = await isOnboardingDone();

  runApp(SmartLuxyApp(
    storage: storage,
    apiClient: apiClient,
    showOnboarding: !onboardingDone,
    localeProvider: localeProvider,
    authProvider: authProvider,
    themeProvider: themeProvider,
  ));
}

class SmartLuxyApp extends StatelessWidget {
  final StorageService storage;
  final ApiClient apiClient;
  final bool showOnboarding;
  final LocaleProvider localeProvider;
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;

  const SmartLuxyApp({
    super.key,
    required this.storage,
    required this.apiClient,
    required this.showOnboarding,
    required this.localeProvider,
    required this.authProvider,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(apiClient)..setLocale(localeProvider),
        ),
        ChangeNotifierProvider(create: (_) => PaymentProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => DoorProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => ResidentProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => MessageProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => PollProvider(apiClient)),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, locale, themeProv, _) {
          return LocaleScope(
            provider: locale,
            child: MaterialApp(
              title: 'SmartLuxy',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProv.themeMode,
              home: showOnboarding
                  ? _OnboardingGate(showLanguagePicker: locale.isFirstLaunch)
                  : const _SplashThenAuth(),
              routes: {
                '/login': (_) => const LoginScreen(),
                '/register': (_) => const RegisterScreen(),
                '/forgot-password': (_) => const ForgotPasswordScreen(),
                '/home': (_) => const MainShell(),
                '/residents': (_) => const ResidentsScreen(),
                '/change-phone': (_) => const ChangePhoneScreen(),
                '/change-password': (_) => const ChangePasswordScreen(),
                '/notifications': (_) => const NotificationsScreen(),
                '/messages': (_) => const MessagesScreen(),
                '/polls': (_) => const PollsScreen(),
                '/inbox': (_) => const InboxScreen(),
              },
            ),
          );
        },
      ),
    );
  }
}

/// Shows animated splash → onboarding on first launch, then transitions to auth.
class _OnboardingGate extends StatefulWidget {
  final bool showLanguagePicker;
  const _OnboardingGate({this.showLanguagePicker = false});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool _splashDone = false;
  bool _onboardingDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return AnimatedSplashScreen(
        showLanguagePicker: widget.showLanguagePicker,
        onComplete: () => setState(() => _splashDone = true),
      );
    }
    if (_onboardingDone) return const _AuthGate();
    return OnboardingScreen(
      onComplete: () => setState(() => _onboardingDone = true),
    );
  }
}

/// Shows animated splash → auth gate for returning users.
class _SplashThenAuth extends StatefulWidget {
  const _SplashThenAuth();

  @override
  State<_SplashThenAuth> createState() => _SplashThenAuthState();
}

class _SplashThenAuthState extends State<_SplashThenAuth> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return AnimatedSplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }
    return const _AuthGate();
  }
}

/// Listens to [AuthProvider] and shows Login or MainShell accordingly.
/// Also starts/stops dashboard polling and handles app lifecycle + notification taps.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> with WidgetsBindingObserver {
  AuthState? _prevState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for pending notification tap
    _checkNotificationTap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final dashboard = context.read<DashboardProvider>();
    switch (state) {
      case AppLifecycleState.resumed:
        dashboard.setForeground(true);
        _checkNotificationTap();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        dashboard.setForeground(false);
        break;
    }
  }

  void _checkNotificationTap() {
    final payload = NotificationService().consumePendingPayload();
    if (payload == null || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleNotificationPayload(payload);
    });
  }

  void _handleNotificationPayload(String payload) {
    if (payload.startsWith('approval:')) {
      Navigator.of(context).pushNamed('/residents');
    } else if (payload.startsWith('payment:')) {
      // Stay on dashboard (payments tab could also be navigated to)
    } else if (payload.startsWith('debt:')) {
      // Stay on dashboard — debt is shown there
    }
    // For 'access:' and others — just open the app (default)
  }

  @override
  Widget build(BuildContext context) {
    // Keep locale in sync with dashboard provider
    final locale = context.watch<LocaleProvider>();
    context.read<DashboardProvider>().setLocale(locale);

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Start/stop polling when auth state changes
        if (auth.state != _prevState) {
          _prevState = auth.state;
          final dashboard = context.read<DashboardProvider>();
          if (auth.state == AuthState.authenticated) {
            dashboard.startPolling();
            context.read<MessageProvider>().loadUnreadCount();
          } else {
            dashboard.stopPolling();
          }
        }

        switch (auth.state) {
          case AuthState.initial:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthState.authenticated:
            return const MainShell();
          case AuthState.loading:
          case AuthState.unauthenticated:
          case AuthState.error:
            return const LoginScreen();
        }
      },
    );
  }
}
