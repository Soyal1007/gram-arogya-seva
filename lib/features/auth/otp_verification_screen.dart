import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/features/auth/auth_notifier.dart';

/// OTP verification screen with resend timer and auto-create user doc.
/// SRS §11.3 P-FLOW-01 Step 2 continued.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _resendTimer;
  int _resendCountdown = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _onVerify() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authNotifierProvider.notifier)
        .verifyOtp(_otpController.text.trim());
  }

  void _onResend() {
    _startResendTimer();
    // Read the stored phone number from the provider (set by PhoneInputScreen)
    final phone = ref.read(phoneNumberProvider);
    ref.read(authNotifierProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // When auth succeeds, create/update user doc, then GoRouter handles redirect
    ref.listen<AuthState>(authNotifierProvider, (prev, next) async {
      if (next.status == AuthStatus.success) {
        await _createUserDocIfNeeded();
        // GoRouter's redirect will handle navigation based on role
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('verify')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms_rounded,
                    size: 40,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  tr('enter_otp'),
                  style: AppTextStyles.headlineSmall,
                ),
              ),
              const SizedBox(height: 32),

              // OTP input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium.copyWith(
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: AppTextStyles.headlineMedium.copyWith(
                      letterSpacing: 12,
                      color: AppColors.disabled,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: Validators.validateOtp,
                ),
              ),
              const SizedBox(height: 24),

              // Verify button
              LargeButton(
                label: tr('verify'),
                icon: Icons.verified_rounded,
                isLoading: authState.status == AuthStatus.verifying,
                onPressed: authState.status == AuthStatus.verifying
                    ? null
                    : _onVerify,
              ),
              const SizedBox(height: 16),

              // Resend button with timer
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        '${tr('resend_otp')} (${_resendCountdown}s)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.disabled,
                        ),
                      )
                    : TextButton(
                        onPressed: _onResend,
                        child: Text(
                          tr('resend_otp'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              // Error message
              if (authState.status == AuthStatus.error &&
                  authState.errorKey != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr(authState.errorKey!),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Post-OTP: create user document if first login.
  /// SRS §11.3 P-FLOW-01 Step 2: users/{uid} created with role: "patient"
  Future<void> _createUserDocIfNeeded() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final existingUser = await firestoreService.getUser(user.uid);

    if (existingUser == null) {
      // First time login — create user doc with default patient role
      await firestoreService.createOrUpdateUser(
        UserModel.newPatient(
          uid: user.uid,
          phone: user.phoneNumber?.replaceAll('+91', '') ?? '',
        ),
      );
    } else {
      // Existing user — update FCM token (token refresh handled in Block 7)
    }
  }
}
