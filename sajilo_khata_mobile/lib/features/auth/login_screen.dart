import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../core/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  AuthService get _authService => ref.read(authServiceProvider);
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  String _verificationId = '';
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Phase 1: Send SMS OTP code
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() {
        _errorMessage =
            'कृपया १०-अङ्कको वैध फोन नम्बर राख्नुहोस्।\n(Please enter a valid 10-digit number)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Offline mode (Firebase not configured): use the developer OTP, like the web prototype
    if (!_authService.firebaseReady) {
      setState(() {
        _isLoading = false;
        _codeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'अफलाइन मोड: OTP ${AuthService.devOtp} प्रयोग गर्नुहोस् (Offline mode: use ${AuthService.devOtp})'),
        ),
      );
      return;
    }

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phone,
        onVerificationCompleted: (credential) async {
          // Automatic SMS retrieval on Android
          await _authService.signInWithCredential(credential);
          _onLoginSuccess();
        },
        onVerificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'प्रमाणीकरण असफल भयो: ${e.message}';
          });
        },
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _codeSent = true;
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP कोड पठाइयो! (OTP Code Sent!)')),
          );
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'त्रुटि भयो: $e';
      });
    }
  }

  // Phase 2: Confirm OTP code verification
  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage =
            'कृपया ६-अङ्कको OTP कोड राख्नुहोस्।\n(Please enter the 6-digit OTP code)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!_authService.firebaseReady) {
      if (code == AuthService.devOtp) {
        await _authService.signInLocally(_phoneController.text.trim());
        _onLoginSuccess();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'गलत OTP कोड। कृपया फेरि प्रयास गर्नुहोस्।\n(Invalid code. Please try again.)';
        });
      }
      return;
    }

    try {
      await _authService.signInWithOtp(
        verificationId: _verificationId,
        smsCode: code,
      );
      _onLoginSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'गलत OTP कोड। कृपया फेरि प्रयास गर्नुहोस्।\n(Invalid code. Please try again.)';
      });
    }
  }

  // The app root listens to sessionProvider and swaps to the home shell on its own
  void _onLoginSuccess() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Symbol
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    'स',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name & description
              const Text(
                'सजिलो खाता',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'बिरगन्जका साना व्यवसायीहरूका लागि डिजिटल लेजर',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_codeSent) ...[
                        const Text(
                          'मोबाईल नम्बर (Mobile Number)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            hintText: '98XXXXXXXX',
                            prefixText: '+977 ',
                            counterText: '',
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'OTP कोड राख्नुहोस् (Enter OTP Code)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: '******',
                            counterText: '',
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppTheme.errorColor, fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor),
                        )
                      else
                        ElevatedButton(
                          onPressed: _codeSent ? _verifyOtp : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _codeSent
                                ? 'कोड प्रमाणित गर्नुहोस् (Verify)'
                                : 'OTP कोड पाउनुहोस् (Get OTP)',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
