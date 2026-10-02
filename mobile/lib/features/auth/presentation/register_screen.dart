import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/errors/api_exception.dart';
import '../data/auth_repository.dart';
import '../../main/presentation/main_nav_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const RegisterScreen({
    super.key,
    required this.authRepository,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authRepository.register(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      // Auto-login after registration
      await widget.authRepository.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainNavScreen(authRepository: widget.authRepository),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('timed out') || msg.contains('TimeoutException')) {
        setState(() {
          _errorMessage = 'Connection timed out. Please check your internet connection and try again.';
        });
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please check your internet connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDemoRegister() async {
    setState(() {
      _isLoading = true;
    });
    final email = _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : 'traveler@keralink.travel';
    final firstName = _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : 'Kerala';
    final lastName = _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : 'Explorer';

    await widget.authRepository.storage.saveTokens(
      accessToken: 'demo_offline_access_token',
      refreshToken: 'demo_offline_refresh_token',
      expiresAt: DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    );
    await widget.authRepository.storage.saveUserData(
      jsonEncode({
        'id': 'demo-usr-${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'roles': ['CUSTOMER'],
        'created_at': DateTime.now().toIso8601String(),
      }),
    );
    await widget.authRepository.checkSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavScreen(authRepository: widget.authRepository),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF7F3E8),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Unlock bespoke Kerala itineraries and live travel assistance',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                ),

                const SizedBox(height: 24),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // First & Last Name
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('First Name', style: TextStyle(fontSize: 12, color: Color(0xFFF7F3E8))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _firstNameController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration('First name'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last Name', style: TextStyle(fontSize: 12, color: Color(0xFFF7F3E8))),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _lastNameController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration('Last name'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Email
                const Text('Email Address', style: TextStyle(fontSize: 12, color: Color(0xFFF7F3E8))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('name@example.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone
                const Text('Phone Number (Optional)', style: TextStyle(fontSize: 12, color: Color(0xFFF7F3E8))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('+91 98460 00000'),
                ),

                const SizedBox(height: 16),

                // Password
                const Text('Password (Min. 8 characters)', style: TextStyle(fontSize: 12, color: Color(0xFFF7F3E8))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0D1F17),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D1F17)),
                          )
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 12),

                // Guest / Offline Mode Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _handleDemoRegister,
                    icon: const Icon(Icons.explore_outlined, size: 18, color: Color(0xFF10B981)),
                    label: const Text(
                      'Explore in Offline Demo Mode',
                      style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF142B20),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
