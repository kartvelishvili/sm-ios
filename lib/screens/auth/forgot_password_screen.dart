import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  int _step = 1; // 1=request, 2=verify, 3=reset
  bool _isLoading = false;
  String? _phone;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final s = AppStrings.of(context);
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^5\d{8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.phoneFormat)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final response = await auth.forgotPasswordRequest(phone);
    setState(() => _isLoading = false);

    if (response.success) {
      setState(() {
        _phone = phone;
        _step = 2;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.codeSentSms)),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? s.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    final s = AppStrings.of(context);
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.enter6digitCode)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final response = await auth.forgotPasswordVerify(_phone!, code);
    setState(() => _isLoading = false);

    if (response.success) {
      setState(() => _step = 3);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? s.codeInvalid),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final s = AppStrings.of(context);
    final password = _newPasswordController.text;
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.passwordMinHint)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final response = await auth.forgotPasswordReset(
      _phone!,
      _codeController.text.trim(),
      password,
    );
    setState(() => _isLoading = false);

    if (response.success && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.passwordChanged),
          content: Text(s.signInWithNewPassword),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(s.signIn),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? s.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.forgotTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              Row(
                children: [
                  for (int i = 1; i <= 3; i++) ...[
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? AppColors.primary
                              : AppColors.adaptiveBorder(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < 3) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 32),

              if (_step == 1) ...[
                Text(
                  s.enterPhone,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  s.smsHint,
                  style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: s.phone,
                    hintText: '5XXXXXXXX',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestCode,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)
                        : Text(s.sendCode),
                  ),
                ),
              ],

              if (_step == 2) ...[
                Text(
                  s.enterSmsCode,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  s.codeSentTo(_phone!),
                  style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '000000',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)
                        : Text(s.confirm),
                  ),
                ),
              ],

              if (_step == 3) ...[
                Text(
                  s.newPassword,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  s.enterNewPassword,
                  style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: s.newPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)
                        : Text(s.changePassword),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
