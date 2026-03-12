import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/doors/doors_screen.dart';
import '../screens/payments/payment_history_screen.dart';
import '../screens/polls/polls_screen.dart';
import '../screens/settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Navigator keys for each tab to maintain separate navigation stacks
  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  // Index mapping: 0=Dashboard, 1=Polls, 2=Doors(center), 3=Payments, 4=Settings
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const PollsScreen();
      case 2:
        return const DoorsScreen();
      case 3:
        return const PaymentHistoryScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Try to pop inner navigator first
        final navState = _navigatorKeys[_currentIndex].currentState;
        if (navState != null && navState.canPop()) {
          navState.pop();
        } else if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(5, (i) => Navigator(
            key: _navigatorKeys[i],
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => _buildScreen(i),
            ),
          )),
        ),
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.adaptiveSurface(context),
          border: Border(
            top: BorderSide(
              color: AppColors.adaptiveBorder(context).withAlpha(80),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Dashboard
                _NavBarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: s.navHome,
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                // Polls
                _NavBarItem(
                  icon: Icons.poll_outlined,
                  activeIcon: Icons.poll,
                  label: s.navPolls,
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                // Doors (center elevated)
                _CenterFab(
                  isActive: _currentIndex == 2,
                  label: s.navDoors,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                // Payments
                _NavBarItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: s.navPayments,
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                // Settings
                _NavBarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: s.navSettings,
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Elevated center FAB-like button for Doors
class _CenterFab extends StatelessWidget {
  final bool isActive;
  final String label;
  final VoidCallback onTap;

  const _CenterFab({
    required this.isActive,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isActive
                    ? AppColors.goldGradient
                    : LinearGradient(
                        colors: [
                          AppColors.primary.withAlpha(180),
                          AppColors.primaryDark.withAlpha(200),
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(isActive ? 100 : 50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.door_sliding,
                color: isActive ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : AppColors.adaptiveTextMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ic = isActive ? activeIcon : icon;
    final color =
        isActive ? AppColors.primary : AppColors.adaptiveTextMuted(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, color: color, size: 22),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
