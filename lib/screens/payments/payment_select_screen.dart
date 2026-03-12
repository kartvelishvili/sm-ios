import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../models/dashboard_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import 'payment_webview_screen.dart';

class PaymentSelectScreen extends StatefulWidget {
  final List<FutureMonth> futureMonths;
  final List<DebtItem> debts;
  final double monthlyFee;

  const PaymentSelectScreen({
    super.key,
    required this.futureMonths,
    required this.debts,
    required this.monthlyFee,
  });

  @override
  State<PaymentSelectScreen> createState() => _PaymentSelectScreenState();
}

class _PaymentSelectScreenState extends State<PaymentSelectScreen> {
  final Set<String> _selectedMonths = {};

  double get _totalAmount {
    double total = 0;
    for (final month in _selectedMonths) {
      // Check debts
      final debt = widget.debts.where((d) => d.billingMonth == month).firstOrNull;
      if (debt != null) {
        total += debt.amount;
        continue;
      }
      // Check future months
      final fm =
          widget.futureMonths.where((m) => m.value == month).firstOrNull;
      if (fm != null) {
        final amt = fm.effectiveAmount;
        total += amt > 0 ? amt : widget.monthlyFee;
      }
    }
    return total;
  }

  Future<void> _processPayment() async {
    if (_selectedMonths.isEmpty) return;

    final provider = context.read<PaymentProvider>();
    final result =
        await provider.processPayment(_selectedMonths.toList());

    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            redirectUrl: result.redirectUrl,
            orderId: result.orderId,
          ),
        ),
      );
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = context.watch<PaymentProvider>().isProcessing;

    // Combine debts + future months
    final allMonths = <_MonthOption>[];

    for (final debt in widget.debts) {
      allMonths.add(_MonthOption(
        month: debt.billingMonth,
        label: debt.billingMonthLabel,
        amount: debt.amount,
        type: 'debt',
      ));
    }

    for (final fm in widget.futureMonths) {
      if (!allMonths.any((m) => m.month == fm.value)) {
        final fmAmount = fm.effectiveAmount;
        allMonths.add(_MonthOption(
          month: fm.value,
          label: fm.label,
          amount: fmAmount > 0 ? fmAmount : widget.monthlyFee,
          type: fm.isDebt
              ? 'debt'
              : fm.isCurrent
                  ? 'current'
                  : 'advance',
          paid: fm.paid,
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context).paymentTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allMonths.length,
              itemBuilder: (context, index) {
                final item = allMonths[index];
                final isSelected = _selectedMonths.contains(item.month);
                final isPaid = item.paid;

                return Opacity(
                  opacity: isPaid ? 0.5 : 1.0,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: isPaid ? true : isSelected,
                      onChanged: isPaid
                          ? null
                          : (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedMonths.add(item.month);
                                } else {
                                  _selectedMonths.remove(item.month);
                                }
                              });
                            },
                      title: Text(
                        item.label,
                        style: TextStyle(
                          decoration:
                              isPaid ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        isPaid
                            ? AppStrings.of(context).paid
                            : item.typeLabelOf(context),
                        style: TextStyle(
                          color: isPaid
                              ? Colors.green
                              : item.type == 'debt'
                                  ? AppColors.error
                                  : item.type == 'current'
                                      ? AppColors.warning
                                      : AppColors.adaptiveTextSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      secondary: Text(
                        '${item.amount} ₾',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration:
                              isPaid ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      activeColor: isPaid ? Colors.green : AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.of(context).totalMonths(_selectedMonths.length),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_totalAmount.toStringAsFixed(2)} ₾',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedMonths.isEmpty || isProcessing
                          ? null
                          : _processPayment,
                      child: isProcessing
                          ? const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)
                          : Text(AppStrings.of(context).payment),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthOption {
  final String month;
  final String label;
  final double amount;
  final String type;
  final bool paid;

  _MonthOption({
    required this.month,
    required this.label,
    required this.amount,
    required this.type,
    this.paid = false,
  });

  String typeLabelOf(BuildContext context) {
    final s = AppStrings.of(context);
    switch (type) {
      case 'debt':
        return s.debt;
      case 'current':
        return s.currentMonth;
      case 'advance':
        return s.prepayment;
      default:
        return type;
    }
  }
}
