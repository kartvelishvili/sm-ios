import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization.dart';
import '../../core/theme.dart';

/// Onboarding key for SharedPreferences
const _kOnboardingDone = 'onboarding_done';

/// Check if onboarding has been completed
Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

/// Mark onboarding as completed
Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _currentPage = 0;

  late AnimationController _bgAnimController;
  late AnimationController _contentAnimController;

  static const _pageCount = 4;

  List<_OnboardingPage> _buildPages(BuildContext context) {
    final s = AppStrings.of(context);
    return [
      _OnboardingPage(
        icon: Icons.apartment_rounded,
        iconColor: AppColors.primary,
        title: s.onboardingTitle1,
        subtitle: s.onboardingSubtitle1,
        features: [
          _Feature(Icons.payment_rounded, s.onboardingFeature1a),
          _Feature(Icons.door_front_door_rounded, s.onboardingFeature1b),
          _Feature(Icons.auto_awesome_rounded, s.onboardingFeature1c),
        ],
      ),
      _OnboardingPage(
        icon: Icons.notifications_active_rounded,
        iconColor: AppColors.warning,
        title: s.onboardingTitle2,
        subtitle: s.onboardingSubtitle2,
        permissionType: _PermissionType.notification,
        features: [
          _Feature(Icons.person_add_rounded, s.onboardingFeature2a),
          _Feature(Icons.check_circle_rounded, s.onboardingFeature2b),
          _Feature(Icons.warning_amber_rounded, s.onboardingFeature2c),
        ],
      ),
      _OnboardingPage(
        icon: Icons.camera_alt_rounded,
        iconColor: AppColors.info,
        title: s.onboardingTitle3,
        subtitle: s.onboardingSubtitle3,
        permissionType: _PermissionType.camera,
        features: [
          _Feature(Icons.photo_camera_rounded, s.onboardingFeature3a),
          _Feature(Icons.photo_library_rounded, s.onboardingFeature3b),
        ],
      ),
      _OnboardingPage(
        icon: Icons.rocket_launch_rounded,
        iconColor: AppColors.success,
        title: s.onboardingTitleFinal,
        subtitle: s.onboardingSubtitleFinal,
        features: [],
        isFinal: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _contentAnimController.reset();
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    _contentAnimController.forward();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _animateToPage(_currentPage + 1);
    }
  }

  void _finish() async {
    await markOnboardingDone();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context);
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, _) {
              final t = _bgAnimController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: AppColors.isDark(context)
                      ? LinearGradient(
                          begin: Alignment(sin(t * pi * 2) * 0.5, -1),
                          end: Alignment(-sin(t * pi * 2) * 0.5, 1),
                          colors: [
                            const Color(0xFF0D0D18),
                            AppColors.darkBackground,
                            Color.lerp(
                              const Color(0xFF0D0D18),
                              pages[_currentPage].iconColor.withAlpha(15),
                              0.5,
                            )!,
                          ],
                        )
                      : null,
                  color: AppColors.isDark(context) ? null : AppColors.background,
                ),
              );
            },
          ),

          // Floating particles
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(
                progress: _bgAnimController.value,
                color: pages[_currentPage].iconColor,
              ),
              size: Size.infinite,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                SizedBox(
                  height: 48,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _currentPage < pages.length - 1
                        ? Align(
                            key: const ValueKey('skip'),
                            alignment: Alignment.topRight,
                            child: TextButton(
                              onPressed: () =>
                                  _animateToPage(pages.length - 1),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.of(context).skip,
                                    style: TextStyle(
                                      color: AppColors.adaptiveTextMuted(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: AppColors.adaptiveTextMuted(context),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('noskip')),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) {
                      setState(() => _currentPage = i);
                      _contentAnimController.reset();
                      _contentAnimController.forward();
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pages.length,
                    itemBuilder: (context, index) =>
                        _AnimatedOnboardingPageWidget(
                      page: pages[index],
                      animation: _contentAnimController,
                      onPermissionGranted: _next,
                    ),
                  ),
                ),

                // Page indicator dots
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [
                                    pages[_currentPage].iconColor,
                                    pages[_currentPage]
                                        .iconColor
                                        .withAlpha(160),
                                  ],
                                )
                              : null,
                          color: isActive ? null : AppColors.adaptiveBorder(context),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: pages[_currentPage]
                                        .iconColor
                                        .withAlpha(80),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                // Bottom button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: pages[_currentPage].isFinal
                        ? _GlowButton(
                            label: AppStrings.of(context).start,
                            color: AppColors.success,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _finish,
                          )
                        : pages[_currentPage].permissionType == null
                            ? _GlowButton(
                                label: AppStrings.of(context).continueBtn,
                                color: AppColors.primary,
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _next,
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow Button ──

class _GlowButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _GlowButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Particle Painter ──

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    final paint = Paint();

    for (int i = 0; i < 25; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final radius = 1.5 + rng.nextDouble() * 3;
      final speed = 0.5 + rng.nextDouble();
      final phase = rng.nextDouble() * pi * 2;

      final t = (progress * speed + phase) % 1.0;
      final x = baseX + sin(t * pi * 2 + i) * 20;
      final y = baseY - t * size.height * 0.08;
      final alpha = (0.08 + 0.20 * sin(t * pi)).clamp(0.0, 1.0);

      paint.color = color.withAlpha((alpha * 255).round());
      canvas.drawCircle(Offset(x, y % size.height), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress || old.color != color;
}

// ── Page Model ──

enum _PermissionType { notification, camera }

class _Feature {
  final IconData icon;
  final String text;
  const _Feature(this.icon, this.text);
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<_Feature> features;
  final _PermissionType? permissionType;
  final bool isFinal;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.features,
    this.permissionType,
    this.isFinal = false,
  });
}

// ── Animated Page Widget ──

class _AnimatedOnboardingPageWidget extends StatefulWidget {
  final _OnboardingPage page;
  final AnimationController animation;
  final VoidCallback onPermissionGranted;

  const _AnimatedOnboardingPageWidget({
    required this.page,
    required this.animation,
    required this.onPermissionGranted,
  });

  @override
  State<_AnimatedOnboardingPageWidget> createState() =>
      _AnimatedOnboardingPageWidgetState();
}

class _AnimatedOnboardingPageWidgetState
    extends State<_AnimatedOnboardingPageWidget> {
  bool _granted = false;
  bool _requesting = false;

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);

    PermissionStatus status;

    switch (widget.page.permissionType!) {
      case _PermissionType.notification:
        status = await Permission.notification.request();
        break;
      case _PermissionType.camera:
        status = await Permission.camera.request();
        if (status.isGranted) {
          await Permission.photos.request();
        }
        break;
    }

    if (mounted) {
      setState(() {
        _granted = status.isGranted || status.isLimited;
        _requesting = false;
      });

      if (_granted) {
        await Future.delayed(const Duration(milliseconds: 700));
        widget.onPermissionGranted();
      } else if (status.isPermanentlyDenied) {
        if (mounted) _showSettingsDialog();
      } else {
        widget.onPermissionGranted();
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adaptiveCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.of(context).permissionRequired),
        content: Text(AppStrings.of(context).permissionDeniedMsg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onPermissionGranted();
            },
            child: Text(AppStrings.of(context).skip),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(AppStrings.of(context).openSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;

    // Staggered entry animations
    final iconSlide = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );
    final titleSlide = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
    );
    final subtitleSlide = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon with glow
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(iconSlide),
            child: FadeTransition(
              opacity: iconSlide,
              child: page.isFinal
                  ? _CelebrationIcon(color: page.iconColor)
                  : _GlowingIcon(
                      icon: page.icon,
                      color: page.iconColor,
                    ),
            ),
          ),
          const SizedBox(height: 36),

          // Title
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(titleSlide),
            child: FadeTransition(
              opacity: titleSlide,
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(subtitleSlide),
            child: FadeTransition(
              opacity: subtitleSlide,
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Features with staggered entry
          ...List.generate(page.features.length, (i) {
            final featureAnim = CurvedAnimation(
              parent: widget.animation,
              curve: Interval(
                0.3 + i * 0.12,
                0.7 + i * 0.1,
                curve: Curves.easeOutCubic,
              ),
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(featureAnim),
              child: FadeTransition(
                opacity: featureAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: page.iconColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: page.iconColor.withAlpha(30),
                          ),
                        ),
                        child: Icon(
                          page.features[i].icon,
                          color: page.iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          page.features[i].text,
                          style: const TextStyle(fontSize: 15, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Permission button
          if (page.permissionType != null) ...[
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              child: _granted
                  ? _SuccessBadge(key: const ValueKey('granted'))
                  : _PermissionButton(
                      key: const ValueKey('request'),
                      color: page.iconColor,
                      requesting: _requesting,
                      onPressed: _requestPermission,
                    ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

// ── Glowing icon circle ──

class _GlowingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _GlowingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withAlpha(40),
            color.withAlpha(10),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
        border: Border.all(color: color.withAlpha(60), width: 2),
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }
}

// ── Celebration icon for final page ──

class _CelebrationIcon extends StatefulWidget {
  final Color color;

  const _CelebrationIcon({required this.color});

  @override
  State<_CelebrationIcon> createState() => _CelebrationIconState();
}

class _CelebrationIconState extends State<_CelebrationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final scale = 1.0 + 0.08 * sin(_bounceController.value * pi);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withAlpha(50),
                  widget.color.withAlpha(15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(40),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: const Center(
              child: Text('🎉', style: TextStyle(fontSize: 56)),
            ),
          ),
        );
      },
    );
  }
}

// ── Success badge after permission granted ──

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
          const SizedBox(width: 10),
          Text(
            AppStrings.of(context).permissionGranted,
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Permission request button ──

class _PermissionButton extends StatelessWidget {
  final Color color;
  final bool requesting;
  final VoidCallback onPressed;

  const _PermissionButton({
    super.key,
    required this.color,
    required this.requesting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: requesting ? null : onPressed,
          icon: requesting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.shield_rounded),
          label: Text(
            requesting ? AppStrings.of(context).requesting : AppStrings.of(context).grantPermission,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
