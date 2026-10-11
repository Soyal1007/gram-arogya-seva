import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/queue_tile.dart';
import 'package:gram_aarogya_seva/shared/widgets/dashboard_tile.dart';
import 'package:gram_aarogya_seva/shared/widgets/inline_error.dart';
import 'package:gram_aarogya_seva/shared/widgets/section_header.dart';
import 'package:gram_aarogya_seva/shared/widgets/warli.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_toggle.dart';
import 'package:gram_aarogya_seva/shared/widgets/notification_bell.dart';
import 'package:gram_aarogya_seva/shared/widgets/feature_tour_overlay.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/features/doctor/doctor_providers.dart';

/// Doctor Dashboard — SRS §11.2 D-FLOW-02.
/// Shows today's queue, quick stats, navigation, and multi-lingual voice guided tour.
class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState
    extends ConsumerState<DoctorDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _availabilityKey = GlobalKey();
  final GlobalKey _appointmentsKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _queueKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startSpotlightTour() {
    final steps = [
      TourStepItem(
        targetKey: _headerKey,
        icon: Icons.medical_services_rounded,
        titleMr: 'डॉक्टर माहिती व स्वागत (Doctor Greeting)',
        titleHi: 'डॉक्टर जानकारी एवं स्वागत (Doctor Greeting)',
        titleEn: 'Doctor Welcome & Specialty',
        descMr: 'येथे आपले नाव, वैद्यकीय विशेष विभाग आणि आरोग्य केंद्राचे नाव दिसेल.',
        descHi: 'यहाँ आपका नाम, विशेषज्ञता और स्वास्थ्य केंद्र का नाम दिखता है।',
        descEn: 'Shows your verified doctor name, clinical specialty, and assigned health centre.',
        audioMr: 'डॉक्टर, आपले स्वागत आहे! येथे आपले नाव आणि विशेष तज्ज्ञ विभाग दिसेल.',
        audioHi: 'डॉक्टर साहब, आपका स्वागत है! यहाँ आपका नाम और विशेषज्ञता दिखेगी।',
        audioEn: 'Welcome Doctor! Your registered name and specialization are displayed here.',
      ),
      TourStepItem(
        targetKey: _availabilityKey,
        icon: Icons.calendar_month_rounded,
        titleMr: 'वेळ व्यवस्थापन (Manage Availability)',
        titleHi: 'समय प्रबंधन (Manage Availability)',
        titleEn: 'Manage OPD Schedule',
        descMr: 'आपले ओपीडीचे कामाचे दिवस, वेळ आणि रुग्ण तपासणीचे स्लॉट येथे निश्चित करा.',
        descHi: 'अपने ओपीडी के दिन, समय और टोकन स्लॉट यहाँ से निर्धारित करें।',
        descEn: 'Configure your active OPD consultation days, hours, and appointment quotas.',
        audioMr: 'आपले उपलब्ध दिवस, ओपीडीच्या वेळा आणि टोकन स्लॉट व्यवस्थापित करण्यासाठी येथे दाबा.',
        audioHi: 'अपने उपलब्ध दिन, ओपीडी का समय और टोकन स्लॉट सेट करने के लिए यहाँ दबाएं।',
        audioEn: 'Set your OPD working days, consultation hours, and token quotas here.',
      ),
      TourStepItem(
        targetKey: _appointmentsKey,
        icon: Icons.list_alt_rounded,
        titleMr: 'अपॉइंटमेंट यादी (View Appointments)',
        titleHi: 'अपॉइंटमेंट्स सूची (View Appointments)',
        titleEn: 'Patient Appointments & Queue',
        descMr: 'आजचे आणि आगामी रुग्ण, त्यांची लक्षणे, टोकन आणि प्रलंबित विनंत्या तपासा.',
        descHi: 'आज के और आने वाले मरीज, उनके लक्षण, टोकन और लंबित अनुरोध यहाँ देखें।',
        descEn: 'Review incoming patient requests, verify symptoms, and manage the consultation queue.',
        audioMr: 'आजच्या आणि आगामी रुग्णांची यादी, रांगेतील टोकन आणि प्रलंबित अर्ज तपासण्यासाठी येथे दाबा.',
        audioHi: 'मरीजों की सूची, कतार टोकन और लंबित अपॉइंटमेंट्स देखने के लिए यहाँ दबाएं।',
        audioEn: 'View your patient queue, approve appointments, and review medical tokens.',
      ),
      TourStepItem(
        targetKey: _historyKey,
        icon: Icons.history_rounded,
        titleMr: 'तपासणी इतिहास (Appointment History)',
        titleHi: 'जाँच इतिहास (Appointment History)',
        titleEn: 'Consultation History',
        descMr: 'पूर्वी तपासलेल्या रुग्णांचा वैद्यकीय इतिहास आणि दिलेली औषधे येथे तपासा.',
        descHi: 'पहले देखे गए मरीजों का इतिहास और दी गई दवाइयों का रिकॉर्ड यहाँ देखें।',
        descEn: 'Access past patient consultation summaries and medical prescription histories.',
        audioMr: 'तपासणी पूर्ण झालेल्या रुग्णांचा इतिहास आणि पूर्वी दिलेल्या औषधांच्या नोंदी येथे तपासा.',
        audioHi: 'जाँच पूरी हो चुके मरीजों का इतिहास और पुरानी पर्चियों का रिकॉर्ड यहाँ देखें।',
        audioEn: 'Access completed consultations, past patient records, and diagnosis history.',
      ),
      TourStepItem(
        targetKey: _profileKey,
        icon: Icons.person_rounded,
        titleMr: 'माझे प्रोफाईल (Doctor Profile)',
        titleHi: 'मेरी प्रोफाइल (Doctor Profile)',
        titleEn: 'Doctor Profile & Credentials',
        descMr: 'आपला मोबाईल नंबर, पदवी, कौन्सिल नोंदणी क्रमांक आणि संपर्क तपशील येथे व्यवस्थापित करा.',
        descHi: 'अपना मोबाइल नंबर, डिग्री, काउंसिल रजिस्ट्रेशन नंबर और संपर्क विवरण यहाँ देखें।',
        descEn: 'Update your medical credentials, council registration number, and contact info.',
        audioMr: 'आपली वैद्यकीय माहिती, पात्रता प्रमाणपत्र आणि नोंदणी तपशील येथे अद्ययावत करा.',
        audioHi: 'अपनी चिकित्सा जानकारी, डिग्री और पंजीकरण विवरण यहाँ अपडेट करें।',
        audioEn: 'Update your medical credentials, clinic details, and registration profile.',
      ),
      TourStepItem(
        targetKey: _queueKey,
        icon: Icons.people_outline_rounded,
        titleMr: 'आजची रुग्ण रांग (Today\'s Live Queue)',
        titleHi: 'आज की मरीज कतार (Today\'s Live Queue)',
        titleEn: 'Today\'s Patient Queue & Counters',
        descMr: 'आज तपासणीसाठी प्रतीक्षेत असलेले, स्वीकारलेले आणि पूर्ण झालेले रुग्ण येथे थेट दिसतील.',
        descHi: 'आज प्रतीक्षारत, स्वीकृत और जाँच हो चुके मरीजों की संख्या और सूची यहाँ दिखती है।',
        descEn: 'Live counters showing pending, accepted, and completed patients for today.',
        audioMr: 'आजच्या रांगेतील प्रलंबित, स्वीकारलेले आणि पूर्ण झालेले रुग्ण येथे थेट दिसतील.',
        audioHi: 'आज की कतार में प्रतीक्षारत, स्वीकृत और पूरे हो चुके मरीज यहाँ सीधे दिखेंगे।',
        audioEn: 'Monitor today\'s live queue with real-time pending, accepted, and completed counters.',
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
    final profileAsync = ref.watch(doctorProfileProvider);
    final appointmentsAsync = ref.watch(doctorTodayAppointmentsProvider);
    final todayAppts = appointmentsAsync.valueOrNull ?? const <AppointmentModel>[];

    int countOf(String status) =>
        todayAppts.where((a) => a.status == status).length;
    final pending = countOf(AppConstants.appointmentPending);

    return Scaffold(
      appBar: AppBar(
        shape: const Border(),
        title: Text(tr('dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: tr('guided_tour'),
            onPressed: _startSpotlightTour,
          ),
          const NotificationBell(),
          const LanguageToggle(),
          const LogoutButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(doctorProfileProvider);
          ref.invalidate(doctorTodayAppointmentsProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting and today at a glance
              MuralHeader(
                scene: MuralScene.clinic,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                child: Column(
                  key: _headerKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileAsync.when(
                      data: (doctor) {
                        if (doctor == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('welcome_doctor', args: [doctor.name]),
                              style: AppTextStyles.displayMedium.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor.specialization,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.onMuralMuted,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(
                            color: AppColors.zariBright,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    HeaderStats(stats: [
                      (tr('pending_label'), '$pending'),
                      (tr('accepted_label'),
                          '${countOf(AppConstants.appointmentAccepted)}'),
                      (tr('done_label'),
                          '${countOf(AppConstants.appointmentCompleted)}'),
                    ]),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardTileGrid(tiles: [
                      DashboardTile(
                        key: _appointmentsKey,
                        icon: Icons.list_alt_rounded,
                        label: tr('view_appointments'),
                        badge: pending,
                        onTap: () {
                          ref.read(doctorAppointmentFilterProvider.notifier).state = null;
                          context.push('/doctor/appointments');
                        },
                      ),
                      DashboardTile(
                        key: _availabilityKey,
                        icon: Icons.calendar_month_outlined,
                        label: tr('manage_availability'),
                        onTap: () => context.push('/doctor/availability'),
                      ),
                      DashboardTile(
                        key: _historyKey,
                        icon: Icons.history_rounded,
                        label: tr('appointment_history'),
                        accent: AppColors.info,
                        tint: AppColors.infoContainer,
                        onTap: () {
                          ref.read(doctorAppointmentFilterProvider.notifier).state =
                              AppConstants.appointmentCompleted;
                          context.push('/doctor/appointments');
                        },
                      ),
                      DashboardTile(
                        key: _profileKey,
                        icon: Icons.badge_outlined,
                        label: tr('doctor_profile'),
                        accent: AppColors.zariDeep,
                        tint: AppColors.zariSoft,
                        onTap: () => context.push('/doctor/profile'),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Today's queue
                    Container(
                      key: _queueKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            title: tr('todays_queue', args: [
                              AppDateUtils.toDisplayDate(
                                  AppDateUtils.todaySchemaDate())
                            ]),
                            count: todayAppts.length,
                          ),
                          appointmentsAsync.when(
                            data: (appts) {
                              if (appts.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color: AppColors.outlineVariant,
                                        width: 0.8),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.event_available_outlined,
                                          size: 44, color: AppColors.primary),
                                      const SizedBox(height: 12),
                                      Text(tr('no_appointments_today'),
                                          style: AppTextStyles.titleLarge,
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                );
                              }
                              return Column(
                                children: appts
                                    .map((apt) => QueueTile(
                                          appointment: apt,
                                          onTap: () => context
                                              .push('/doctor/appointments'),
                                        ))
                                    .toList(),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) =>
                                InlineError(message: tr('error_generic')),
                          ),
                        ],
                      ),
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
