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
import 'package:gram_aarogya_seva/shared/widgets/guided_tour_dialog.dart';
import 'package:gram_aarogya_seva/shared/widgets/feature_tour_overlay.dart';
import 'package:gram_aarogya_seva/shared/widgets/emergency_helpline_sheet.dart';
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

  void _showTourOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.locale.languageCode == 'mr'
                  ? 'ॲप मार्गदर्शन कसे पाहायचे?'
                  : context.locale.languageCode == 'hi'
                      ? 'ऐप का मार्गदर्शन कैसे देखना चाहते हैं?'
                      : 'How would you like the guided tour?',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Option 1: Spotlight Tour
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _startSpotlightTour();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFA5D6A7), width: 1.5),
              ),
              tileColor: const Color(0xFFE8F5E9),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.fullscreen_rounded, color: Colors.white),
              ),
              title: Text(
                context.locale.languageCode == 'mr'
                    ? 'स्क्रीनवर फिचर हायलाइट करा (बोलणारा आवाज)'
                    : context.locale.languageCode == 'hi'
                        ? 'स्क्रीन पर फीचर देखें (बोलती आवाज़ के साथ)'
                        : 'Interactive Spotlight Tour (With Voice Audio)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                context.locale.languageCode == 'mr'
                    ? 'प्रत्येक बटण व फिचर चमकवून आवाजात माहिती देईल'
                    : context.locale.languageCode == 'hi'
                        ? 'हर बटन और फीचर को हाइलाइट करके आवाज़ में समझाएगा'
                        : 'Highlights actual elements on your screen with audio',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
            const SizedBox(height: 12),
            // Option 2: Step-by-Step Dialog
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                GuidedTourDialog.show(
                  context,
                  onStartSpotlightTour: _startSpotlightTour,
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFB3E5FC), width: 1.5),
              ),
              tileColor: const Color(0xFFE1F5FE),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF0288D1),
                child: Icon(Icons.menu_book_rounded, color: Colors.white),
              ),
              title: Text(
                context.locale.languageCode == 'mr'
                    ? 'मार्गदर्शिका पुस्तिका (Step-by-Step Guide)'
                    : context.locale.languageCode == 'hi'
                        ? 'मार्गदर्शिका पुस्तिका (Step-by-Step Guide)'
                        : 'Tour Book Dialog (Step-by-Step)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                context.locale.languageCode == 'mr'
                    ? 'पायरी-दर-पायरी माहितीपत्रक'
                    : context.locale.languageCode == 'hi'
                        ? 'स्टेप-बाय-स्टेप जानकारी कार्ड'
                        : 'Browse clear visual guide cards at your pace',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(patientProfileProvider);
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: Text(
          tr('app_name'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: tr('guided_tour'),
            onPressed: _showTourOptions,
          ),
          const NotificationBell(),
          const LogoutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTourOptions,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.school_rounded, size: 22),
        label: Text(
          tr('guided_tour'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientProfileProvider);
          ref.invalidate(myAppointmentsProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Language Bar (Wrapped in Key & Zero Overflow)
              Container(
                key: _langBarKey,
                child: const _QuickLanguageBar(),
              ),
              const SizedBox(height: 14),

              // 2. Profile Greeting or Warning Card
              Container(
                key: _profileCardKey,
                child: profileAsync.when(
                  data: (patient) => patient == null
                      ? const _NoProfileCard()
                      : _ProfileCard(
                          name: patient.name,
                          villageId: patient.villageId,
                        ),
                  loading: () => Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Guided Tour Banner
              Container(
                key: _tourBannerKey,
                child: _GuidedTourCard(onTap: _showTourOptions),
              ),
              const SizedBox(height: 20),

              // 4. Quick Services (2x2 Grid)
              Text(
                tr('quick_actions'),
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ServicesGrid(
                profileAsync: profileAsync,
                bookKey: _bookAptKey,
                recordsKey: _healthRecordsKey,
                emergencyKey: _emergencyKey,
                doctorKey: _doctorRegKey,
              ),
              const SizedBox(height: 24),

              // 5. My Appointments Section
              Container(
                key: _appointmentsSectionKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('my_appointments'),
                          style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        appointmentsAsync.maybeWhen(
                          data: (list) => list.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    '${list.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    appointmentsAsync.when(
                      data: (appointments) {
                        if (appointments.isEmpty) {
                          return _EmptyAppointmentsCard(
                            onBookTap: () => _handleBookNavigation(context, profileAsync),
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
                      error: (_, __) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(tr('error_generic'), style: AppTextStyles.bodyMedium),
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

/// Prominent 1-tap language toggle bar with horizontal scrolling to prevent any pixel overflow.
class _QuickLanguageBar extends StatelessWidget {
  const _QuickLanguageBar();

  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.g_translate_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'भाषा:',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPill(context, 'mr', 'मराठी', currentCode == 'mr'),
                  const SizedBox(width: 6),
                  _buildPill(context, 'hi', 'हिंदी', currentCode == 'hi'),
                  const SizedBox(width: 6),
                  _buildPill(context, 'en', 'English', currentCode == 'en'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(BuildContext context, String code, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        context.setLocale(Locale(code));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Guided Tour Card with zero pixel overflow handling.
class _GuidedTourCard extends StatelessWidget {
  final VoidCallback onTap;

  const _GuidedTourCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF2E7D32), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tr('guided_tour_title'),
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('guided_tour_desc'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2x2 Services Grid for high-contrast, effortless rural navigation with zero-overflow tiles.
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
      children: [
        Row(
          children: [
            // 1. Book Appointment
            Expanded(
              child: _ActionTile(
                key: bookKey,
                title: tr('book_appointment'),
                subtitle: tr('book_apt_subtitle'),
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF1B5E20),
                backgroundColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFFC8E6C9),
                onTap: () => _handleBookNavigation(context, profileAsync),
              ),
            ),
            const SizedBox(width: 12),
            // 2. Health Records
            Expanded(
              child: _ActionTile(
                key: recordsKey,
                title: tr('health_records'),
                subtitle: tr('records_subtitle'),
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF0277BD),
                backgroundColor: const Color(0xFFE1F5FE),
                borderColor: const Color(0xFFB3E5FC),
                onTap: () => context.push(AppConstants.routeHealthRecords),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 3. Emergency & Helpline
            Expanded(
              child: _ActionTile(
                key: emergencyKey,
                title: tr('emergency_helpline'),
                subtitle: tr('emergency_desc'),
                icon: Icons.emergency_rounded,
                iconColor: const Color(0xFFC62828),
                backgroundColor: const Color(0xFFFFEBEE),
                borderColor: const Color(0xFFFFCDD2),
                onTap: () => EmergencyHelplineSheet.show(context),
              ),
            ),
            const SizedBox(width: 12),
            // 4. Register as Doctor
            Expanded(
              child: _ActionTile(
                key: doctorKey,
                title: tr('register_as_doctor'),
                subtitle: tr('doctor_registration_mode'),
                icon: Icons.medical_services_rounded,
                iconColor: const Color(0xFF4527A0),
                backgroundColor: const Color(0xFFEDE7F6),
                borderColor: const Color(0xFFD1C4E9),
                onTap: () {
                  ref.read(isDoctorRegistrationIntentProvider.notifier).state = true;
                  context.push('/doctor/register');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: iconColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoProfileCard extends StatelessWidget {
  const _NoProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0B2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_rounded, color: Color(0xFFE65100), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('complete_profile_first'),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tr('tap_create_profile'),
                  style: AppTextStyles.caption.copyWith(color: const Color(0xFFBF360C)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push(AppConstants.routePatientProfile),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              tr('create_profile'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.name, required this.villageId});

  final String name;
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villageName = ref.watch(villageNameProvider(villageId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('patient_greeting', args: [name]),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${tr("village_label_short")}: ${villageName ?? tr("loading")}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: tr('edit_profile'),
            onPressed: () => context.push(AppConstants.routePatientProfile),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state for patient appointments with a high-contrast CTA.
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr('no_appointments'),
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            tr('book_apt_subtitle'),
            style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onBookTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: Text(
                tr('book_appointment'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual Appointment Card with zero pixel overflow handling.
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Slot row (wrapped in Expanded so it never overflows next to StatusBadge)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${AppDateUtils.toDisplayDate(apt.date)} • ${AppDateUtils.formatSlotForDisplay(apt.timeSlot)}',
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: apt.status),
              ],
            ),
            const Divider(height: 18),
            if (apt.doctorName.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr('doctor_name', args: [apt.doctorName]),
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (centerName != null) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      centerName,
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 5),
            Text(
              tr('reason_label', args: [apt.reason]),
              style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (apt.prepInstructions?.isNotEmpty ?? false)
              _InfoBox(
                icon: Icons.info_outline,
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
              const SizedBox(height: 10),
              if (_isCancelling)
                const Center(child: CircularProgressIndicator())
              else if (canCancel)
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _cancelAppointment,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text(
                      tr('cancel_appointment'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTextStyles.caption)),
          ],
        ),
      ),
    );
  }
}
