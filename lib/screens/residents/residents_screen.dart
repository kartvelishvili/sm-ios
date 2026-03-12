import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/resident_provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResidentProvider>().loadResidents();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _buildFadeSlide(double start, double end, {required Widget child}) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResidentProvider>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.residentsTitle)),
      body: provider.isLoading && provider.apartments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadResidents(),
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, _) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.apartments.length,
                    itemBuilder: (context, index) {
                      final delay = (index * 0.15).clamp(0.0, 0.6);
                      return _buildFadeSlide(
                        delay,
                        (delay + 0.4).clamp(0, 1),
                        child: _ApartmentResidentsCard(
                          apartmentData: provider.apartments[index],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _ApartmentResidentsCard extends StatelessWidget {
  final Map<String, dynamic> apartmentData;

  const _ApartmentResidentsCard({required this.apartmentData});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final aptNumber = apartmentData['apartment_number'] as String? ?? '';
    final complexName = apartmentData['complex_name'] as String? ??
        apartmentData['building'] as String? ??
        '';
    final residents = apartmentData['residents'] as List? ?? [];
    final pendingRequests = apartmentData['pending_requests'] as List? ?? [];
    final apartmentId = apartmentData['apartment_id'] as int? ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.adaptiveCard(context),
          gradient: AppColors.isDark(context)
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkCard,
                    Color(0xFF1A1F25),
                    AppColors.darkCard,
                  ],
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gold accent bar
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0x33D4AF37), Color(0x11D4AF37)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.apartment_rounded,
                            size: 22, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.aptComplex(aptNumber, complexName),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${residents.length} ${s.resident}',
                              style: TextStyle(
                                color: AppColors.adaptiveTextSecondary(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Residents
                  ...residents.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final resident = entry.value as Map<String, dynamic>;
                    final isSelf = resident['is_self'] == true ||
                        resident['is_me'] == true;
                    final canRemove = resident['can_remove'] == true;
                    final role = resident['role'] as String? ?? '';
                    final isOwner = role == 'owner' || idx == 0;
                    final roleColor =
                        isOwner ? AppColors.primary : AppColors.success;
                    final roleName =
                        isOwner ? s.owner : s.resident;

                    final profileImg =
                        resident['profile_image'] as String?;
                    final hasImage =
                        profileImg != null && profileImg.isNotEmpty;
                    final firstName =
                        resident['first_name'] as String? ?? '';
                    final lastName =
                        resident['last_name'] as String? ?? '';
                    final fullName = '$firstName $lastName'.trim();
                    final phone = resident['phone'] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelf
                              ? AppColors.primary.withAlpha(8)
                              : AppColors.adaptiveSurface(context).withAlpha(120),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelf
                                ? AppColors.primary.withAlpha(40)
                                : AppColors.adaptiveBorder(context).withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: roleColor.withAlpha(80),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: roleColor.withAlpha(25),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: roleColor.withAlpha(20),
                                backgroundImage: hasImage
                                    ? NetworkImage(
                                        'https://pay.smartluxy.ge$profileImg')
                                    : null,
                                child: !hasImage
                                    ? Text(
                                        firstName.isNotEmpty
                                            ? firstName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: roleColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isOwner
                                            ? Icons.star_rounded
                                            : Icons.person_rounded,
                                        size: 14,
                                        color: roleColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          roleName,
                                          style: TextStyle(
                                            color: roleColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (phone != null &&
                                          phone.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.phone_rounded,
                                            size: 12,
                                            color: AppColors
                                                .adaptiveTextMuted(context)),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            phone,
                                            style: TextStyle(
                                              color: AppColors
                                                  .adaptiveTextMuted(context),
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Trailing badges/actions
                            if (canRemove)
                              Material(
                                color: AppColors.error.withAlpha(15),
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  onTap: () => _confirmRemove(
                                      context, resident, apartmentId),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                        Icons.person_remove_rounded,
                                        size: 18,
                                        color: AppColors.error),
                                  ),
                                ),
                              )
                            else if (isSelf)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0x20D4AF37),
                                      Color(0x10D4AF37)
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primary
                                          .withAlpha(60)),
                                ),
                                child: Text(
                                  s.you,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Pending Requests
                  if (pendingRequests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    // Pending header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.warning.withAlpha(30)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pending_actions_rounded,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            s.pendingRequests(pendingRequests.length),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...pendingRequests.map((req) {
                      final request = req as Map<String, dynamic>;
                      final requestId = request['request_id'] as int? ??
                          request['id'] as int? ??
                          0;
                      final reqName =
                          '${request['first_name'] ?? ''} ${request['last_name'] ?? ''}'
                              .trim();
                      final reqPhone = request['phone'] as String?;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.warning.withAlpha(30)),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.warning
                                            .withAlpha(60),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          AppColors.warning.withAlpha(20),
                                      child: Text(
                                        reqName.isNotEmpty
                                            ? reqName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reqName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (reqPhone != null)
                                          Row(
                                            children: [
                                              Icon(Icons.phone_rounded,
                                                  size: 12,
                                                  color: AppColors
                                                      .adaptiveTextMuted(context)),
                                              const SizedBox(width: 3),
                                              Text(
                                                reqPhone,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .adaptiveTextMuted(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _rejectRequest(
                                        context, requestId),
                                    icon: const Icon(
                                        Icons.close_rounded,
                                        size: 16),
                                    label: Text(s.reject),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                          color: AppColors.error),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8),
                                      textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => _approveRequest(
                                        context, requestId),
                                    icon: const Icon(
                                        Icons.check_rounded,
                                        size: 16),
                                    label: Text(s.approve),
                                    style: ElevatedButton.styleFrom(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8),
                                      textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, Map<String, dynamic> resident, int apartmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(ctx).removeResident),
        content: Text(AppStrings.of(ctx).removeConfirm(
            '${resident['first_name']} ${resident['last_name']}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.of(ctx).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = context.read<ResidentProvider>();
              final success = await provider.removeResident(
                resident['id'] as int,
                apartmentId,
              );
              if (context.mounted) {
                final s = AppStrings.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? s.removeSuccess
                        : (provider.error ?? s.removeFailed)),
                    backgroundColor:
                        success ? Colors.green : AppColors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.of(ctx).removeBtn),
          ),
        ],
      ),
    );
  }

  void _approveRequest(BuildContext context, int requestId) {
    context.read<ResidentProvider>().approveRequest(requestId);
  }

  void _rejectRequest(BuildContext context, int requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(ctx).rejectRequestTitle),
        content: Text(AppStrings.of(ctx).rejectRequestMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.of(ctx).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ResidentProvider>().rejectRequest(requestId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.of(ctx).reject),
          ),
        ],
      ),
    );
  }
}
