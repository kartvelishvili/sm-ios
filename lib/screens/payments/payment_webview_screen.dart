import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String redirectUrl;
  final String orderId;

  const PaymentWebViewScreen({
    super.key,
    required this.redirectUrl,
    required this.orderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkPaymentResult(url);
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _checkPaymentResult(String url) {
    // BOG redirects to pay.smartluxy.ge/payment/success.php or fail.php
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final path = uri.path.toLowerCase();

    if (path.contains('/payment/success') || path.contains('/payment/callback')) {
      _verifyAndComplete();
    } else if (path.contains('/payment/fail')) {
      _onPaymentFailed();
    }
  }

  Future<void> _verifyAndComplete() async {
    if (_paymentCompleted) return;
    _paymentCompleted = true;

    // Verify payment status via API
    final paymentProvider = context.read<PaymentProvider>();
    final statusData = await paymentProvider.checkStatus(widget.orderId);

    if (!mounted) return;

    final status = statusData?['status'] as String? ?? '';

    if (status == 'completed') {
      _onPaymentSuccess();
    } else if (status == 'failed') {
      _paymentCompleted = false; // Allow retry
      _onPaymentFailed();
    } else {
      // pending — show pending message, then close
      _onPaymentPending();
    }
  }

  void _onPaymentSuccess() {
    if (!mounted) return;

    // Refresh dashboard
    context.read<DashboardProvider>().loadDashboard();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: Text(AppStrings.of(context).paymentSuccess),
        content: Text(AppStrings.of(context).paymentSuccessMsg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
              // Pop back to main screen (webview + select screen)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(AppStrings.of(context).close),
          ),
        ],
      ),
    );
  }

  void _onPaymentPending() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.hourglass_top, color: AppColors.warning, size: 48),
        title: Text(AppStrings.of(context).processing),
        content: Text(AppStrings.of(context).paymentPendingMsg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(AppStrings.of(context).close),
          ),
        ],
      ),
    );
  }

  void _onPaymentFailed() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error, color: AppColors.error, size: 48),
        title: Text(AppStrings.of(context).paymentFailed),
        content: Text(AppStrings.of(context).paymentFailedMsg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // just close webview, stay on select
            },
            child: Text(AppStrings.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).paymentTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(AppStrings.of(context).cancelPayment),
                content: Text(AppStrings.of(context).cancelPaymentMsg),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(AppStrings.of(context).cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(AppStrings.of(context).yes),
                  ),
                ],
              ),
            );
            if (shouldPop == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
