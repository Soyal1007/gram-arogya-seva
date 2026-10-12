import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/shared/widgets/inline_error.dart';
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
      if (next.status == AuthStatus.success && prev?.status != AuthStatus.success) {
        // GoRouter can redirect away (disposing this screen) while the await
        // is pending, so capture the container first — `ref` dies with us.
        final container = ProviderScope.containerOf(context, listen: false);
        await _createUserDocIfNeeded();
        container.invalidate(currentUserProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('verify')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
              const SizedBox(height: 8),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('enter_otp'),
                style: AppTextStyles.headlineLarge,
              ),
              if (ref.watch(phoneNumberProvider).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '+91 ${ref.watch(phoneNumberProvider)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // OTP input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  style: AppTextStyles.displayMedium.copyWith(
                    fontFamily: AppTextStyles.sans,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 14,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '······',
                    hintStyle: AppTextStyles.displayMedium.copyWith(
                      fontFamily: AppTextStyles.sans,
                      letterSpacing: 14,
                      color: AppColors.outlineVariant,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                          color: AppColors.outline,
                        ),
                      )
                    : TextButton(
                        onPressed: _onResend,
                        child: Text(
                          tr('resend_otp'),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),

              // Error message
              if (authState.status == AuthStatus.error &&
                  authState.errorKey != null) ...[
                const SizedBox(height: 16),
                InlineError(message: tr(authState.errorKey!)),
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
