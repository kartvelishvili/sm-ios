import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) return;

    final provider = context.read<SettingsProvider>();
    final success = await provider.uploadProfileImage(File(pickedFile.path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? AppStrings.of(context).imageUpdated
              : provider.error ?? AppStrings.of(context).error),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final profile = provider.profile;

    if (provider.isLoading && profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final s = AppStrings.of(context);
    final user = profile?['user'] as Map<String, dynamic>? ?? {};
    final complex = profile?['complex'] as Map<String, dynamic>? ?? {};
    final apartments = profile?['apartments'] as List? ?? [];
    final parkings = profile?['parkings'] as List? ?? [];
    final sessions = profile?['active_sessions'] as List? ?? [];
    final profileImage = user['profile_image'] as String?;
    final userName =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();

    // Get role from first apartment
    final firstApt = apartments.isNotEmpty
        ? apartments.first as Map<String, dynamic>
        : <String, dynamic>{};
    final role = firstApt['role'] as String?;
    final isPrimary = firstApt['is_primary'] == true || apartments.length == 1;
    final isOwner = role == 'owner' || isPrimary;
    String roleLabel;
    IconData roleIcon;
    Color roleColor;
    if (isOwner) {
      roleLabel = s.owner;
      roleIcon = Icons.star_rounded;
      roleColor = AppColors.primary;
    } else if (role == 'resident') {
      roleLabel = s.resident;
      roleIcon = Icons.person_rounded;
      roleColor = AppColors.success;
    } else {
      roleLabel = role ?? '';
      roleIcon = Icons.person_outline;
      roleColor = AppColors.adaptiveTextSecondary(context);
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: RefreshIndicator(
        onRefresh: () => provider.loadProfile(),
        child: AnimatedBuilder(
          animation: _entryController,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),

                // ═══ Profile Hero Card ═══
                _buildFadeSlide(0.0, 0.3, child: _ProfileHeroCard(
                  userName: userName,
                  email: user['email'] as String? ?? '',
                  profileImage: profileImage,
                  roleLabel: roleLabel,
                  roleIcon: roleIcon,
                  roleColor: roleColor,
                  complexName: complex['name'] as String? ?? '',
                  onImageTap: _pickAndUploadImage,
                )),
                const SizedBox(height: 16),

                // ═══ Apartment & Parking Tiles ═══
                if (apartments.isNotEmpty || parkings.isNotEmpty)
                  _buildFadeSlide(0.1, 0.4, child: _ApartmentTilesRow(
                    apartments: apartments,
                    parkings: parkings,
                  )),
                if (apartments.isNotEmpty || parkings.isNotEmpty)
                  const SizedBox(height: 16),

                // ═══ Personal Info Card ═══
                _buildFadeSlide(0.2, 0.5, child: _SectionCard(
                  icon: Icons.person_rounded,
                  iconColor: AppColors.info,
                  title: s.personalInfo,
                  children: [
                    _DetailTile(
                      icon: Icons.phone_rounded,
                      label: s.phone,
                      value: user['phone'] as String? ?? '',
                    ),
                    _DetailTile(
                      icon: Icons.badge_rounded,
                      label: s.personalNo,
                      value: user['personal_id'] as String? ?? '',
                    ),
                    _DetailTile(
                      icon: Icons.email_rounded,
                      label: 'Email',
                      value: user['email'] as String? ?? '',
                    ),
                  ],
                )),
                const SizedBox(height: 16),

                // ═══ Billing Info Card ═══
                _buildFadeSlide(0.3, 0.6, child: _SectionCard(
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.primary,
                  title: s.billingInfo,
                  children: [
                    _DetailTile(
                      icon: Icons.home_work_rounded,
                      label: s.complex,
                      value: complex['name'] as String? ?? '',
                    ),
                    if (complex['project_name'] != null)
                      _DetailTile(
                        icon: Icons.business_rounded,
                        label: s.project,
                        value: complex['project_name'] as String? ?? '',
                      ),
                    _DetailTile(
                      icon: Icons.payments_rounded,
                      label: s.monthlyFeeLabel,
                      value: '${complex['monthly_fee'] ?? 0} ₾',
                      valueColor: AppColors.primary,
                    ),
                    if ((complex['parking_fee'] as num? ?? 0) > 0)
                      _DetailTile(
                        icon: Icons.local_parking_rounded,
                        label: s.parkingFeeLabel,
                        value: '${complex['parking_fee']} ₾',
                        valueColor: AppColors.primary,
                      ),
                    _DetailTile(
                      icon: Icons.calendar_month_rounded,
                      label: s.paymentDeadline,
                      value: s.deadlineDay(
                          complex['payment_deadline_day'] as int? ?? 20),
                    ),
                  ],
                )),
                const SizedBox(height: 16),

                // ═══ Actions Card ═══
                _buildFadeSlide(0.4, 0.7, child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Consumer<LocaleProvider>(
                        builder: (context, locale, _) {
                          return _ActionTile(
                            icon: Icons.language_rounded,
                            iconBgColor: const Color(0xFF3B82F6),
                            title: s.language,
                            subtitle: locale.language == AppLanguage.ka
                                ? '🇬🇪 ქართული'
                                : '🇬🇧 English',
                            onTap: () => _showLanguageDialog(context),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProv, _) {
                          final String subtitle;
                          switch (themeProv.themeMode) {
                            case ThemeMode.light:
                              subtitle = '☀️ ${s.themeLight}';
                            case ThemeMode.system:
                              subtitle = '📱 ${s.themeSystem}';
                            default:
                              subtitle = '🌙 ${s.themeDark}';
                          }
                          return _ActionTile(
                            icon: Icons.brightness_6_rounded,
                            iconBgColor: AppColors.accent,
                            title: s.themeLabel,
                            subtitle: subtitle,
                            onTap: () => _showThemeDialog(context),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 60),
                      _ActionTile(
                        icon: Icons.phone_rounded,
                        iconBgColor: AppColors.success,
                        title: s.changePhone,
                        onTap: () =>
                            Navigator.pushNamed(context, '/change-phone'),
                      ),
                      const Divider(height: 1, indent: 60),
                      _ActionTile(
                        icon: Icons.lock_rounded,
                        iconBgColor: AppColors.warning,
                        title: s.changePasswordSetting,
                        onTap: () =>
                            Navigator.pushNamed(context, '/change-password'),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),

                // ═══ Active Sessions ═══
                if (sessions.isNotEmpty)
                  _buildFadeSlide(0.5, 0.8, child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.devices_rounded, size: 18, color: AppColors.success),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.activeSessions,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (sessions.length > 1)
                                Flexible(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _clearOtherSessions(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withAlpha(15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.error.withAlpha(40)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete_sweep_rounded, size: 14, color: AppColors.error),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              s.clearOtherSessions,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.error,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...sessions.map((ses) {
                            final session = ses as Map<String, dynamic>;
                            final isCurrent = session['is_current'] == true;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (isCurrent
                                              ? AppColors.success
                                              : AppColors.adaptiveTextMuted(context))
                                          .withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.smartphone_rounded,
                                      size: 18,
                                      color: isCurrent
                                          ? AppColors.success
                                          : AppColors.adaptiveTextMuted(context),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session['device_info'] as String? ??
                                              'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          session['last_used_at'] as String? ?? '',
                                          style: TextStyle(
                                            color: AppColors.adaptiveTextMuted(context),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withAlpha(20),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppColors.success.withAlpha(60)),
                                      ),
                                      child: Text(
                                        s.current,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  )),
                if (sessions.isNotEmpty) const SizedBox(height: 16),

                // ═══ Logout ═══
                _buildFadeSlide(0.6, 0.9, child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Icons.logout_rounded,
                        iconBgColor: AppColors.warning,
                        title: s.logout,
                        titleColor: AppColors.warning,
                        onTap: () => _logout(context, allDevices: false),
                      ),
                      const Divider(height: 1, indent: 60),
                      _ActionTile(
                        icon: Icons.logout_rounded,
                        iconBgColor: AppColors.error,
                        title: s.logoutAll,
                        titleColor: AppColors.error,
                        onTap: () => _logout(context, allDevices: true),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFadeSlide(double start, double end, {required Widget child}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(context).language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppLanguage>(
              value: AppLanguage.ka,
              groupValue: locale.language,
              title: const Text('🇬🇪 ქართული'),
              activeColor: AppColors.primary,
              onChanged: (v) {
                locale.setLanguage(AppLanguage.ka);
                Navigator.of(ctx).pop();
              },
            ),
            RadioListTile<AppLanguage>(
              value: AppLanguage.en,
              groupValue: locale.language,
              title: const Text('🇬🇧 English'),
              activeColor: AppColors.primary,
              onChanged: (v) {
                locale.setLanguage(AppLanguage.en);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProv = context.read<ThemeProvider>();
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.themeLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeProv.themeMode,
              title: Text('🌙 ${s.themeDark}'),
              activeColor: AppColors.primary,
              onChanged: (v) {
                themeProv.setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeProv.themeMode,
              title: Text('☀️ ${s.themeLight}'),
              activeColor: AppColors.primary,
              onChanged: (v) {
                themeProv.setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeProv.themeMode,
              title: Text('📱 ${s.themeSystem}'),
              activeColor: AppColors.primary,
              onChanged: (v) {
                themeProv.setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, {required bool allDevices}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(context).logout),
        content: Text(allDevices
            ? AppStrings.of(context).logoutAllConfirm
            : AppStrings.of(context).logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout(allDevices: allDevices);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.of(context).logout),
          ),
        ],
      ),
    );
  }

  void _clearOtherSessions(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearOtherSessions),
        content: Text(s.clearOtherSessionsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout(allDevices: true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Profile Hero Card — gradient header with avatar, name, role, complex
// ═══════════════════════════════════════════════════════════════════════════════
class _ProfileHeroCard extends StatelessWidget {
  final String userName;
  final String email;
  final String? profileImage;
  final String roleLabel;
  final IconData roleIcon;
  final Color roleColor;
  final String complexName;
  final VoidCallback onImageTap;

  const _ProfileHeroCard({
    required this.userName,
    required this.email,
    required this.profileImage,
    required this.roleLabel,
    required this.roleIcon,
    required this.roleColor,
    required this.complexName,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: AppColors.isDark(context)
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1F2E),
                    Color(0xFF15192A),
                    Color(0xFF1A1A25),
                  ],
                ),
              )
            : null,
        child: Column(
          children: [
            // Gold accent line at top
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00D4AF37),
                    AppColors.primary,
                    AppColors.primaryLight,
                    AppColors.primary,
                    Color(0x00D4AF37),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  // Avatar with camera button
                  GestureDetector(
                    onTap: onImageTap,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withAlpha(80),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(30),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primary.withAlpha(20),
                            backgroundImage: profileImage != null &&
                                    profileImage!.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    'https://pay.smartluxy.ge$profileImage')
                                : null,
                            child: profileImage == null ||
                                    profileImage!.isEmpty
                                ? Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(60),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    email,
                    style: TextStyle(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Role badge + complex name
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (roleLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: roleColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: roleColor.withAlpha(60)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, size: 14, color: roleColor),
                              const SizedBox(width: 5),
                              Text(
                                roleLabel,
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (complexName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withAlpha(40)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.apartment_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                complexName,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Apartment & Parking horizontal tiles
// ═══════════════════════════════════════════════════════════════════════════════
class _ApartmentTilesRow extends StatelessWidget {
  final List apartments;
  final List parkings;

  const _ApartmentTilesRow({
    required this.apartments,
    required this.parkings,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final tiles = <Widget>[];

    for (final apt in apartments) {
      final a = apt as Map<String, dynamic>;
      tiles.add(_MiniInfoTile(
        icon: Icons.door_front_door_rounded,
        color: AppColors.info,
        label: s.aptLabel,
        value: '${a['apartment_number'] ?? ''}',
        subtitle:
            '${s.floor} ${a['floor'] ?? ''} · ${s.building} ${a['building'] ?? ''}',
      ));
    }

    for (final prk in parkings) {
      final p = prk as Map<String, dynamic>;
      tiles.add(_MiniInfoTile(
        icon: Icons.local_parking_rounded,
        color: AppColors.warning,
        label: s.parking,
        value: 'P${p['parking_number'] ?? ''}',
        subtitle: p['zone'] as String? ?? '',
      ));
    }

    return Row(
      children: tiles
          .expand((t) => [Expanded(child: t), const SizedBox(width: 10)])
          .toList()
        ..removeLast(),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;

  const _MiniInfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppColors.isDark(context)
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withAlpha(12),
                    AppColors.darkCard,
                  ],
                ),
              )
            : BoxDecoration(
                color: color.withAlpha(8),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.adaptiveTextSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.adaptiveTextPrimary(context),
              ),
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.adaptiveTextMuted(context),
                    fontSize: 11,
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

// ═══════════════════════════════════════════════════════════════════════════════
//  Section Card — reusable card with icon header
// ═══════════════════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Detail Tile — icon + label + value row
// ═══════════════════════════════════════════════════════════════════════════════
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.adaptiveTextMuted(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.adaptiveTextSecondary(context),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: valueColor ?? AppColors.adaptiveTextPrimary(context),
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Action Tile — settings menu item with colored icon circle
// ═══════════════════════════════════════════════════════════════════════════════
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconBgColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor,
          fontSize: 14,
        ),
      ),
      trailing: subtitle != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: AppColors.adaptiveTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            )
          : const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
