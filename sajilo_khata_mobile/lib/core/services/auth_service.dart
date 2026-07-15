import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to track authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get currently logged-in user
  User? get currentUser => _auth.currentUser;

  /// Initiates Phone Number OTP Verification.
  /// 
  /// Calls Firebase Auth's phone number verification flow.
  /// Handles callbacks for automatic verification, verification failures, 
  /// SMS dispatch, and auto-retrieval timeouts.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      // Ensure phone number starts with country code for Nepal (+977) if not present
      String formattedPhone = phoneNumber.trim();
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('9') && formattedPhone.length == 10) {
          formattedPhone = '+977$formattedPhone';
        } else {
          throw FirebaseAuthException(
            code: 'invalid-phone-number',
            message: 'Please provide a valid 10-digit number (+977)',
          );
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Phone verification completed automatically: ${credential.smsCode}');
          // Sign in automatically if system auto-verifies SMS (e.g. Android auto-read)
          await onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} - ${e.message}');
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('SMS OTP code sent. VerificationID: $verificationId');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('SMS auto-retrieval timeout.');
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      debugPrint('Error during phone number verification: $e');
      rethrow;
    }
  }

  /// Signs in a user using the verification ID and SMS Code OTP.
  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with OTP: $e');
      rethrow;
    }
  }

  /// Complete sign in directly if verification completed automatically
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with credential: $e');
      rethrow;
    }
  }

  /// Sign out current active session
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
