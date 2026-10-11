import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/load_more_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/shared/widgets/notification_bell.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/shared/widgets/feature_tour_overlay.dart';
import 'package:gram_aarogya_seva/shared/widgets/emergency_helpline_sheet.dart';
import 'package:gram_aarogya_seva/shared/widgets/date_leaf.dart';
import 'package:gram_aarogya_seva/shared/widgets/inline_error.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_segmented.dart';
import 'package:gram_aarogya_seva/shared/widgets/section_header.dart';
import 'package:gram_aarogya_seva/shared/widgets/warli.dart';
import 'package:gram_aarogya_seva/features/patient/patient_providers.dart';

/// Patient Home Screen — Rural Healthcare Interface.
/// Features high contrast, multi-lingual audio tour in Marathi, Hindi & English,
/// interactive feature spotlighting walkthrough, and zero pixel overflow layout.
class PatientDashboardScreen extends ConsumerStatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  ConsumerState<PatientDashboardScreen> createState() =>
      _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends ConsumerState<PatientDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  // Keys to highlight each feature during interactive spotlight walkthrough
  final GlobalKey _langBarKey = GlobalKey();
  final GlobalKey _profileCardKey = GlobalKey();
  final GlobalKey _tourBannerKey = GlobalKey();
  final GlobalKey _bookAptKey = GlobalKey();
  final GlobalKey _healthRecordsKey = GlobalKey();
  final GlobalKey _emergencyKey = GlobalKey();
  final GlobalKey _doctorRegKey = GlobalKey();
  final GlobalKey _appointmentsSectionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startSpotlightTour() {
    final steps = [
      TourStepItem(
        targetKey: _langBarKey,
        icon: Icons.g_translate_rounded,
        titleMr: 'भाषा निवडा (Language)',
        titleHi: 'भाषा चुनें (Language)',
        titleEn: 'Choose Language',
        descMr: 'येथून तुम्ही एका स्पर्शात मराठी, हिंदी किंवा इंग्रजी भाषा बदलू शकता. संपूर्ण ॲप तुमच्या भाषेत काम करेल.',
        descHi: 'यहाँ से आप अपनी भाषा मराठी, हिंदी या अंग्रेजी एक टच से बदल सकते हैं। पूरा ऐप आपकी भाषा में चलेगा।',
        descEn: 'Switch between Marathi, Hindi, and English anytime with a single tap. The entire app will adapt immediately.',
        audioMr: 'येथून तुम्ही एका स्पर्शात मराठी, हिंदी किंवा इंग्रजी भाषा निवडू शकता.',
        audioHi: 'यहाँ से आप अपनी भाषा मराठी, हिंदी या अंग्रेजी में बदल सकते हैं।',
        audioEn: 'Switch between Marathi, Hindi, and English anytime with a single tap.',
      ),
      TourStepItem(
        targetKey: _profileCardKey,
        icon: Icons.person_pin_rounded,
        titleMr: 'माझे गाव व नाव (Village & Profile)',
        titleHi: 'मेरा गाँव व नाम (Village & Profile)',
        titleEn: 'Your Village & Profile',
        descMr: 'येथे तुमचे नाव आणि गाव दिसेल. सर्व आरोग्य सेवा आणि डॉक्टर तुमच्या गावातील केंद्राशी जोडले जातील.',
        descHi: 'यहाँ आपका नाम और आपका गाँव दिखता है। आपकी सभी स्वास्थ्य सेवाएँ आपके गाँव के अनुसार मिलेंगी।',
        descEn: 'Your registered name and village. Appointments are automatically linked to your local health centre.',
        audioMr: 'येथे तुमचे नाव आणि गाव दिसेल. सर्व आरोग्य सेवा तुमच्या गावातील केंद्राशी जोडल्या जातील.',
        audioHi: 'यहाँ आपका नाम और आपका गाँव दिखता है। आपकी सभी स्वास्थ्य सेवाएँ आपके गाँव के अनुसार मिलेंगी।',
        audioEn: 'Your registered name and village. Appointments are mapped to your local health centre.',
      ),
      TourStepItem(
        targetKey: _bookAptKey,
        icon: Icons.calendar_month_rounded,
        titleMr: 'डॉक्टर अपॉइंटमेंट बुक करा',
        titleHi: 'डॉक्टर अपॉइंटमेंट बुक करें',
        titleEn: 'Book Doctor Appointment',
        descMr: 'दवाखान्यात ताटकळत न बसता घरी बसून डॉक्टर आणि सोयीची वेळ निवडून टोकन निश्चित करा.',
        descHi: 'अस्पताल में लंबी लाइन से बचने के लिए यहाँ से गाँव, डॉक्टर और समय चुनकर टोकन बुक करें।',
        descEn: 'Pick your village doctor and a convenient time slot in advance to skip hospital waiting queues.',
        audioMr: 'डॉक्टरांना भेटण्यासाठी येथे दाबा. गाव, डॉक्टर आणि सोयीची वेळ निवडून टोकन निश्चित करा.',
        audioHi: 'डॉक्टर से मिलने के लिए यहाँ दबाएं। अपना गाँव, डॉक्टर और सुविधाजनक समय चुनकर अपॉइंटमेंट लें।',
        audioEn: 'Tap here to book a doctor appointment and skip long queues at the health centre.',
      ),
      TourStepItem(
        targetKey: _healthRecordsKey,
        icon: Icons.receipt_long_rounded,
        titleMr: 'आरोग्य नोंदी व औषधे',
        titleHi: 'दवाइयां और स्वास्थ्य रिकॉर्ड',
        titleEn: 'Health Records & Prescriptions',
        descMr: 'डॉक्टरांनी दिलेली औषधांची चिठ्ठी आणि तपासणी अहवाल येथे नेहमी सुरक्षित राहतील. कागद गहाळ होण्याची भीती नाही.',
        descHi: 'डॉक्टर द्वारा लिखी गई दवाइयों की पर्ची और रिपोर्ट यहाँ हमेशा सुरक्षित रहेंगी। कागज़ खोने का कोई डर नहीं।',
        descEn: 'Access past prescriptions, test reports, and doctor clinical notes anytime safely on your phone.',
        audioMr: 'डॉक्टरांनी दिलेली औषधांची चिठ्ठी आणि तपासणी अहवाल येथे नेहमी सुरक्षित राहतील.',
        audioHi: 'डॉक्टर द्वारा दी गई दवाइयों की पर्ची और जाँच रिपोर्ट यहाँ हमेशा सुरक्षित रहेंगी।',
        audioEn: 'View all your past prescriptions and doctor visit summaries safely in your phone.',
      ),
      TourStepItem(
        targetKey: _emergencyKey,
        icon: Icons.emergency_rounded,
        titleMr: '१०८ रुग्णवाहिका व आपत्कालीन मदत',
        titleHi: '108 एम्बुलेंस व आपातकालीन सहायता',
        titleEn: '108 Ambulance & Emergency Helpline',
        descMr: '१०८ मोफत शासकीय रुग्णवाहिका, १०४ आरोग्य सल्ला आणि गावातील आशा सेविकेचा संपर्क मिळवण्यासाठी येथे दाबा.',
        descHi: '१०८ निःशुल्क सरकारी एम्बुलेंस, १०४ स्वास्थ्य सलाह और गाँव की आशा दीदी की मदद के लिए यहाँ दबाएं।',
        descEn: 'Quick 1-tap dial for 108 Free Ambulance, 104 Health Helpline, and village ASHA healthcare workers.',
        audioMr: '१०८ मोफत रुग्णवाहिका, १०४ आरोग्य सल्ला आणि गावातील आशा सेविकेच्या मदतीसाठी येथे दाबा.',
        audioHi: '१०८ निःशुल्क एम्बुलेंस, १०४ स्वास्थ्य हेल्पलाइन और गाँव की आशा दीदी की मदद के लिए यहाँ दबाएं।',
        audioEn: 'Get instant access to 108 Free Ambulance, 104 Health Helpline, and village ASHA support.',
      ),
      TourStepItem(
        targetKey: _appointmentsSectionKey,
        icon: Icons.event_available_rounded,
        titleMr: 'माझ्या अपॉइंटमेंट (Appointments)',
        titleHi: 'मेरी अपॉइंटमेंट (Appointments)',
        titleEn: 'My Upcoming Appointments',
        descMr: 'तुमच्या आगामी भेटीची तारीख, वेळ, डॉक्टर आणि टोकन स्थिती येथे तपासा किंवा गरज पडल्यास रद्द करा.',
        descHi: 'आपकी आने वाली अपॉइंटमेंट का समय, टोकन और डॉक्टर की जानकारी यहाँ दिखेगी।',
        descEn: 'Track your scheduled appointment time, doctor details, and current queue token status here.',
        audioMr: 'तुमच्या आगामी भेटीची वेळ, डॉक्टर आणि टोकन क्रमांक येथे दिसेल.',
        audioHi: 'आपकी आने वाली अपॉइंटमेंट का समय, टोकन और डॉक्टर का नाम यहाँ दिखेगी।',
        audioEn: 'Check your upcoming appointment schedule, doctor details, and status here.',
      ),
    ];

    FeatureTourOverlay.show(
      context,
      steps: steps,
      scrollController: _scrollController,
    );
  }



  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider);
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        // The header below carries the zari edge; no second border here.
        shape: const Border(),
        title: Text(tr('app_name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: tr('guided_tour'),
            onPressed: _startSpotlightTour,
          ),
          const NotificationBell(),
          const LogoutButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(patientProfileProvider);
          ref.invalidate(myAppointmentsProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Peacock header: who and where, then language
              MuralHeader(
                scene: MuralScene.village,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: _profileCardKey,
                      child: profileAsync.when(
                        data: (patient) => patient == null
                            ? const _NoProfileGreeting()
                            : _ProfileGreeting(
                                name: patient.name,
                                villageId: patient.villageId,
                              ),
                        loading: () => const SizedBox(
                          height: 72,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CircularProgressIndicator(
                              color: AppColors.zariBright,
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      key: _langBarKey,
                      child: const LanguageSegmented(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Services — booking first and largest
                    _ServicesGrid(
                      profileAsync: profileAsync,
                      bookKey: _bookAptKey,
                      recordsKey: _healthRecordsKey,
                      emergencyKey: _emergencyKey,
                      doctorKey: _doctorRegKey,
                    ),
                    const SizedBox(height: 28),

                    // 3. My Appointments
                    Container(
                      key: _appointmentsSectionKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            title: tr('my_appointments'),
                            count: appointmentsAsync.valueOrNull?.length,
                          ),
                          appointmentsAsync.when(
                            data: (appointments) {
                              if (appointments.isEmpty) {
                                return _EmptyAppointmentsCard(
                                  onBookTap: () =>
                                      _handleBookNavigation(context, profileAsync),
                                );
                              }
                              return Column(
                                children: [
                                  ...appointments.map(
                                    (apt) => PatientAppointmentCard(appointment: apt),
                                  ),
                                  LoadMoreButton(
                                    pageKey: PageKeys.patientAppointments,
                                    loadedCount: appointments.length,
                                  ),
                                ],
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, __) =>
                                InlineError(message: tr('error_generic')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 4. Guided tour — quiet, at the end, for whoever needs it
                    Container(
                      key: _tourBannerKey,
                      child: _GuidedTourCard(onTap: _startSpotlightTour),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _handleBookNavigation(
    BuildContext context, AsyncValue<dynamic> profileAsync) {
  if (profileAsync.isLoading) return;
  if (profileAsync.hasError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('error_generic'))),
    );
    return;
  }
  if (profileAsync.value == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('complete_profile_first'))),
    );
    context.push(AppConstants.routePatientProfile);
    return;
  }
  context.push('/patient/book');
}

/// Guided tour entry: a quiet outlined row, not a banner competing with
/// booking.
class _GuidedTourCard extends StatelessWidget {
  final VoidCallback onTap;

  const _GuidedTourCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.zari.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.zariDeep, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('guided_tour_title'),
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      tr('guided_tour_desc'),
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Services: booking is the reason the app exists, so it takes the full
/// width in peacock; records and emergency share the next row; doctor
/// registration — rarely used by patients — is a plain row below.
class _ServicesGrid extends ConsumerWidget {
  const _ServicesGrid({
    required this.profileAsync,
    required this.bookKey,
    required this.recordsKey,
    required this.emergencyKey,
    required this.doctorKey,
  });

  final AsyncValue<dynamic> profileAsync;
  final Key bookKey;
  final Key recordsKey;
  final Key emergencyKey;
  final Key doctorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookTile(
          key: bookKey,
          onTap: () => _handleBookNavigation(context, profileAsync),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionTile(
                  key: recordsKey,
                  title: tr('health_records'),
                  subtitle: tr('records_subtitle'),
                  icon: Icons.description_outlined,
                  accent: AppColors.primary,
                  tint: AppColors.primaryFixed,
                  onTap: () => context.push(AppConstants.routeHealthRecords),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  key: emergencyKey,
                  title: tr('emergency_helpline'),
                  subtitle: '108 / 104',
                  icon: Icons.emergency_outlined,
                  accent: AppColors.error,
                  tint: AppColors.errorContainer,
                  onTap: () => EmergencyHelplineSheet.show(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Material(
          key: doctorKey,
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              ref.read(isDoctorRegistrationIntentProvider.notifier).state = true;
              context.push('/doctor/register');
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outlineVariant, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined,
                      color: AppColors.primary, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(tr('register_as_doctor'),
                        style: AppTextStyles.titleMedium),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.outline),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: AppColors.healingGradient),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.zariBright, width: 1.5),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: AppColors.onPrimary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('book_appointment'),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('book_apt_subtitle'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.zariBright, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outlineVariant, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: AppTextStyles.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header greeting when the patient has not created a profile yet: the only
/// thing they can usefully do is create one, so that is the whole message.
class _NoProfileGreeting extends StatelessWidget {
  const _NoProfileGreeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('complete_profile_first'),
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('tap_create_profile'),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onMuralMuted,
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () => context.push(AppConstants.routePatientProfile),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.zariBright,
            foregroundColor: AppColors.geruDeep,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(tr('create_profile')),
        ),
      ],
    );
  }
}

class _ProfileGreeting extends ConsumerWidget {
  const _ProfileGreeting({required this.name, required this.villageId});

  final String name;
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villageName = ref.watch(villageNameProvider(villageId));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('patient_greeting', args: [name]),
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.onPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 20, color: AppColors.zariBright),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${tr("village_label_short")}: ${villageName ?? tr("loading")}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.onMuralMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.onPrimary),
          tooltip: tr('edit_profile'),
          onPressed: () => context.push(AppConstants.routePatientProfile),
        ),
      ],
    );
  }
}

