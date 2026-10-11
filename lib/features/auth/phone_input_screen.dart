import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/guided_tour_dialog.dart';
import 'package:gram_aarogya_seva/shared/widgets/inline_error.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_segmented.dart';
import 'package:gram_aarogya_seva/shared/widgets/warli.dart';
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Peacock hero with the app mark and name
            MuralHeader(
                scene: MuralScene.village,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.paddingOf(context).top + 36,
                24,
                32,
              ),
              child: Column(
                children: [
                  const AppMark(size: 92),
                  const SizedBox(height: 20),
                  Text(
                    tr('app_name'),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Language first: a villager may not read English.
                  const LanguageSegmented(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(tr('enter_mobile'), style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      style: AppTextStyles.headlineSmall.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 18, right: 10),
                          child: Text(
                            '+91',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: '98765 43210',
                        hintStyle: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.outlineVariant,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.5,
                        ),
                        counterText: '',
                      ),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 20),
                    LargeButton(
                      label: tr('continue_btn'),
                      icon: Icons.arrow_forward_rounded,
                      isLoading: authState.status == AuthStatus.sendingOtp,
                      onPressed: authState.status == AuthStatus.sendingOtp
                          ? null
                          : _onSendOtp,
                    ),

                    // Error message
                    if (authState.status == AuthStatus.error &&
                        authState.errorKey != null) ...[
                      const SizedBox(height: 16),
                      InlineError(message: tr(authState.errorKey!)),
                    ],

                    const SizedBox(height: 28),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Secondary paths, as plain rows rather than competing buttons
                    _SecondaryAction(
                      icon: Icons.play_circle_outline_rounded,
                      label: tr('guided_tour_title'),
                      onTap: () => GuidedTourDialog.show(context),
                    ),
                    _SecondaryAction(
                      icon: Icons.medical_services_outlined,
                      label: tr('register_as_doctor'),
                      onTap: () {
                        ref.read(isDoctorRegistrationIntentProvider.notifier).state = true;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('doctor_registration_mode')),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: AppColors.primary, size: 28),
      title: Text(
        label,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.outline),
      onTap: onTap,
    );
  }
}
