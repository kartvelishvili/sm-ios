import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/dashboard_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../services/notification_service.dart';
import '../payments/payment_select_screen.dart';
import '../../providers/message_provider.dart';
import '../../providers/poll_provider.dart';
import '../polls/poll_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      context.read<PollProvider>().loadPolls();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final user = context.read<AuthProvider>().user;

    if (dashboard.data == null) {
      if (!dashboard.isLoading && dashboard.error != null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(dashboard.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => dashboard.loadDashboard(),
                  child: Text(AppStrings.of(context).retryBtn),
                ),
              ],
            ),
          ),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = dashboard.data!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => dashboard.loadDashboard(
            apartmentId: dashboard.selectedApartmentId),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              leading: _NotifBellIcon(),
              title: Text('${user?.firstName ?? ''} 👋'),
              actions: [
                if (data.apartments.length > 1)
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.apartment),
                    onSelected: (id) => dashboard.selectApartment(id),
                    itemBuilder: (_) => data.apartments.map((apt) {
                      return PopupMenuItem<int>(
                        value: apt['id'] as int,
                        child: Text(
                            AppStrings.of(context).aptBuilding(apt['apartment_number']?.toString() ?? '', apt['building']?.toString() ?? '')),
                      );
                    }).toList(),
                  ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // --- Access Status Card ---
                  _AccessStatusCard(accessStatus: data.accessStatus),
                  const SizedBox(height: 16),

                  // --- Active Polls (below access status) ---
                  _ActivePollsSection(),

                  // --- Credit Days Card ---
                  if (data.activeCredit != null) ...[
                    _CreditDaysCard(credit: data.activeCredit!),
                    const SizedBox(height: 16),
                  ],

                  // --- Billing Card ---
                  _BillingCard(
                    billing: data.billing,
                    paymentStatus: data.paymentStatus,
                    totalDebt: data.totalDebt,
                    paymentDeadlineDay: data.complex?['payment_deadline_day'] as int? ?? 20,
                    onPayPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentSelectScreen(
                            futureMonths: data.futureMonths,
                            debts: data.debts,
                            monthlyFee: data.billing.totalMonthlyFee,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Complex Progress ---
                  if (data.complexProgress != null) ...[                    _ComplexProgressWidget(
                      progress: data.complexProgress!,
                      complexName: data.complex?['name'] as String? ?? '',
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- Residents ---
                  if (data.residents.isNotEmpty) ...[                    _ResidentsCard(residents: data.residents),
                    const SizedBox(height: 16),
                  ],

                  // --- Debts ---
                  if (data.debts.isNotEmpty) ...[
                    _DebtCard(debts: data.debts, totalDebt: data.totalDebt),
                    const SizedBox(height: 16),
                  ],



                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Access Status Card ---
class _AccessStatusCard extends StatelessWidget {
  final AccessStatus accessStatus;

  const _AccessStatusCard({required this.accessStatus});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    Color color;
    IconData icon;
    String title;
    String statusLabel;

    if (accessStatus.adminLocked) {
      color = AppColors.error;
      icon = Icons.block_rounded;
      title = s.accessBlocked;
      statusLabel = s.adminBlocked;
    } else if (accessStatus.isGracePeriod) {
      color = AppColors.warning;
      icon = Icons.timer_rounded;
      title = 'Grace Period';
      statusLabel = s.gracePeriod(accessStatus.graceDaysLeft);
    } else if (accessStatus.hasAccess) {
      color = AppColors.success;
      icon = Icons.lock_open_rounded;
      title = s.accessActive;
      statusLabel = accessStatus.reason == 'paid' ? s.paidActive : s.active;
    } else {
      color = AppColors.error;
      icon = Icons.lock_rounded;
      title = s.accessLimited;
      if (accessStatus.reason == 'never_paid') {
        statusLabel = s.neverPaid;
      } else if (accessStatus.reason == 'blocked') {
        statusLabel = s.blockedUnpaid;
      } else if (!accessStatus.hasEverPaid) {
        statusLabel = s.neverPaid;
      } else {
        statusLabel = s.blocked;
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: AppColors.cardGradient(context, accent: color),
        child: Column(
          children: [
            // Top accent line
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withAlpha(0),
                    color,
                    color.withAlpha(180),
                    color.withAlpha(0),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withAlpha(35),
                          color.withAlpha(15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withAlpha(40)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(20),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withAlpha(40)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: color.withAlpha(200),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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

// --- Credit Days Card ---
class _CreditDaysCard extends StatelessWidget {
  final ActiveCredit credit;

  const _CreditDaysCard({required this.credit});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final progress = credit.daysGranted > 0
        ? credit.daysRemaining / credit.daysGranted
        : 0.0;
    final isLow = credit.daysRemaining <= 30;
    final accentColor = isLow ? AppColors.warning : const Color(0xFF4FC3F7);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: AppColors.cardGradient(context, accent: accentColor),
        child: Column(
          children: [
            // Accent line
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withAlpha(0),
                    accentColor,
                    accentColor.withAlpha(180),
                    accentColor.withAlpha(0),
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
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withAlpha(35),
                              accentColor.withAlpha(15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withAlpha(40)),
                        ),
                        child: Icon(Icons.credit_score_rounded,
                            size: 22, color: accentColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.creditDays,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: accentColor.withAlpha(40)),
                              ),
                              child: Text(
                                s.creditActive,
                                style: TextStyle(
                                  color: accentColor.withAlpha(200),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Days remaining (big number)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${credit.daysRemaining}',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.creditDaysRemaining(credit.daysRemaining),
                          style: TextStyle(
                            color: AppColors.adaptiveTextSecondary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.adaptiveBorder(context).withAlpha(80),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info rows
                  _creditInfoRow(context,
                      s.creditAmount, '${credit.amount.toStringAsFixed(0)} ₾'),
                  const SizedBox(height: 8),
                  _creditInfoRow(context, s.creditDailyRate,
                      '${credit.dailyRate.toStringAsFixed(0)} ₾/${s.creditDailyRate.contains('ტარიფი') ? 'დღე' : 'day'}'),
                  const SizedBox(height: 8),
                  _creditInfoRow(context,
                      s.creditDaysGranted, '${credit.daysGranted}'),
                  const SizedBox(height: 8),
                  _creditInfoRow(context,
                      s.creditPeriod, '${credit.startDate} → ${credit.endDate}'),

                  // Gap warning
                  if (credit.hasGap) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withAlpha(40)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 18, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.creditGapWarning(
                                credit.gapDays!,
                                credit.gapDailyRate ?? credit.dailyRate,
                                credit.gapAmount!,
                                credit.gapDeadline!,
                              ),
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _creditInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.adaptiveTextSecondary(context),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- Billing Card ---
class _BillingCard extends StatelessWidget {
  final BillingInfo billing;
  final PaymentStatusInfo paymentStatus;
  final double totalDebt;
  final int paymentDeadlineDay;
  final VoidCallback onPayPressed;

  const _BillingCard({
    required this.billing,
    required this.paymentStatus,
    required this.totalDebt,
    required this.paymentDeadlineDay,
    required this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: AppColors.cardGradient(context),
        child: Column(
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with calendar icon
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
                        child: const Icon(Icons.calendar_month_rounded,
                            size: 22, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          billing.currentMonthLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (paymentStatus.isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.success.withAlpha(50)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                s.paid,
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Fee rows
                  _FeeRow(
                    icon: Icons.door_front_door_rounded,
                    iconColor: AppColors.info,
                    label: s.residential,
                    value: '${billing.perApartmentFee} ₾',
                  ),
                  if (billing.parkingCount > 0)
                    _FeeRow(
                      icon: Icons.local_parking_rounded,
                      iconColor: AppColors.warning,
                      label: s.parking,
                      value: '${billing.parkingFee} ₾',
                    ),
                  if (billing.discountPercent > 0)
                    _FeeRow(
                      icon: Icons.discount_rounded,
                      iconColor: AppColors.success,
                      label: s.discount,
                      value: '-${billing.discountPercent}%',
                      valueColor: AppColors.success,
                    ),

                  const SizedBox(height: 12),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.adaptiveBorder(context).withAlpha(0),
                          AppColors.primary.withAlpha(50),
                          AppColors.adaptiveBorder(context).withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Total row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.total,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0x20D4AF37), Color(0x10D4AF37)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withAlpha(60)),
                        ),
                        child: Text(
                          '${billing.totalMonthlyFee} ₾',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Deadline progress bar
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final now = DateTime.now();
                    final d = paymentDeadlineDay;

                    final DateTime cycleStart;
                    final DateTime cycleEnd;
                    if (now.day >= d) {
                      cycleStart = DateTime(now.year, now.month, d);
                      cycleEnd = DateTime(now.year, now.month + 1, d);
                    } else {
                      cycleStart = DateTime(now.year, now.month - 1, d);
                      cycleEnd = DateTime(now.year, now.month, d);
                    }

                    final totalDays = cycleEnd.difference(cycleStart).inDays;
                    final elapsed = now.difference(cycleStart).inDays;
                    final remaining = cycleEnd.difference(now).inDays;
                    final progress = totalDays > 0
                        ? (elapsed / totalDays).clamp(0.0, 1.0)
                        : 0.0;

                    final Color barColor;
                    if (remaining <= 0) {
                      barColor = AppColors.error;
                    } else if (remaining <= 3) {
                      barColor = AppColors.warning;
                    } else {
                      barColor = AppColors.primary;
                    }

                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.adaptiveBorder(context).withAlpha(80),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        barColor,
                                        barColor.withAlpha(180),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: barColor.withAlpha(60),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (remaining > 0) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$remaining ${s.daysLeft}',
                              style: TextStyle(
                                color: barColor.withAlpha(180),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),

                  const SizedBox(height: 14),
                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: paymentStatus.isPaid
                            ? const LinearGradient(
                                colors: [Color(0xFF2A6F4F), Color(0xFF1A4A35)])
                            : const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                  AppColors.primary,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (paymentStatus.isPaid
                                    ? AppColors.success
                                    : AppColors.primary)
                                .withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: onPayPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          paymentStatus.isPaid
                              ? Icons.schedule_send_rounded
                              : Icons.payment_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          paymentStatus.isPaid ? s.prepayment : s.payment,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
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

class _FeeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _FeeRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 14,
                )),
          ),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}

// --- Debt Card ---
class _DebtCard extends StatelessWidget {
  final List<DebtItem> debts;
  final double totalDebt;

  const _DebtCard({required this.debts, required this.totalDebt});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                Text(
                  AppStrings.of(context).debtTotal(totalDebt.toString()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...debts.map((debt) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(debt.billingMonthLabel),
                      Text('${debt.amount} ₾',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// --- Complex Progress Widget (animated, pulsating) ---
class _ComplexProgressWidget extends StatefulWidget {
  final ComplexProgress progress;
  final String complexName;
  const _ComplexProgressWidget({required this.progress, required this.complexName});
  @override
  State<_ComplexProgressWidget> createState() => _ComplexProgressWidgetState();
}

class _ComplexProgressWidgetState extends State<_ComplexProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _stat1Anim;
  late Animation<double> _stat2Anim;
  late Animation<double> _stat3Anim;
  late Animation<double> _percentCountAnim;

  @override
  void initState() {
    super.initState();
    final target = widget.progress.percent / 100;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0, 0.25, curve: Curves.easeIn)),
    );
    _percentCountAnim = Tween<double>(begin: 0, end: widget.progress.percent).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic)),
    );
    _progressAnim = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic)),
    );
    _stat1Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.55, 0.72, curve: Curves.easeOut)),
    );
    _stat2Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.63, 0.80, curve: Curves.easeOut)),
    );
    _stat3Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.71, 0.88, curve: Curves.easeOut)),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final paid = widget.progress.paid;
    final total = widget.progress.total;
    final unpaid = total - paid;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _pulseController]),
      builder: (context, child) {
        final percent = _percentCountAnim.value.toStringAsFixed(0);

        return Opacity(
          opacity: _fadeAnim.value,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: AppColors.cardGradient(context).copyWith(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with complex name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0x33D4AF37), Color(0x11D4AF37)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.apartment_rounded, size: 20, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.complexName.isNotEmpty)
                                Text(
                                  widget.complexName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                s.complexStats,
                                style: TextStyle(
                                  color: AppColors.adaptiveTextSecondary(context),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Pulsating live indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success.withAlpha((_pulseAnim.value * 255).round()),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withAlpha((_pulseAnim.value * 80).round()),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Percentage row with animated count
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$percent%',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 42,
                            color: AppColors.adaptiveTextPrimary(context),
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            s.paid,
                            style: TextStyle(
                              color: AppColors.adaptiveTextSecondary(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pulsating linear progress bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withAlpha((_pulseAnim.value * 50).round()),
                            blurRadius: 12,
                            spreadRadius: -2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 10,
                          child: Stack(
                            children: [
                              // Track
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.adaptiveBorder(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Filled portion with gradient
                              FractionallySizedBox(
                                widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4AF37), Color(0xFF10B981)],
                                    ),
                                  ),
                                ),
                              ),
                              // Shimmer sweep overlay
                              FractionallySizedBox(
                                widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      begin: Alignment(-1.0 + 2.0 * _pulseAnim.value, 0),
                                      end: Alignment(-0.5 + 2.0 * _pulseAnim.value, 0),
                                      colors: [
                                        Colors.white.withAlpha(0),
                                        Colors.white.withAlpha(40),
                                        Colors.white.withAlpha(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stat tiles with staggered entrance
                    Row(
                      children: [
                        Expanded(
                          child: _AnimatedStatTile(
                            animation: _stat1Anim,
                            color: AppColors.success,
                            value: '$paid',
                            label: s.paid,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AnimatedStatTile(
                            animation: _stat2Anim,
                            color: AppColors.warning,
                            value: '$unpaid',
                            label: s.unpaid,
                            icon: Icons.pending_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AnimatedStatTile(
                            animation: _stat3Anim,
                            color: AppColors.primary,
                            value: '$total',
                            label: s.total,
                            icon: Icons.home_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated stat tile with slide-up + fade entrance
class _AnimatedStatTile extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final String value;
  final String label;
  final IconData icon;

  const _AnimatedStatTile({
    required this.animation,
    required this.color,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 20 * (1 - animation.value)),
      child: Opacity(
        opacity: animation.value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(30)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.adaptiveTextPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.adaptiveTextSecondary(context),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Residents Card ---
class _ResidentsCard extends StatelessWidget {
  final List<ResidentInfo> residents;

  const _ResidentsCard({required this.residents});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: AppColors.cardGradient(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_rounded, size: 18, color: AppColors.info),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.residentsCount(residents.length),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/residents'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withAlpha(40)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.seeAll,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Residents list
              ...residents.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final isOwner = r.role == 'owner' || idx == 0;
                final roleColor = isOwner ? AppColors.primary : AppColors.success;
                final roleName = isOwner ? s.owner : r.role == 'resident' ? s.resident : r.role;
                final hasImage = r.profileImage != null && r.profileImage!.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: r.isMe
                          ? AppColors.primary.withAlpha(8)
                          : AppColors.adaptiveSurface(context).withAlpha(120),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: r.isMe
                            ? AppColors.primary.withAlpha(40)
                            : AppColors.adaptiveBorder(context).withAlpha(60),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar with photo
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: roleColor.withAlpha(80),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: roleColor.withAlpha(20),
                            backgroundImage: hasImage
                                ? NetworkImage(
                                    'https://pay.smartluxy.ge${r.profileImage}')
                                : null,
                            child: !hasImage
                                ? Text(
                                    r.firstName.isNotEmpty
                                        ? r.firstName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: roleColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    isOwner
                                        ? Icons.star_rounded
                                        : Icons.person_rounded,
                                    size: 13,
                                    color: roleColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    roleName,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Role badge (owner = gold star, me = highlighted)
                        if (r.isMe)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0x20D4AF37), Color(0x10D4AF37)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primary.withAlpha(60)),
                            ),
                            child: Text(
                              s.me,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Active Polls on Dashboard ───
class _ActivePollsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final polls = context.watch<PollProvider>().activePolls;
    if (polls.isEmpty) return const SizedBox();

    final s = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...polls.map((poll) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PollDetailScreen(pollId: poll.id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.info.withAlpha(50)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.info.withAlpha(12),
                      AppColors.adaptiveCard(context),
                      AppColors.info.withAlpha(6),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accent line
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.info.withAlpha(0),
                            AppColors.info,
                            AppColors.info.withAlpha(180),
                            AppColors.info.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                    // Image if present
                    if (poll.imageUrl != null && poll.imageUrl!.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.network(
                            poll.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.info.withAlpha(40)),
                            ),
                            child: Icon(Icons.poll_rounded,
                                size: 20, color: AppColors.info),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  poll.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color:
                                        AppColors.adaptiveTextPrimary(context),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withAlpha(20),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        s.pollActive,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                    if (poll.hasVoted) ...[
                                      const SizedBox(width: 6),
                                      Icon(Icons.check_circle,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          s.pollVoted,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      s.pollTotalVotes(poll.totalVotes),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.adaptiveTextMuted(
                                            context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.adaptiveTextMuted(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _NotifBellIcon extends StatefulWidget {
  @override
  State<_NotifBellIcon> createState() => _NotifBellIconState();
}

class _NotifBellIconState extends State<_NotifBellIcon> {
  @override
  void initState() {
    super.initState();
    NotificationService().addListener(_update);
  }

  @override
  void dispose() {
    NotificationService().removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifUnread = NotificationService().unreadCount;
    final msgUnread = context.watch<MessageProvider>().unreadCount;
    final total = notifUnread + msgUnread;

    return IconButton(
      icon: Badge(
        isLabelVisible: total > 0,
        label: Text(
          total > 9 ? '9+' : '$total',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pushNamed('/inbox');
      },
    );
  }
}