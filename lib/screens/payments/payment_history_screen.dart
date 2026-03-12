import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/payment_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import 'payment_select_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadHistory();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<PaymentProvider>().loadMore();
      }
    });
  }

  Widget? _buildPayButton(BuildContext context) {
    final dashboard = context.read<DashboardProvider>();
    final data = dashboard.data;
    if (data == null) return null;
    return FloatingActionButton.extended(
      onPressed: () {
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
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.payment, color: Colors.black),
      label: Text(AppStrings.of(context).payment,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.paymentHistory)),
      floatingActionButton: _buildPayButton(context),
      body: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: s.all,
                  selected: _selectedStatus == null,
                  onTap: () => _applyStatusFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: s.paymentSuccessful,
                  selected: _selectedStatus == 'completed',
                  onTap: () => _applyStatusFilter('completed'),
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: s.paymentProcessing,
                  selected: _selectedStatus == 'pending',
                  onTap: () => _applyStatusFilter('pending'),
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: s.paymentFailedLabel,
                  selected: _selectedStatus == 'failed',
                  onTap: () => _applyStatusFilter('failed'),
                  color: AppColors.error,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.adaptiveBorder(context)),
          // List body
          Expanded(
            child: provider.isLoading && provider.history.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 48,
                                color: AppColors.adaptiveTextMuted(context)),
                            const SizedBox(height: 16),
                            Text(s.paymentHistoryEmpty,
                                style: TextStyle(color: AppColors.adaptiveTextSecondary(context))),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadHistory(status: _selectedStatus),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              provider.history.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.history.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _PaymentHistoryItem(
                                payment: provider.history[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _applyStatusFilter(String? status) {
    setState(() => _selectedStatus = status);
    context.read<PaymentProvider>().loadHistory(status: status);
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final PaymentItem payment;

  const _PaymentHistoryItem({required this.payment});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (payment.status) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          payment.paymentMonthLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payment.apartmentNumber != null)
              Text(AppStrings.of(context).paymentApt(payment.apartmentNumber!),
                  style: const TextStyle(fontSize: 12)),
            Text(payment.createdAt,
                style: TextStyle(
                    fontSize: 11, color: AppColors.adaptiveTextMuted(context))),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${payment.amount} ₾',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              payment.statusLabel,
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : AppColors.adaptiveTextMuted(context).withAlpha(60),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : AppColors.adaptiveTextSecondary(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
