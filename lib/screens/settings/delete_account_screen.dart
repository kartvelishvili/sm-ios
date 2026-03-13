import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/storage_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _confirmed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitDeletionRequest() async {
    final s = AppStrings.of(context);
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteSelectReason)),
      );
      return;
    }
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.deleteConfirmRequired)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAccountTitle),
        content: Text(s.deleteFinalWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.deleteConfirmButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final api = ApiClient(StorageService());
      final response = await api.post(
        '/account/delete-request.php',
        data: {
          'reason': _selectedReason,
          'details': _detailsController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.success) {
        await context.read<AuthProvider>().logout();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (_) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.deleteRequestSent),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? s.deleteRequestFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).deleteRequestFailed),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final reasons = [
      s.deleteReasonNoUse,
      s.deleteReasonPrivacy,
      s.deleteReasonOtherService,
      s.deleteReasonDissatisfied,
      s.deleteReasonOther,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.deleteAccountTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.error.withAlpha(40)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.deleteWarning,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info section
            Text(
              s.deleteInfoTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.adaptiveTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.deleteInfoBody,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.adaptiveTextSecondary(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Reason selection
            Text(
              s.deleteReasonLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.adaptiveTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            ...reasons.map((reason) => RadioListTile<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (v) => setState(() => _selectedReason = v),
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  activeColor: AppColors.error,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
            const SizedBox(height: 16),

            // Additional details
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: s.deleteDetailsHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Confirmation checkbox
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: Text(
                s.deleteConfirmCheckbox,
                style: const TextStyle(fontSize: 13),
              ),
              activeColor: AppColors.error,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDeletionRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        s.deleteSubmitButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
