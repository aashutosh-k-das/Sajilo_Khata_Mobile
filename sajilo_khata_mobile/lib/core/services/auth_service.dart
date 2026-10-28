import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown for login failures that should be shown to the user as-is.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({required this.firebaseReady});

  /// False when Firebase is not configured (no google-services.json /
  /// GoogleService-Info.plist / web options). Real login is impossible then.
  final bool firebaseReady;

  /// Test-only OTP. Accepted only when [devLoginAllowed]; never in a
  /// production build.
  static const String devOtp = '123456';

  /// Debug builds, or builds made with --dart-define=DEV_LOGIN=true, may sign
  /// in offline with [devOtp] while Firebase is not configured.
  static const bool devLoginAllowed =
      kDebugMode || bool.fromEnvironment('DEV_LOGIN');

  /// Facebook login needs a Meta developer app; the button is shown only for
  /// builds made with --dart-define=FACEBOOK_LOGIN=true.
  static const bool facebookEnabled = bool.fromEnvironment('FACEBOOK_LOGIN');

  static const String _sessionKey = 'sajilokhata_session';

  final _localSession = StreamController<String?>.broadcast();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Whether the offline developer login is the one in effect.
  bool get usesDevLogin => !firebaseReady && devLoginAllowed;

  /// Emits the signed-in user's identifier (phone/email/uid), or null when signed out.
  Stream<String?> sessionChanges() async* {
    if (firebaseReady) {
      yield* _auth.authStateChanges().map((u) => u == null
          ? null
          : (u.phoneNumber ?? u.email ?? u.displayName ?? u.uid));
      return;
    }
    if (!devLoginAllowed) {
      yield null;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    yield prefs.getString(_sessionKey);
    yield* _localSession.stream;
  }

  // Get currently logged-in Firebase user (null in offline mode)
  User? get currentUser => firebaseReady ? _auth.currentUser : null;

  /// Offline developer sign in after [devOtp] has been checked.
  Future<void> signInLocally(String identifier) async {
    assert(devLoginAllowed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, identifier);
    _localSession.add(identifier);
  }

  /// Converts a 10-digit Nepal mobile number to E.164 (+977...).
  static String formatNepalPhone(String phone) {
    final p = phone.trim();
    if (p.startsWith('+')) return p;
    if (p.length == 10 && p.startsWith('9')) return '+977$p';
    throw AuthFailure('Please provide a valid 10-digit number (+977)');
  }

  // --- Phone OTP ---

  /// Web uses signInWithPhoneNumber (invisible reCAPTCHA); mobile uses
  /// verifyPhoneNumber. Either way the SMS code is confirmed via [confirmOtp].
  ConfirmationResult? _webConfirmation;
  String? _verificationId;

  /// Sends a real SMS OTP. [onCodeSent] fires once the SMS is on its way;
  /// [onAutoVerified] fires if Android reads the SMS and signs in by itself.
  Future<void> sendOtp({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required VoidCallback onAutoVerified,
    required void Function(String message) onFailed,
  }) async {
    final phone = formatNepalPhone(phoneNumber);

    if (kIsWeb) {
      _webConfirmation = await _auth.signInWithPhoneNumber(phone);
      onCodeSent();
      return;
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Automatic SMS retrieval on Android
        await _auth.signInWithCredential(credential);
        await _recordLogin('phone');
        onAutoVerified();
      },
      verificationFailed: (e) {
        debugPrint('Phone verification failed: ${e.code} - ${e.message}');
        onFailed(e.message ?? e.code);
      },
      codeSent: (verificationId, _) {
        _verificationId = verificationId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Checks the SMS code the user typed.
  Future<void> confirmOtp(String smsCode) async {
    if (_webConfirmation != null) {
      await _webConfirmation!.confirm(smsCode);
      await _recordLogin('phone');
      return;
    }
    final verificationId = _verificationId;
    if (verificationId == null) throw AuthFailure('Request a new OTP first');
    await _auth.signInWithCredential(PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    ));
    await _recordLogin('phone');
  }

  // --- Google ---

  bool _googleInitialized = false;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      await _recordLogin('google.com');
      return;
    }
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      // Client IDs are read from google-services.json / GoogleService-Info.plist
      await google.initialize();
      _googleInitialized = true;
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw AuthFailure('Google did not return an ID token');
    await _auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    await _recordLogin('google.com');
  }

  // --- Facebook ---

  Future<void> signInWithFacebook() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(FacebookAuthProvider());
      await _recordLogin('facebook.com');
      return;
    }
    // iOS may return a Limited Login (OIDC) token, which Firebase verifies
    // against the nonce we sent.
    final rawNonce = _randomNonce();
    final result = await FacebookAuth.instance.login(
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    if (result.status == LoginStatus.cancelled) {
      throw AuthFailure('Facebook login cancelled');
    }
    final token = result.accessToken;
    if (result.status != LoginStatus.success || token == null) {
      throw AuthFailure(result.message ?? 'Facebook login failed');
    }
    final credential = token.type == AccessTokenType.limited
        ? OAuthProvider('facebook.com')
            .credential(idToken: token.tokenString, rawNonce: rawNonce)
        : FacebookAuthProvider.credential(token.tokenString);
    await _auth.signInWithCredential(credential);
    await _recordLogin('facebook.com');
  }

  /// Writes shops/{uid}/logins/{id}; the notifyLogin Cloud Function emails the
  /// account owner about the new sign-in. Never blocks login if it fails.
  Future<void> _recordLogin(String method) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(uid)
          .collection('logins')
          .add({
        'method': method,
        'platform': kIsWeb ? 'web browser' : defaultTargetPlatform.name,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Could not record login: $e');
    }
  }

  static String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Sign out current active session
  Future<void> signOut() async {
    if (firebaseReady) {
      await _auth.signOut();
      if (!kIsWeb) {
        if (_googleInitialized) await GoogleSignIn.instance.signOut();
        if (facebookEnabled) await FacebookAuth.instance.logOut();
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _localSession.add(null);
  }
}
