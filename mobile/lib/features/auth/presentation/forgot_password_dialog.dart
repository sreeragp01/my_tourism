import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final AuthRepository authRepository;
  final String initialEmail;
  final void Function(String email, String newPassword) onResetSuccess;

  const ForgotPasswordDialog({
    super.key,
    required this.authRepository,
    this.initialEmail = '',
    required this.onResetSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required AuthRepository authRepository,
    String initialEmail = '',
    required void Function(String email, String newPassword) onResetSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ForgotPasswordDialog(
        authRepository: authRepository,
        initialEmail: initialEmail,
        onResetSuccess: onResetSuccess,
      ),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  int _currentStep = 1; // 1 = Enter Email, 2 = Enter OTP & New Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await widget.authRepository.requestPasswordReset(email);
      setState(() {
        _isLoading = false;
        _currentStep = 2;
        _successMessage = res['message'] ?? '6-digit OTP sent to $email';
        if (res['demo_otp'] != null) {
          _otpController.text = res['demo_otp'].toString();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _handleVerifyAndReset() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text;

    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP code');
      return;
    }
    if (newPass.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authRepository.verifyPasswordReset(
        email: email,
        otp: otp,
        newPassword: newPass,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        widget.onResetSuccess(email, newPass);
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1F17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1E3A2F)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF144032),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF7F3E8),
                        ),
                      ),
                      Text(
                        _currentStep == 1 ? 'Step 1 of 2: Request OTP' : 'Step 2 of 2: Enter OTP & New Password',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Error / Success Banners
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_successMessage!, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_currentStep == 1) ...[
              const Text(
                'Enter the email address registered with your KeraLink account. We will send a 6-digit verification code.',
                style: TextStyle(fontSize: 13, color: Color(0xFFC5D8CD), height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF7F3E8))),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF142B20),
                  hintText: 'name@example.com',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF10B981), size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRequestOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0D1F17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D1F17)))
                      : const Text('Send 6-Digit OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ] else ...[
              // Step 2: OTP & New Password
              Text(
                'Verification code sent to ${_emailController.text}. Enter the code and choose a new password.',
                style: const TextStyle(fontSize: 12, color: Color(0xFFC5D8CD), height: 1.3),
              ),
              const SizedBox(height: 16),

              const Text('6-Digit Verification OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF7F3E8))),
              const SizedBox(height: 6),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF142B20),
                  hintText: '••••••',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 16, letterSpacing: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 14),

              const Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF7F3E8))),
              const SizedBox(height: 6),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF142B20),
                  hintText: 'Minimum 8 characters',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF10B981), size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyAndReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Save New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),

              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _currentStep = 1),
                  child: const Text('Back to Step 1', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
