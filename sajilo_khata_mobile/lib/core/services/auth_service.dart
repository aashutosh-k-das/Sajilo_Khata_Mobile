import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService({required this.firebaseReady});

  /// False when Firebase is not configured; the app then runs fully offline
  /// with a locally stored session and the developer OTP [devOtp].
  final bool firebaseReady;

  static const String devOtp = '123456';
  static const String _sessionKey = 'sajilokhata_session';

  final _localSession = StreamController<String?>.broadcast();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Emits the signed-in user's identifier (phone/email/uid), or null when signed out.
  Stream<String?> sessionChanges() async* {
    if (firebaseReady) {
      yield* _auth
          .authStateChanges()
          .map((u) => u == null ? null : (u.phoneNumber ?? u.email ?? u.uid));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    yield prefs.getString(_sessionKey);
    yield* _localSession.stream;
  }

  // Get currently logged-in Firebase user (null in offline mode)
  User? get currentUser => firebaseReady ? _auth.currentUser : null;

  /// Offline-mode sign in after the developer OTP has been checked.
  Future<void> signInLocally(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, identifier);
    _localSession.add(identifier);
  }

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
          debugPrint(
              'Phone verification completed automatically: ${credential.smsCode}');
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
  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with credential: $e');
      rethrow;
    }
  }

  /// Sign out current active session
  Future<void> signOut() async {
    if (firebaseReady) {
      await _auth.signOut();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _localSession.add(null);
  }
}