/// Empty state for patient appointments: says what to do, with the button
/// that does it.
class _EmptyAppointmentsCard extends StatelessWidget {
  const _EmptyAppointmentsCard({required this.onBookTap});

  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant, width: 0.8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            tr('no_appointments'),
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            tr('book_apt_subtitle'),
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onBookTap,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(tr('book_appointment')),
          ),
        ],
      ),
    );
  }
}

/// One appointment: calendar leaf on the left, time / doctor / centre on the
/// right, status top-right, the cancel action at the bottom when allowed.
class PatientAppointmentCard extends ConsumerStatefulWidget {
  const PatientAppointmentCard({super.key, required this.appointment});

  final AppointmentModel appointment;

  @override
  ConsumerState<PatientAppointmentCard> createState() =>
      _PatientAppointmentCardState();
}

class _PatientAppointmentCardState
    extends ConsumerState<PatientAppointmentCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    final centerName = ref.watch(healthCenterNameProvider(apt.healthCenterId));

    final isOpen = apt.status == AppConstants.appointmentPending ||
        apt.status == AppConstants.appointmentAccepted;

    final hasPassed = AppDateUtils.hasSlotPassed(
      date: apt.date,
      timeSlot: apt.timeSlot,
      slotStartAt: apt.slotStartAt,
    );
    final canCancel = isOpen &&
        !hasPassed &&
        AppDateUtils.canCancel(
          date: apt.date,
          timeSlot: apt.timeSlot,
          slotStartAt: apt.slotStartAt,
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DateLeaf(schemaDate: apt.date, muted: !isOpen || hasPassed),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              AppDateUtils.formatSlotForDisplay(apt.timeSlot),
                              style: AppTextStyles.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: apt.status),
                        ],
                      ),
                      if (apt.doctorName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tr('doctor_name', args: [apt.doctorName]),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (centerName != null)
                        Text(
                          centerName,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tr('reason_label', args: [apt.reason]),
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (apt.prepInstructions?.isNotEmpty ?? false)
              _InfoBox(
                icon: Icons.info_outline_rounded,
                color: AppColors.info,
                text: apt.prepInstructions!,
              ),
            if (apt.status == AppConstants.appointmentRejected &&
                (apt.rejectionReason?.isNotEmpty ?? false))
              _InfoBox(
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                text: apt.rejectionReason!,
              ),

            if (isOpen && !hasPassed) ...[
              const SizedBox(height: 12),
              if (_isCancelling)
                const Center(child: CircularProgressIndicator())
              else if (canCancel)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _cancelAppointment,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    label: Text(
                      tr('cancel_appointment'),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  tr('cancel_too_late'),
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelAppointment() async {
    final apt = widget.appointment;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('cancel_appointment'),
      message: tr('cancel_confirm', args: [
        apt.doctorName,
        AppDateUtils.toDisplayDate(apt.date),
        AppDateUtils.formatSlotForDisplay(apt.timeSlot),
      ]),
      confirmLabel: tr('cancel_appointment'),
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref
          .read(functionsServiceProvider)
          .cancelAppointment(apt.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('appointment_cancelled'))),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(e.messageKey))),
        );
      }
    }
    if (mounted) setState(() => _isCancelling = false);
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
