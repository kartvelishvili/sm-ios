import 'package:flutter/material.dart';

// ─── SmartLuxy Design Tokens ─────────────────────────────────────────────────
// Source: https://pay.smartluxy.ge/assets/css/smartluxy.css

class AppColors {
  AppColors._();

  // ── Brand / Gold Accent ──
  static const Color primary = Color(0xFFD4AF37);       // --gold-primary
  static const Color primaryLight = Color(0xFFF4D03F);   // --gold-light
  static const Color primaryDark = Color(0xFFB8960C);    // --gold-dark
  static const Color borderGold = Color(0x4DD4AF37);     // rgba(212,175,55,0.3)

  // ── Secondary (Light Theme) ──
  static const Color secondary = Color(0xFF6366F1);      // --primary-color (indigo)
  static const Color secondaryLight = Color(0xFFE0E7FF);  // --primary-light
  static const Color secondaryDark = Color(0xFF4F46E5);   // --primary-hover
  static const Color accent = Color(0xFF8B5CF6);          // --accent-color
  static const Color secondaryBlue = Color(0xFF0EA5E9);   // --secondary-color

  // ── Status ──
  static const Color success = Color(0xFF10B981);        // --success / emerald
  static const Color warning = Color(0xFFF59E0B);        // --warning / amber
  static const Color error = Color(0xFFEF4444);          // --danger / red
  static const Color info = Color(0xFF3B82F6);           // --info / blue

  // ── Dark Theme Backgrounds ──
  static const Color darkBackground = Color(0xFF0A0A0F);  // --bg-primary
  static const Color darkSurface = Color(0xFF12121A);      // --bg-secondary
  static const Color darkCard = Color(0xFF1A1A25);         // --bg-card
  static const Color darkCardHover = Color(0xFF222230);    // --bg-card-hover
  static const Color darkInput = Color(0xFF15151F);        // --bg-input
  static const Color darkBorder = Color(0xFF2A2A3A);       // --border-color

  // ── Dark Theme Text ──
  static const Color darkTextPrimary = Color(0xFFFFFFFF);  // --text-primary
  static const Color darkTextSecondary = Color(0xFFA0A0B0); // --text-secondary
  static const Color darkTextMuted = Color(0xFF6B6B7B);    // --text-muted

  // ── Light Theme Neutrals (Gray Scale) ──
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // ── Light Theme Card BG (slight gray for subtle cards) ──
  static const Color lightCard = Color(0xFFF3F4F6);

  // ── Theme-aware helpers ──
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color adaptiveBackground(BuildContext context) =>
      isDark(context) ? darkBackground : background;
  static Color adaptiveSurface(BuildContext context) =>
      isDark(context) ? darkSurface : surface;
  static Color adaptiveCard(BuildContext context) =>
      isDark(context) ? darkCard : lightCard;
  static Color adaptiveCardHover(BuildContext context) =>
      isDark(context) ? darkCardHover : const Color(0xFFE5E7EB);
  static Color adaptiveBorder(BuildContext context) =>
      isDark(context) ? darkBorder : cardBorder;
  static Color adaptiveTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;
  static Color adaptiveTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;
  static Color adaptiveTextMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : textHint;

  /// Card gradient: in dark mode use subtle gradient, in light mode use flat color.
  static BoxDecoration adaptiveCardDecoration(BuildContext context, {
    Color? accentColor,
    BorderRadius? borderRadius,
  }) {
    final br = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    if (isDark(context)) {
      final card = darkCard;
      final end = accentColor != null
          ? Color.lerp(card, accentColor, 0.06)!
          : const Color(0xFF1A1F25);
      return BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [card, end],
        ),
        border: Border.all(color: darkBorder.withAlpha(80)),
      );
    }
    return BoxDecoration(
      borderRadius: br,
      color: surface,
      border: Border.all(color: cardBorder),
    );
  }

  /// Standard card gradient: dark mode → subtle gradient; light mode → flat surface.
  static BoxDecoration cardGradient(BuildContext context, {Color? accent}) {
    if (!isDark(context)) {
      return BoxDecoration(color: surface);
    }
    if (accent != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withAlpha(15), darkCard, accent.withAlpha(8)],
        ),
      );
    }
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkCard, Color(0xFF1A1F25), darkCard],
      ),
    );
  }

  // ── Gradients ──
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFF4D03F), Color(0xFFD4AF37)],
  );
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFF093FB)],
  );
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C0C0C), Color(0xFF1A1A2E), Color(0xFF16213E)],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  );
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEB3349), Color(0xFFF45C43)],
  );
}

// ─── Border Radii ────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

// ─── Font Families ───────────────────────────────────────────────────────────
const String _fontHeading = 'BPG WEB 002 Caps';
const String _fontBody = 'BPG Glaho WEB';
const String _fontFallback = 'Segoe UI';

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  //  DARK THEME  (primary — gold accent on dark bg)
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get dark {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: _fontBody,
      fontFamilyFallback: const [_fontFallback, 'sans-serif'],
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(fontFamily: _fontHeading),
        displayMedium: const TextStyle(fontFamily: _fontHeading),
        displaySmall: const TextStyle(fontFamily: _fontHeading),
        headlineLarge: const TextStyle(fontFamily: _fontHeading),
        headlineMedium: const TextStyle(fontFamily: _fontHeading),
        headlineSmall: const TextStyle(fontFamily: _fontHeading),
        titleLarge: const TextStyle(fontFamily: _fontHeading, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontFamily: _fontHeading),
        titleSmall: const TextStyle(fontFamily: _fontHeading),
      ).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: TextStyle(
          fontFamily: _fontHeading,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        color: AppColors.darkCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontBody,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: const BorderSide(color: AppColors.borderGold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(
          fontFamily: _fontBody,
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primary.withAlpha(30),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.darkTextMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: _fontBody,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontFamily: _fontBody,
            fontSize: 12,
            color: AppColors.darkTextMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCard,
        contentTextStyle: const TextStyle(
          fontFamily: _fontBody,
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: const TextStyle(
          fontFamily: _fontHeading,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _fontBody,
          color: AppColors.darkTextSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCard,
        selectedColor: AppColors.primary.withAlpha(30),
        side: const BorderSide(color: AppColors.darkBorder),
        labelStyle: const TextStyle(fontFamily: _fontBody, color: AppColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.darkBorder,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(AppColors.darkBackground),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.darkTextMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME  (indigo/purple accent)
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get light {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.secondary,       // indigo
        onPrimary: Colors.white,
        secondary: AppColors.secondaryBlue,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: _fontBody,
      fontFamilyFallback: const [_fontFallback, 'sans-serif'],
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(fontFamily: _fontHeading),
        displayMedium: const TextStyle(fontFamily: _fontHeading),
        displaySmall: const TextStyle(fontFamily: _fontHeading),
        headlineLarge: const TextStyle(fontFamily: _fontHeading),
        headlineMedium: const TextStyle(fontFamily: _fontHeading),
        headlineSmall: const TextStyle(fontFamily: _fontHeading),
        titleLarge: const TextStyle(fontFamily: _fontHeading, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontFamily: _fontHeading),
        titleSmall: const TextStyle(fontFamily: _fontHeading),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: _fontHeading,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        color: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontBody,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: const BorderSide(color: AppColors.secondary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          fontFamily: _fontBody,
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
