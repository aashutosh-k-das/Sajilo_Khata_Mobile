import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../app/themes/app_theme.dart';
import '../../core/providers.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/ui.dart';

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
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    final message = switch (e) {
      FirebaseAuthException(:final message, :final code) => message ?? code,
      GoogleSignInException(code: GoogleSignInExceptionCode.canceled) =>
        'लगइन रद्द गरियो (Login cancelled)',
      _ => '$e',
    };
    setState(() {
      _isLoading = false;
      _errorMessage = 'त्रुटि भयो: $message';
    });
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

    // Test build without Firebase: the developer OTP stands in for the SMS
    if (_authService.usesDevLogin) {
      setState(() {
        _isLoading = false;
        _codeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'टेस्ट मोड: OTP ${AuthService.devOtp} (Test build: use ${AuthService.devOtp})'),
        ),
      );
      return;
    }

    try {
      await _authService.sendOtp(
        phoneNumber: phone,
        onCodeSent: () {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _codeSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP कोड पठाइयो! (OTP Code Sent!)')),
          );
        },
        onAutoVerified: _onLoginSuccess,
        onFailed: (message) => _showError(message),
      );
    } catch (e) {
      _showError(e);
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

    if (_authService.usesDevLogin) {
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
      await _authService.confirmOtp(code);
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

  Future<void> _socialSignIn(Future<void> Function() signIn) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await signIn();
      _onLoginSuccess();
    } catch (e) {
      _showError(e);
    }
  }

  // The app root listens to sessionProvider and swaps to the home shell on its own
  void _onLoginSuccess() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final showForm = _authService.firebaseReady || AuthService.devLoginAllowed;

    return Scaffold(
      body: Stack(
        children: [
          // Brand header behind the form card
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandMark(size: 76, onDark: true)),
                      const SizedBox(height: 16),
                      const Text(
                        'सजिलो खाता',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'बिरगन्जका साना व्यवसायीहरूका लागि डिजिटल लेजर',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 28),
                      if (!showForm)
                        _notConfiguredNotice()
                      else
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _codeSent
                                    ? 'OTP प्रमाणित गर्नुहोस्'
                                    : 'लगइन गर्नुहोस्',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                _codeSent
                                    ? '+977 ${_phoneController.text.trim()} मा पठाइएको ६-अङ्कको कोड राख्नुहोस्'
                                    : 'तपाईंको मोबाइल नम्बरमा OTP पठाइनेछ (We will text you a code)',
                                style: TextStyle(fontSize: 13, color: muted),
                              ),
                              const SizedBox(height: 20),
                              if (!_codeSent)
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: '98XXXXXXXX',
                                    // Country code stays visible even before typing
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 14, right: 10),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🇳🇵',
                                              style: TextStyle(fontSize: 18)),
                                          const SizedBox(width: 6),
                                          Text('+977',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: muted)),
                                        ],
                                      ),
                                    ),
                                    counterText: '',
                                  ),
                                )
                              else
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    letterSpacing: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '••••••',
                                    counterText: '',
                                  ),
                                ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                        color: AppTheme.errorColor,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: _isLoading
                                    ? null
                                    : (_codeSent ? _verifyOtp : _sendOtp),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white),
                                      )
                                    : Text(_codeSent
                                        ? 'कोड प्रमाणित गर्नुहोस् (Verify)'
                                        : 'OTP कोड पाउनुहोस् (Get OTP)'),
                              ),
                              if (_codeSent)
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() {
                                            _codeSent = false;
                                            _otpController.clear();
                                            _errorMessage = null;
                                          }),
                                  child: const Text(
                                      'नम्बर परिवर्तन गर्नुहोस् (Change number)'),
                                ),
                              if (_authService.firebaseReady && !_codeSent) ...[
                                const SizedBox(height: 18),
                                Row(children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('वा (or)',
                                        style: TextStyle(color: muted)),
                                  ),
                                  const Expanded(child: Divider()),
                                ]),
                                const SizedBox(height: 18),
                                _socialButton(
                                  label:
                                      'Google बाट लगइन (Continue with Google)',
                                  icon: Icons.g_mobiledata_rounded,
                                  color: const Color(0xFFDB4437),
                                  onPressed: () => _socialSignIn(
                                      _authService.signInWithGoogle),
                                ),
                                if (AuthService.facebookEnabled) ...[
                                  const SizedBox(height: 12),
                                  _socialButton(
                                    label:
                                        'Facebook बाट लगइन (Continue with Facebook)',
                                    icon: Icons.facebook_rounded,
                                    color: const Color(0xFF1877F2),
                                    onPressed: () => _socialSignIn(
                                        _authService.signInWithFacebook),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 14, color: muted),
                          const SizedBox(width: 6),
                          Text('तपाईंको डाटा सुरक्षित छ (Your data is secure)',
                              style: TextStyle(fontSize: 12, color: muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 28),
      label: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Production build without Firebase config: there is no server to log in against
  Widget _notConfiguredNotice() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'लगइन अझै सेटअप भएको छैन।\n'
          'Login is not set up yet: this build has no Firebase configuration. '
          'Run `flutterfire configure` and rebuild the app.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
