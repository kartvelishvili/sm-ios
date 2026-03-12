import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _personalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Complex> _complexes = [];
  List<Apartment> _apartments = [];
  Complex? _selectedComplex;
  Apartment? _selectedApartment;
  bool _isLoadingComplexes = true;
  bool _isLoadingApartments = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadComplexes();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _personalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadComplexes() async {
    final auth = context.read<AuthProvider>();
    final complexes = await auth.getComplexes();
    setState(() {
      _complexes = complexes;
      _isLoadingComplexes = false;
    });
  }

  Future<void> _loadApartments(int complexId) async {
    setState(() {
      _isLoadingApartments = true;
      _apartments = [];
      _selectedApartment = null;
    });

    final auth = context.read<AuthProvider>();
    final apartments = await auth.getApartments(complexId);
    setState(() {
      _apartments = apartments;
      _isLoadingApartments = false;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final s = AppStrings.of(context);
    if (_selectedComplex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.chooseComplex)),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      personalId: _personalIdController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      complexId: _selectedComplex!.id,
      apartmentId: _selectedApartment?.id,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      if (result['status'] == 'pending_approval') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(s.requestSent),
            content: Text(result['message'] as String? ??
                s.requestSentMsg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: Text(s.understood),
              ),
            ],
          ),
        );
      }
      // if 'active', auth state change will trigger navigation
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? s.registerFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.state == AuthState.loading;
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.registerTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(labelText: s.firstName),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? s.required_ : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(labelText: s.lastName),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? s.required_ : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Personal ID
                TextFormField(
                  controller: _personalIdController,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: s.personalId,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.required_;
                    if (v.length != 11) return s.personalIdHint;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: s.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    hintText: '5XXXXXXXX',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.required_;
                    if (!RegExp(r'^5\d{8}$').hasMatch(v)) {
                      return s.phoneFormat;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: s.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.required_;
                    if (!v.contains('@')) return s.invalidFormat;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: s.password,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.required_;
                    if (v.length < 6) return s.minChars6;
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Complex Dropdown
                if (_isLoadingComplexes)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<Complex>(
                    isExpanded: true,
                    initialValue: _selectedComplex,
                    decoration: InputDecoration(
                      labelText: s.complex,
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    items: _complexes.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (complex) {
                      setState(() => _selectedComplex = complex);
                      if (complex != null) _loadApartments(complex.id);
                    },
                    validator: (v) => v == null ? s.chooseComplex : null,
                  ),
                const SizedBox(height: 16),

                // Apartment Dropdown
                if (_isLoadingApartments)
                  const Center(child: CircularProgressIndicator())
                else if (_apartments.isNotEmpty)
                  DropdownButtonFormField<Apartment>(
                    isExpanded: true,
                    initialValue: _selectedApartment,
                    decoration: InputDecoration(
                      labelText: s.apartment,
                      prefixIcon: const Icon(Icons.door_front_door_outlined),
                    ),
                    items: _apartments.map((a) {
                      return DropdownMenuItem(
                        value: a,
                        child: Text(a.displayName),
                      );
                    }).toList(),
                    onChanged: (apt) {
                      setState(() => _selectedApartment = apt);
                    },
                  ),
                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(s.register),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to Login
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.alreadyHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
