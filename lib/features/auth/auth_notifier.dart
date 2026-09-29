import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages phone OTP verification state.
/// SRS §11.2 D-FLOW-01, §11.3 P-FLOW-01.
enum AuthStatus { idle, sendingOtp, otpSent, verifying, success, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.verificationId,
    this.errorKey,
    this.resendToken,
  });

  final AuthStatus status;
  final String? verificationId;

  /// Localisation key for the current error, never a raw message.
  ///
  /// SRS §12.1 requires localised, user-friendly errors; carrying a
  /// pre-formatted English string here made that impossible and previously
  /// leaked Firebase codes such as `[invalid-phone-number]` onto the screen.
  final String? errorKey;

  final int? resendToken;

  AuthState copyWith({
    AuthStatus? status,
    String? verificationId,
    String? errorKey,
    int? resendToken,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      resendToken: resendToken ?? this.resendToken,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;

  AuthNotifier([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance,
        super(const AuthState());

  /// Sends OTP to the given phone number.
  /// SRS: OTP-based login for all roles (Firebase Phone Auth).
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      clearError: true,
    );

    final formattedPhone = '+91$phoneNumber'; // Indian numbers only

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign in (happens on some Android devices)
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        // SRS §12.1: never surface a raw Firebase code to the user. The code
        // goes to the log for diagnosis; the user gets a localisation key.
        debugPrint('[Auth] verifyPhoneNumber failed: ${e.code} ${e.message}');
        state = state.copyWith(
          status: AuthStatus.error,
          errorKey: switch (e.code) {
            'too-many-requests' => 'error_rate_limited',
            'invalid-phone-number' => 'error_invalid_phone',
            'network-request-failed' => 'error_no_network',
            _ => 'error_otp_send_failed',
          },
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        state = state.copyWith(
          status: AuthStatus.otpSent,
          verificationId: verificationId,
          resendToken: resendToken,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // No action needed — user can still manually enter OTP
      },
      forceResendingToken: state.resendToken,
    );
  }

  /// Verifies the OTP entered by the user.
  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorKey: 'error_otp_expired',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.verifying, clearError: true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] verifyOtp failed: ${e.code}');
      state = state.copyWith(
        status: AuthStatus.error,
        errorKey: switch (e.code) {
          'invalid-verification-code' => 'error_invalid_otp',
          'session-expired' => 'error_otp_expired',
          'network-request-failed' => 'error_no_network',
          _ => 'error_otp_verify_failed',
        },
      );
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      state = state.copyWith(status: AuthStatus.success);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signIn failed: ${e.code}');
      state = state.copyWith(
        status: AuthStatus.error,
        errorKey: 'error_otp_verify_failed',
      );
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState();
  }

  /// Resets state for retry.
  void reset() {
    state = const AuthState();
  }
}

/// Provider for auth state management.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Stores the phone number entered on the login screen so the OTP screen
/// can access it for resend. Cleared on sign-out.
final phoneNumberProvider = StateProvider<String>((ref) => '');
