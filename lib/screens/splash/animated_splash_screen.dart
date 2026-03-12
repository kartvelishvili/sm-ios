import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

/// Animated splash screen that shows "SmartLuxy" with shimmer + particles.
///
/// On **first launch** (`showLanguagePicker = true`) the auto-advance is
/// paused after the text fades in and two language buttons slide up.
/// On **returning launches** the splash plays through and calls [onComplete].
class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool showLanguagePicker;

  const AnimatedSplashScreen({
    super.key,
    required this.onComplete,
    this.showLanguagePicker = false,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final AnimationController _particleController;
  late final AnimationController _scaleController;
  late final AnimationController _langPickerController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _scaleAnim;

  bool _languageChosen = false;

  @override
  void initState() {
    super.initState();

    // Main fade-in for text (shorter if language picker, because we pause)
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.showLanguagePicker ? 1600 : 2800,
      ),
    );

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _subtitleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );

    // Shimmer effect on the gold text
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Floating particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Scale pulse
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Language picker slide-up (only used when showLanguagePicker)
    _langPickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    if (widget.showLanguagePicker) {
      // When fade-in completes, reveal language picker
      _fadeController.addStatusListener((status) {
        if (status == AnimationStatus.completed && !_languageChosen) {
          _langPickerController.forward();
        }
      });
    } else {
      // Normal splash — auto-complete
      _fadeController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    }
  }

  void _pickLanguage(AppLanguage lang) async {
    if (_languageChosen) return;
    setState(() => _languageChosen = true);

    final localeProvider = context.read<LocaleProvider>();
    await localeProvider.setLanguage(lang);

    // Brief delay to show selection, then complete
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _scaleController.dispose();
    _langPickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _fadeController,
          _shimmerController,
          _particleController,
          _scaleController,
          _langPickerController,
        ]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.isDark(context)
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0D0D15),
                        AppColors.darkBackground,
                        Color(0xFF0D0D15),
                      ],
                    )
                  : null,
              color: AppColors.isDark(context) ? null : AppColors.background,
            ),
            child: Stack(
              children: [
                // Animated particles
                ..._buildParticles(),

                // Glow behind text
                Center(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withAlpha(30),
                            AppColors.primary.withAlpha(8),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Main content
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gold shimmer text: SmartLuxy
                        FadeTransition(
                          opacity: _fadeIn,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              final sv = _shimmerController.value;
                              return LinearGradient(
                                begin: Alignment(-1.0 + 3.0 * sv, 0),
                                end: Alignment(-0.5 + 3.0 * sv, 0),
                                colors: const [
                                  AppColors.primaryDark,
                                  AppColors.primaryLight,
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                  AppColors.primaryDark,
                                ],
                                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: const Text(
                              'SmartLuxy',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subtitle
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: Text(
                            'კომფორტი ერთი შეხებით',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  AppColors.adaptiveTextSecondary(context).withAlpha(180),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Loading dots (only when NOT showing language picker)
                        if (!widget.showLanguagePicker)
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: _LoadingDots(
                                animation: _particleController),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Language picker (first launch only) ──
                if (widget.showLanguagePicker)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _langPickerController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(
                        opacity: _langPickerController,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'აირჩიეთ ენა / Choose Language',
                                  style: TextStyle(
                                    color: AppColors.adaptiveTextSecondary(context),
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _LanguageButton(
                                        flag: '🇬🇪',
                                        label: 'ქართული',
                                        selected: _languageChosen,
                                        onTap: () =>
                                            _pickLanguage(AppLanguage.ka),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _LanguageButton(
                                        flag: '🇬🇧',
                                        label: 'English',
                                        selected: _languageChosen,
                                        onTap: () =>
                                            _pickLanguage(AppLanguage.en),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles() {
    final rng = Random(42);
    return List.generate(18, (i) {
      final startX = rng.nextDouble();
      final startY = rng.nextDouble();
      final size = 2.0 + rng.nextDouble() * 4;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final delay = rng.nextDouble();

      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, _) {
          final t = ((_particleController.value + delay) % 1.0) * speed;
          final opacity = _fadeIn.value * (0.15 + 0.35 * sin(t * pi * 2));
          final dx = startX + sin(t * pi * 2 + i) * 0.03;
          final dy = startY - t * 0.15;

          return Positioned(
            left: dx * MediaQuery.of(context).size.width,
            top: (dy % 1.0) * MediaQuery.of(context).size.height,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((opacity * 255).round()),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      );
    });
  }
}

// ── Language selection button ──

class _LanguageButton extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withAlpha(80),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withAlpha(15),
                AppColors.primary.withAlpha(5),
              ],
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.adaptiveTextPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading dots animation ──

class _LoadingDots extends StatelessWidget {
  final Animation<double> animation;

  const _LoadingDots({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((animation.value + i * 0.2) % 1.0);
            final scale = 0.5 + 0.5 * sin(t * pi);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((180 * scale).round()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
