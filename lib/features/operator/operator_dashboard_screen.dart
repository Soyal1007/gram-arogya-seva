import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/dashboard_tile.dart';
import 'package:gram_aarogya_seva/shared/widgets/inline_error.dart';
import 'package:gram_aarogya_seva/shared/widgets/queue_tile.dart';
import 'package:gram_aarogya_seva/shared/widgets/section_header.dart';
import 'package:gram_aarogya_seva/shared/widgets/warli.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_toggle.dart';
import 'package:gram_aarogya_seva/shared/widgets/notification_bell.dart';
import 'package:gram_aarogya_seva/shared/widgets/feature_tour_overlay.dart';
import 'package:gram_aarogya_seva/features/operator/operator_providers.dart';

/// Operator Dashboard — SRS §11.5 O-FLOW-01.
/// Shows today's bookings, quick actions, and multi-lingual voice guided tour.
class OperatorDashboardScreen extends ConsumerStatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  ConsumerState<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState
    extends ConsumerState<OperatorDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _registerPatientKey = GlobalKey();
  final GlobalKey _bookAppointmentKey = GlobalKey();
  final GlobalKey _assistedAppointmentsKey = GlobalKey();
  final GlobalKey _availabilityKey = GlobalKey();
  final GlobalKey _todayBookingsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startSpotlightTour() {
    final steps = [
      TourStepItem(
        targetKey: _registerPatientKey,
        icon: Icons.person_add_rounded,
        titleMr: 'नवीन रुग्ण नोंदणी (Register Patient)',
        titleHi: 'नया मरीज पंजीकरण (Register Patient)',
        titleEn: 'Register Rural Citizen',
        descMr: 'ज्या ग्रामस्थांकडे स्मार्टफोन नाही, त्यांची फोन नंबर किंवा आधार क्रमांकाने नवीन नोंदणी करा.',
        descHi: 'जिन ग्रामीणों के पास स्मार्टफोन नहीं है, उनका मोबाइल नंबर से नया पंजीकरण करें।',
        descEn: 'Quickly register rural citizens who lack smartphones or require digital assistance.',
        audioMr: 'ज्या ग्रामस्थांकडे स्मार्टफोन नाही, त्यांची आधार किंवा फोन नंबरवरून नवीन नोंदणी येथे करा.',
        audioHi: 'जिन ग्रामीणों के पास स्मार्टफोन नहीं है, उनका नया पंजीकरण यहाँ से करें।',
        audioEn: 'Register rural citizens who do not have smartphones or need digital assistance.',
      ),
      TourStepItem(
        targetKey: _bookAppointmentKey,
        icon: Icons.calendar_month_rounded,
        titleMr: 'मदतनीस बुकिंग (Book Appointment)',
        titleHi: 'सहायता बुकिंग (Book Appointment)',
        titleEn: 'Book Doctor Appointment',
        descMr: 'गावातील रुग्णासाठी डॉक्टर आणि सोयीचा वेळ स्लॉट निवडून टोकन निश्चित करा.',
        descHi: 'गाँव के मरीज के लिए डॉक्टर और समय चुनकर टोकन बुक करें।',
        descEn: 'Book appointments and reserve clinic queue tokens on behalf of villagers.',
        audioMr: 'गावातील रुग्णासाठी प्राथमिक आरोग्य केंद्रातील डॉक्टर आणि सोयीची वेळ निवडून टोकन बुक करा.',
        audioHi: 'गाँव के मरीज के लिए स्वास्थ्य केंद्र के डॉक्टर और समय चुनकर टोकन बुक करें।',
        audioEn: 'Book doctor appointments and generate clinic tokens on behalf of villagers.',
      ),
      TourStepItem(
        targetKey: _assistedAppointmentsKey,
        icon: Icons.event_note_rounded,
        titleMr: 'मदत केलेली बुकिंग्ज (Assisted Bookings)',
        titleHi: 'सहायता प्राप्त बुकिंग (Assisted Bookings)',
        titleEn: 'Assisted Appointments List',
        descMr: 'आशा सेविका किंवा ऑपरेटर म्हणून तुम्ही बुक केलेल्या सर्व रुग्णांच्या भेटी तपासा.',
        descHi: 'आशा कार्यकर्ता या ऑपरेटर द्वारा बुक की गई सभी मरीजों की अपॉइंटमेंट्स देखें।',
        descEn: 'Track and review all doctor appointments scheduled through this operator desk.',
        audioMr: 'तुम्ही सहाय्य केलेल्या सर्व रुग्णांच्या भेटींची स्थिती आणि तपासणी टोकन येथे तपासा.',
        audioHi: 'आपके द्वारा बुक की गई सभी अपॉइंटमेंट्स की स्थिति और टोकन यहाँ देखें।',
        audioEn: 'Track and manage all appointments booked through your operator desk.',
      ),
      TourStepItem(
        targetKey: _availabilityKey,
        icon: Icons.schedule_rounded,
        titleMr: 'वेळ व्यवस्थापन (Manage Availability)',
        titleHi: 'समय प्रबंधन (Manage Availability)',
        titleEn: 'Centre OPD Schedule',
        descMr: 'आरोग्य केंद्राच्या वेळा आणि डॉक्टरांच्या उपलब्धतेचे वेळापत्रक येथे व्यवस्थापित करा.',
        descHi: 'स्वास्थ्य केंद्र के समय और डॉक्टर के उपलब्ध स्लॉट यहाँ से प्रबंधित करें।',
        descEn: 'Manage health centre operational hours and doctor consultation slots.',
        audioMr: 'आरोग्य केंद्राच्या वेळा आणि उपलब्ध डॉक्टर स्लॉट व्यवस्थापित करण्यासाठी येथे दाबा.',
        audioHi: 'स्वास्थ्य केंद्र के समय और डॉक्टर स्लॉट का प्रबंधन करने के लिए यहाँ दबाएं।',
        audioEn: 'Manage health centre operational hours and doctor session schedules.',
      ),
      TourStepItem(
        targetKey: _todayBookingsKey,
        icon: Icons.assignment_turned_in_rounded,
        titleMr: 'आजच्या नोंदी (Today\'s Bookings)',
        titleHi: 'आज की बुकिंग (Today\'s Bookings)',
        titleEn: 'Today\'s Assisted Bookings',
        descMr: 'आज नोंदवलेल्या सर्व रुग्णांची संख्या, टोकन आणि डॉक्टरांच्या मंजुरीची स्थिती येथे तपासा.',
        descHi: 'आज बुक किए गए सभी मरीजों की संख्या, टोकन और स्थिति यहाँ सीधे देखें।',
        descEn: 'Live count and status of all patient bookings completed today.',
        audioMr: 'आजच्या दिवशी नोंदवलेल्या सर्व रुग्णांची संख्या आणि प्रलंबित स्थिती येथे थेट तपासा.',
        audioHi: 'आज दर्ज किए गए सभी मरीजों की संख्या और स्थिति यहाँ सीधे देखें।',
        audioEn: 'Review today\'s total assisted bookings and live token progress summary.',
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
    final bookingsAsync = ref.watch(operatorTodayBookingsProvider);
    final bookings = bookingsAsync.valueOrNull ?? const [];

    int countOf(String status) =>
        bookings.where((a) => a.status == status).length;

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
        onRefresh: () async =>
            ref.invalidate(operatorTodayBookingsProvider),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today at a glance
              MuralHeader(
                scene: MuralScene.register,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('todays_bookings', args: [
                        AppDateUtils.toDisplayDate(AppDateUtils.todaySchemaDate())
                      ]),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    HeaderStats(stats: [
                      (tr('total_label'), '${bookings.length}'),
                      (tr('pending_label'),
                          '${countOf(AppConstants.appointmentPending)}'),
                      (tr('accepted_label'),
                          '${countOf(AppConstants.appointmentAccepted)}'),
                    ]),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick actions — the four operator flows (SRS §5.1)
                    DashboardTileGrid(tiles: [
                      DashboardTile(
                        key: _bookAppointmentKey,
                        icon: Icons.calendar_month_outlined,
                        label: tr('book_appointment'),
                        onTap: () => context.push('/operator/book'),
                      ),
                      DashboardTile(
                        key: _registerPatientKey,
                        icon: Icons.person_add_alt_1_outlined,
                        label: tr('register_patient'),
                        accent: AppColors.zariDeep,
                        tint: AppColors.zariSoft,
                        onTap: () => context.push('/operator/register-patient'),
                      ),
                      DashboardTile(
                        key: _assistedAppointmentsKey,
                        icon: Icons.event_note_outlined,
                        label: tr('assisted_appointments'),
                        accent: AppColors.info,
                        tint: AppColors.infoContainer,
                        onTap: () => context.push('/operator/appointments'),
                      ),
                      DashboardTile(
                        key: _availabilityKey,
                        icon: Icons.schedule_rounded,
                        label: tr('manage_availability'),
                        accent: AppColors.secondary,
                        tint: AppColors.secondaryContainer,
                        onTap: () => context.push('/operator/availability'),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Today's bookings
                    Container(
                      key: _todayBookingsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            title: tr('today'),
                            count: bookings.length,
                          ),
                          bookingsAsync.when(
                            data: (list) {
                              if (list.isEmpty) {
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
                                      const Icon(Icons.event_busy_outlined,
                                          size: 44, color: AppColors.primary),
                                      const SizedBox(height: 12),
                                      Text(tr('no_bookings_today'),
                                          style: AppTextStyles.titleLarge,
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                );
                              }
                              return Column(
                                children: list
                                    .map((apt) => QueueTile(appointment: apt))
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
