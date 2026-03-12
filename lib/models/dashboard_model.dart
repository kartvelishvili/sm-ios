/// Models matching the actual API response from /dashboard/index.php

class DashboardData {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? complex;
  final List<Map<String, dynamic>> apartments;
  final int? selectedApartmentId;
  final BillingInfo billing;
  final PaymentStatusInfo paymentStatus;
  final List<DebtItem> debts;
  final double totalDebt;
  final AccessStatus accessStatus;
  final ActiveCredit? activeCredit;
  final List<FutureMonth> futureMonths;
  final ComplexProgress? complexProgress;
  final List<PendingApproval> pendingApprovals;
  final List<ResidentInfo> residents;
  final Map<String, dynamic>? latestPayment;

  DashboardData({
    required this.user,
    this.complex,
    required this.apartments,
    this.selectedApartmentId,
    required this.billing,
    required this.paymentStatus,
    required this.debts,
    required this.totalDebt,
    required this.accessStatus,
    this.activeCredit,
    required this.futureMonths,
    this.complexProgress,
    required this.pendingApprovals,
    required this.residents,
    this.latestPayment,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // debts can be an object {total_amount, count, months[]} or a list
    final debtsRaw = json['debts'];
    List<DebtItem> debtsList = [];
    double totalDebt = 0;
    if (debtsRaw is Map<String, dynamic>) {
      totalDebt = (debtsRaw['total_amount'] as num?)?.toDouble() ?? 0;
      debtsList = (debtsRaw['months'] as List?)
              ?.map((d) => DebtItem.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [];
    } else if (debtsRaw is List) {
      debtsList = debtsRaw
          .map((d) => DebtItem.fromJson(d as Map<String, dynamic>))
          .toList();
      totalDebt = (json['total_debt'] as num?)?.toDouble() ?? 0;
    }

    return DashboardData(
      user: json['user'] as Map<String, dynamic>? ?? {},
      complex: json['complex'] as Map<String, dynamic>?,
      apartments: (json['apartments'] as List?)
              ?.map((a) => a as Map<String, dynamic>)
              .toList() ??
          [],
      selectedApartmentId: json['selected_apartment_id'] as int?,
      billing: BillingInfo.fromJson(
          json['billing'] as Map<String, dynamic>? ?? {}),
      paymentStatus: PaymentStatusInfo.fromJson(
          json['payment_status'] as Map<String, dynamic>? ?? {}),
      debts: debtsList,
      totalDebt: totalDebt,
      accessStatus: AccessStatus.fromJson(
          json['access'] as Map<String, dynamic>? ??
              json['access_status'] as Map<String, dynamic>? ??
              {}),
      activeCredit: json['active_credit'] != null
          ? ActiveCredit.fromJson(
              json['active_credit'] as Map<String, dynamic>)
          : null,
      futureMonths: (json['future_months'] as List?)
              ?.map((m) => FutureMonth.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      complexProgress: json['complex_progress'] != null
          ? ComplexProgress.fromJson(
              json['complex_progress'] as Map<String, dynamic>)
          : null,
      pendingApprovals: (json['pending_approvals'] as List?)
              ?.map(
                  (p) => PendingApproval.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      residents: (json['residents'] as List?)
              ?.map((r) => ResidentInfo.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      latestPayment: json['latest_payment'] as Map<String, dynamic>?,
    );
  }
}

class BillingInfo {
  final String currentMonth;
  final String currentMonthLabel;
  final double baseFee;
  final int apartmentCount;
  final int discountPercent;
  final double subtotal;
  final double discountAmount;
  final double perApartmentFee;
  final int parkingCount;
  final double parkingFee;
  final double totalMonthlyFee;

  BillingInfo({
    required this.currentMonth,
    required this.currentMonthLabel,
    required this.baseFee,
    this.apartmentCount = 1,
    this.discountPercent = 0,
    required this.subtotal,
    this.discountAmount = 0,
    required this.perApartmentFee,
    this.parkingCount = 0,
    required this.parkingFee,
    required this.totalMonthlyFee,
  });

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    return BillingInfo(
      currentMonth: json['current_month'] as String? ??
          json['billing_month'] as String? ??
          '',
      currentMonthLabel: json['current_month_label'] as String? ??
          json['billing_month_label'] as String? ??
          '',
      baseFee: (json['base_fee'] as num?)?.toDouble() ??
          (json['monthly_fee'] as num?)?.toDouble() ??
          0,
      apartmentCount: json['apartment_count'] as int? ?? 1,
      discountPercent: json['discount_percent'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      perApartmentFee:
          (json['per_apartment_fee'] as num?)?.toDouble() ?? 0,
      parkingCount: json['parking_count'] as int? ?? 0,
      parkingFee: (json['parking_fee'] as num?)?.toDouble() ?? 0,
      totalMonthlyFee: (json['total_monthly_fee'] as num?)?.toDouble() ??
          (json['total_fee'] as num?)?.toDouble() ??
          0,
    );
  }
}

class PaymentStatusInfo {
  final double paidAmount;
  final double remainingAmount;
  final bool isPaid;
  final bool isFullyPaid;
  final bool isPartiallyPaid;

  PaymentStatusInfo({
    this.paidAmount = 0,
    this.remainingAmount = 0,
    required this.isPaid,
    this.isFullyPaid = false,
    this.isPartiallyPaid = false,
  });

  factory PaymentStatusInfo.fromJson(Map<String, dynamic> json) {
    return PaymentStatusInfo(
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
      isPaid: json['is_paid'] == true || json['is_fully_paid'] == true,
      isFullyPaid: json['is_fully_paid'] == true,
      isPartiallyPaid: json['is_partially_paid'] == true,
    );
  }
}

class DebtItem {
  final int? id;
  final String billingMonth;
  final String billingMonthLabel;
  final double amount;
  final String? type;
  final String? createdAt;

  DebtItem({
    this.id,
    required this.billingMonth,
    required this.billingMonthLabel,
    required this.amount,
    this.type,
    this.createdAt,
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    return DebtItem(
      id: json['id'] as int?,
      billingMonth: json['billing_month'] as String? ??
          json['month'] as String? ??
          '',
      billingMonthLabel: json['billing_month_label'] as String? ??
          json['label'] as String? ??
          '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ActiveCredit {
  final int id;
  final double amount;
  final double dailyRate;
  final int daysGranted;
  final int daysRemaining;
  final String startDate;
  final String endDate;
  final String? note;
  final String? createdAt;
  final int? gapDays;
  final double? gapAmount;
  final double? gapDailyRate;
  final String? gapDeadline;

  ActiveCredit({
    required this.id,
    required this.amount,
    required this.dailyRate,
    required this.daysGranted,
    required this.daysRemaining,
    required this.startDate,
    required this.endDate,
    this.note,
    this.createdAt,
    this.gapDays,
    this.gapAmount,
    this.gapDailyRate,
    this.gapDeadline,
  });

  bool get hasGap => gapDays != null && gapDays! > 0;

  factory ActiveCredit.fromJson(Map<String, dynamic> json) {
    return ActiveCredit(
      id: json['id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0,
      daysGranted: json['days_granted'] as int? ?? 0,
      daysRemaining: json['days_remaining'] as int? ?? 0,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      gapDays: json['gap_days'] as int?,
      gapAmount: (json['gap_amount'] as num?)?.toDouble(),
      gapDailyRate: (json['gap_daily_rate'] as num?)?.toDouble(),
      gapDeadline: json['gap_deadline'] as String?,
    );
  }
}

class AccessStatus {
  final bool hasAccess;
  final bool hasEverPaid;
  final bool hasCredit;
  final int creditDaysRemaining;
  final String? reason;
  final int graceDaysLeft;
  final bool isGracePeriod;
  final bool adminLocked;
  final bool elevatorLocked;
  final bool doorLocked;

  AccessStatus({
    required this.hasAccess,
    this.hasEverPaid = false,
    this.hasCredit = false,
    this.creditDaysRemaining = 0,
    this.reason,
    this.graceDaysLeft = 0,
    this.isGracePeriod = false,
    this.adminLocked = false,
    this.elevatorLocked = false,
    this.doorLocked = false,
  });

  String get statusLabel {
    if (adminLocked) return 'ადმინის მიერ დაბლოკილი';
    if (isGracePeriod) return 'Grace Period — $graceDaysLeft დღე დარჩა';
    if (hasAccess) {
      if (reason == 'paid') return 'გადახდილი — აქტიური';
      return 'აქტიური';
    }
    if (reason == 'never_paid') return 'არასდროს გადახდილი';
    if (reason == 'blocked') return 'დაბლოკილი — გადაუხდელობა';
    if (!hasEverPaid) return 'არასდროს გადახდილი';
    return 'დაბლოკილი';
  }

  factory AccessStatus.fromJson(Map<String, dynamic> json) {
    return AccessStatus(
      hasAccess: json['has_access'] == true,
      hasEverPaid: json['has_ever_paid'] == true,
      hasCredit: json['has_credit'] == true,
      creditDaysRemaining: json['credit_days_remaining'] as int? ?? 0,
      reason: json['reason'] as String?,
      graceDaysLeft: json['grace_days_left'] as int? ?? 0,
      isGracePeriod: json['is_grace_period'] == true,
      adminLocked: json['admin_locked'] == true,
      elevatorLocked: json['elevator_locked'] == true,
      doorLocked: json['door_locked'] == true,
    );
  }
}

class FutureMonth {
  final String value;
  final String label;
  final bool paid;
  final bool isDebt;
  final bool isCurrent;
  final double? amount;
  final List<int> debtIds;
  final double? debtAmount;

  FutureMonth({
    required this.value,
    required this.label,
    this.paid = false,
    this.isDebt = false,
    this.isCurrent = false,
    this.amount,
    this.debtIds = const [],
    this.debtAmount,
  });

  /// Effective amount for display: debt amount if debt, or base amount, or 0
  double get effectiveAmount => debtAmount ?? amount ?? 0;

  factory FutureMonth.fromJson(Map<String, dynamic> json) {
    return FutureMonth(
      value: json['value'] as String? ??
          json['month'] as String? ??
          '',
      label: json['label'] as String? ?? '',
      paid: json['paid'] == true,
      isDebt: json['is_debt'] == true,
      isCurrent: json['is_current'] == true,
      amount: (json['amount'] as num?)?.toDouble(),
      debtIds: (json['debt_ids'] as List?)?.cast<int>() ?? [],
      debtAmount: (json['debt_amount'] as num?)?.toDouble(),
    );
  }
}

class ComplexProgress {
  final int total;
  final int paid;
  final double percent;

  ComplexProgress({
    required this.total,
    required this.paid,
    required this.percent,
  });

  factory ComplexProgress.fromJson(Map<String, dynamic> json) {
    return ComplexProgress(
      total: json['total'] as int? ??
          json['total_apartments'] as int? ??
          0,
      paid: json['paid'] as int? ??
          json['paid_apartments'] as int? ??
          0,
      percent: (json['percent'] as num?)?.toDouble() ??
          (json['paid_percent'] as num?)?.toDouble() ??
          0,
    );
  }
}

class PendingApproval {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? apartmentNumber;
  final String createdAt;

  PendingApproval({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.apartmentNumber,
    required this.createdAt,
  });

  String get fullName =>
      '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory PendingApproval.fromJson(Map<String, dynamic> json) {
    return PendingApproval(
      id: json['request_id'] as int? ?? json['id'] as int? ?? 0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      apartmentNumber: json['apartment_number']?.toString(),
      createdAt: json['request_date'] as String? ?? json['created_at'] as String? ?? '',
    );
  }
}

class ResidentInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? profileImage;
  final String role;
  final String? joinedAt;
  final bool canRemove;
  final bool isMe;

  ResidentInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.profileImage,
    required this.role,
    this.joinedAt,
    this.canRemove = false,
    this.isMe = false,
  });

  String get fullName => '$firstName $lastName';

  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'მფლობელი';
      case 'resident':
        return 'მცხოვრები';
      default:
        return role;
    }
  }

  factory ResidentInfo.fromJson(Map<String, dynamic> json) {
    return ResidentInfo(
      id: json['id'] as int? ??
          json['user_id'] as int? ??
          0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profileImage: json['profile_image'] as String?,
      role: json['role'] as String? ?? '',
      joinedAt: json['joined_at'] as String?,
      canRemove: json['can_remove'] == true,
      isMe: json['is_me'] == true || json['is_self'] == true,
    );
  }
}
