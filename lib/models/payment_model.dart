class PaymentItem {
  final int id;
  final String orderId;
  final double amount;
  final String status;
  final String paymentMonth;
  final String paymentMonthLabel;
  final String? apartmentNumber;
  final String? complexName;
  final String createdAt;
  final String? completedAt;

  PaymentItem({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.paymentMonth,
    required this.paymentMonthLabel,
    this.apartmentNumber,
    this.complexName,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'წარმატებული';
      case 'pending':
        return 'მუშავდება';
      case 'failed':
        return 'წარუმატებელი';
      default:
        return status;
    }
  }

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    return PaymentItem(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      paymentMonth: json['payment_month'] as String? ?? '',
      paymentMonthLabel: json['payment_month_label'] as String? ?? '',
      apartmentNumber: json['apartment_number'] as String?,
      complexName: json['complex_name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
    );
  }
}

class PaymentProcessResult {
  final String orderId;
  final String redirectUrl;
  final double totalAmount;
  final List<PaymentLineItem> items;

  PaymentProcessResult({
    required this.orderId,
    required this.redirectUrl,
    required this.totalAmount,
    required this.items,
  });

  factory PaymentProcessResult.fromJson(Map<String, dynamic> json) {
    return PaymentProcessResult(
      orderId: json['order_id'] as String? ?? '',
      redirectUrl: json['redirect_url'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List?)
              ?.map((i) =>
                  PaymentLineItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaymentLineItem {
  final String month;
  final String label;
  final double amount;
  final String type;

  PaymentLineItem({
    required this.month,
    required this.label,
    required this.amount,
    required this.type,
  });

  String get typeLabel {
    switch (type) {
      case 'debt':
        return 'დავალიანება';
      case 'current':
        return 'მიმდინარე';
      case 'advance':
        return 'წინასწარი';
      default:
        return type;
    }
  }

  factory PaymentLineItem.fromJson(Map<String, dynamic> json) {
    return PaymentLineItem(
      month: json['month'] as String? ?? '',
      label: json['label'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? '',
    );
  }
}
