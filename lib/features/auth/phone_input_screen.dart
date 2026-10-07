import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/features/auth/auth_notifier.dart';

/// Phone number input screen. SRS §11.3 P-FLOW-01 Step 2.
class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    // Store phone so OTP screen can access it for resend
    ref.read(phoneNumberProvider.notifier).state = phone;
    ref.read(authNotifierProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Navigate to OTP screen when OTP is sent, or handle auto-signin success
    ref.listen<AuthState>(authNotifierProvider, (prev, next) async {
      if (next.status == AuthStatus.otpSent && prev?.status != AuthStatus.otpSent) {
        if (mounted) context.push(AppConstants.routeOtpVerification);
      } else if (next.status == AuthStatus.success && prev?.status != AuthStatus.success) {
        await _createUserDocIfNeeded();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // App icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // App title
              Text(
                tr('app_name'),
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Language selector
              _LanguageSelector(),
              const SizedBox(height: 32),

              // Phone number form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('enter_mobile'), style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        prefixText: '+91  ',
                        prefixStyle: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: '9876543210',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 24),
                    LargeButton(
                      label: tr('continue_btn'),
                      icon: Icons.send_rounded,
                      isLoading: authState.status == AuthStatus.sendingOtp,
                      onPressed: authState.status == AuthStatus.sendingOtp
                          ? null
                          : _onSendOtp,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          ref.read(isDoctorRegistrationIntentProvider.notifier).state = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('doctor_registration_mode')),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        icon: const Icon(Icons.medical_services_outlined, size: 20),
                        label: Text(
                          tr('register_as_doctor'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
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

  Future<void> _createUserDocIfNeeded() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final existingUser = await firestoreService.getUser(user.uid);

    if (existingUser == null) {
      await firestoreService.createOrUpdateUser(
        UserModel.newPatient(
          uid: user.uid,
          phone: user.phoneNumber?.replaceAll('+91', '') ?? '',
        ),
      );
    }
  }
}

/// Language selection row — switchable from login screen.
/// SRS DP-1: 3 languages from any screen.
class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LangChip(locale: const Locale('en'), label: 'English'),
        const SizedBox(width: 8),
        _LangChip(locale: const Locale('mr'), label: 'मराठी'),
        const SizedBox(width: 8),
        _LangChip(locale: const Locale('hi'), label: 'हिंदी'),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final Locale locale;
  final String label;

  const _LangChip({required this.locale, required this.label});

  @override
  Widget build(BuildContext context) {
    final isSelected = context.locale == locale;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppColors.onPrimary : AppColors.primary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.primary),
      onSelected: (_) => context.setLocale(locale),
    );
  }
}
