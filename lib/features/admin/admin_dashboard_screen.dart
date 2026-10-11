import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_toggle.dart';
import 'package:gram_aarogya_seva/shared/widgets/notification_bell.dart';
import 'package:gram_aarogya_seva/shared/widgets/dashboard_tile.dart';
import 'package:gram_aarogya_seva/shared/widgets/section_header.dart';
import 'package:gram_aarogya_seva/shared/widgets/home_header.dart';
import 'package:gram_aarogya_seva/shared/widgets/feature_tour_overlay.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// Admin Dashboard — SRS §11.1 A-FLOW-01.
/// Stat cards + grid navigation to all admin modules with multi-lingual voice guided tour.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _statsGridKey = GlobalKey();
  final GlobalKey _pendingApprovalsKey = GlobalKey();
  final GlobalKey _villagesKey = GlobalKey();
  final GlobalKey _doctorsKey = GlobalKey();
  final GlobalKey _patientsKey = GlobalKey();
  final GlobalKey _monitorApptsKey = GlobalKey();
  final GlobalKey _rolesKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startSpotlightTour() {
    final steps = [
      TourStepItem(
        targetKey: _statsGridKey,
        icon: Icons.analytics_rounded,
        titleMr: 'प्रशासकीय सांख्यिकी (System Analytics)',
        titleHi: 'प्रशासनिक आँकड़े (System Analytics)',
        titleEn: 'District Analytics Overview',
        descMr: 'एकूण गावे, नोंदणीकृत डॉक्टर, प्रलंबित मान्यता आणि रुग्णांची संख्या येथे थेट दिसेल.',
        descHi: 'कुल गाँव, पंजीकृत डॉक्टर, लंबित स्वीकृतियां और मरीजों की संख्या यहाँ दिखती है।',
        descEn: 'Real-time overview of villages, doctors, pending verifications, and registered patients.',
        audioMr: 'गावे, नोंदणीकृत डॉक्टर, प्रलंबित मान्यता आणि एकूण रुग्णांची सांख्यिकी येथे दिसेल.',
        audioHi: 'गाँव, पंजीकृत डॉक्टर, लंबित स्वीकृतियां और कुल मरीजों के आँकड़े यहाँ दिखते हैं।',
        audioEn: 'High-level real-time overview of villages, doctors, pending approvals, and patients.',
      ),
      TourStepItem(
        targetKey: _pendingApprovalsKey,
        icon: Icons.pending_actions_rounded,
        titleMr: 'प्रलंबित डॉक्टर मान्यता (Pending Approvals)',
        titleHi: 'लंबित डॉक्टर स्वीकृति (Pending Approvals)',
        titleEn: 'Doctor Approvals & Verification',
        descMr: 'नवीन नोंदणी केलेल्या डॉक्टरांची वैद्यकीय प्रमाणपत्रे तपासून त्यांना मान्यता द्या.',
        descHi: 'नए पंजीकृत डॉक्टरों के प्रमाणपत्र जाँचकर उन्हें स्वीकृति दें।',
        descEn: 'Verify registration credentials and grant practice access to newly registered doctors.',
        audioMr: 'नवीन नोंदणी केलेल्या डॉक्टरांची प्रमाणपत्रे तपासून त्यांना मंजुरी देण्यासाठी येथे दाबा.',
        audioHi: 'नए डॉक्टरों के प्रमाणपत्र जाँचकर उन्हें स्वीकृति देने के लिए यहाँ दबाएं।',
        audioEn: 'Review medical registrations and verify newly applied healthcare professionals.',
      ),
      TourStepItem(
        targetKey: _villagesKey,
        icon: Icons.location_on_rounded,
        titleMr: 'गावे व आरोग्य केंद्र (Villages & Centers)',
        titleHi: 'गाँव व स्वास्थ्य केंद्र (Villages & Centers)',
        titleEn: 'Villages & Health Centres',
        descMr: 'जिल्ह्यातील नवीन गावे जोडा आणि प्राथमिक आरोग्य केंद्रांची जोडणी करा.',
        descHi: 'जिले के नए गाँव जोड़ें और प्राथमिक स्वास्थ्य केंद्रों का प्रबंधन करें।',
        descEn: 'Configure administrative village boundaries and primary health centers.',
        audioMr: 'नवीन गावे आणि प्राथमिक उपकेंद्रांची जोडणी व नियंत्रण करण्यासाठी येथे जा.',
        audioHi: 'नए गाँव और प्राथमिक स्वास्थ्य केंद्रों को जोड़ने और प्रबंधित करने के लिए यहाँ जाएं।',
        audioEn: 'Configure administrative village boundaries and primary health centers.',
      ),
      TourStepItem(
        targetKey: _doctorsKey,
        icon: Icons.medical_services_rounded,
        titleMr: 'डॉक्टर निर्देशिका (Doctors Directory)',
        titleHi: 'डॉक्टर डायरेक्टरी (Doctors Directory)',
        titleEn: 'Registered Doctors Directory',
        descMr: 'सर्व सक्रिय डॉक्टरांची यादी, विशेष विभाग आणि त्यांची नेमणूक येथे तपासा.',
        descHi: 'सभी सक्रिय डॉक्टरों की सूची, विशेषता और उनकी पोस्टिंग यहाँ देखें।',
        descEn: 'Supervise the complete directory of registered physicians and clinical specialists.',
        audioMr: 'आरोग्य केंद्रातील सर्व डॉक्टरांची यादी, विशेष विभाग आणि त्यांची उपलब्धता येथे नियंत्रित करा.',
        audioHi: 'सभी डॉक्टरों की सूची, विशेषता और उनकी उपलब्धता यहाँ से प्रबंधित करें।',
        audioEn: 'Supervise the complete directory of registered physicians and clinical specialists.',
      ),
      TourStepItem(
        targetKey: _patientsKey,
        icon: Icons.people_rounded,
        titleMr: 'रुग्ण यादी (Patient Directory)',
        titleHi: 'मरीज डायरेक्टरी (Patient Directory)',
        titleEn: 'Registered Patients',
        descMr: 'आरोग्य सेवेत नोंदणी केलेल्या सर्व ग्रामीण रुग्णांची माहिती येथे उपलब्ध आहे.',
        descHi: 'स्वास्थ्य सेवा में पंजीकृत सभी ग्रामीण मरीजों की जानकारी यहाँ उपलब्ध है।',
        descEn: 'Access the registry of all registered rural patients and consultation records.',
        audioMr: 'नोंदणी केलेल्या सर्व ग्रामीण रुग्णांची माहिती आणि संपर्क येथे उपलब्ध आहे.',
        audioHi: 'पंजीकृत सभी ग्रामीण मरीजों की जानकारी और संपर्क यहाँ उपलब्ध है।',
        audioEn: 'Access the registry of all registered rural patients and consultation records.',
      ),
      TourStepItem(
        targetKey: _monitorApptsKey,
        icon: Icons.calendar_today_rounded,
        titleMr: 'अपॉइंटमेंट सनियंत्रण (Monitor Appointments)',
        titleHi: 'अपॉइंटमेंट निगरानी (Monitor Appointments)',
        titleEn: 'Audit Appointments & Queue',
        descMr: 'जिल्ह्यातील सर्व केंद्रांमधील भेटी, रांगेतील टोकन आणि तपासणी स्थितीचे सनियंत्रण करा.',
        descHi: 'जिले के सभी केंद्रों में अपॉइंटमेंट और कतार की स्थिति की निगरानी करें।',
        descEn: 'Monitor appointment queues, clinic operational efficiency, and token fulfillment.',
        audioMr: 'संपूर्ण जिल्ह्यातील सर्व आरोग्य केंद्रांमधील दैनंदिन तपासण्या आणि टोकन प्रवाह येथे तपासा.',
        audioHi: 'जिले के सभी स्वास्थ्य केंद्रों में चल रही दैनिक जाँच और टोकन प्रवाह की निगरानी करें।',
        audioEn: 'Audit appointments, queue efficiency, and consultation flow across all clinics.',
      ),
      TourStepItem(
        targetKey: _rolesKey,
        icon: Icons.admin_panel_settings_rounded,
        titleMr: 'भूमिका व्यवस्थापन (Role Management)',
        titleHi: 'भूमिका प्रबंधन (Role Management)',
        titleEn: 'User Roles & Access Control',
        descMr: 'ऑपरेटर, आशा सेविका आणि प्रशासक यांच्या अधिकारांचे वाटप व नियमन करा.',
        descHi: 'ऑपरेटर, आशा कार्यकर्ता और प्रशासकों के अधिकार यहाँ से निर्धारित करें।',
        descEn: 'Assign administrative privileges and configure system role assignments.',
        audioMr: 'आशा सेविका, ऑपरेटर आणि प्रशासकीय भूमिकांच्या परवानग्या येथे नियंत्रित करा.',
        audioHi: 'आशा कार्यकर्ता, ऑपरेटर और प्रशासनिक भूमिकाओं के अधिकार यहाँ से नियंत्रित करें।',
        audioEn: 'Configure access controls, operator designations, and role permissions.',
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
    final statsAsync = ref.watch(dashboardStatsProvider);

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
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Programme at a glance
              HomeHeader(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                child: Container(
                  key: _statsGridKey,
                  child: statsAsync.when(
                    data: (stats) => Column(
                      children: [
                        HeaderStats(stats: [
                          (tr('manage_villages'), '${stats.totalVillages}'),
                          (tr('manage_doctors'), '${stats.totalDoctors}'),
                        ]),
                        const SizedBox(height: 16),
                        HeaderStats(stats: [
                          (tr('view_patients'), '${stats.totalPatients}'),
                          (tr('pending_approvals'), '${stats.pendingDoctors}'),
                        ]),
                      ],
                    ),
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.zariBright,
                        ),
                      ),
                    ),
                    error: (e, _) => Text(
                      tr('error_generic'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(title: tr('management')),
                    DashboardTileGrid(tiles: [
                      DashboardTile(
                        key: _pendingApprovalsKey,
                        icon: Icons.pending_actions_outlined,
                        label: tr('pending_approvals'),
                        accent: AppColors.tertiary,
                        tint: AppColors.tertiaryFixed,
                        badge: statsAsync.valueOrNull?.pendingDoctors,
                        onTap: () => context.push('/admin/pending-approvals'),
                      ),
                      DashboardTile(
                        key: _monitorApptsKey,
                        icon: Icons.calendar_today_outlined,
                        label: tr('monitor_appointments'),
                        onTap: () => context.push('/admin/appointments'),
                      ),
                      DashboardTile(
                        key: _doctorsKey,
                        icon: Icons.medical_services_outlined,
                        label: tr('manage_doctors'),
                        onTap: () => context.push('/admin/doctors'),
                      ),
                      DashboardTile(
                        key: _patientsKey,
                        icon: Icons.people_outline_rounded,
                        label: tr('view_patients'),
                        onTap: () => context.push('/admin/patients'),
                      ),
                      DashboardTile(
                        key: _villagesKey,
                        icon: Icons.location_on_outlined,
                        label: tr('manage_villages'),
                        accent: AppColors.zariDeep,
                        tint: AppColors.zariSoft,
                        onTap: () => context.push('/admin/villages'),
                      ),
                      DashboardTile(
                        icon: Icons.local_hospital_outlined,
                        label: tr('manage_health_centers'),
                        accent: AppColors.zariDeep,
                        tint: AppColors.zariSoft,
                        onTap: () => context.push('/admin/health-centers'),
                      ),
                      DashboardTile(
                        key: _rolesKey,
                        icon: Icons.admin_panel_settings_outlined,
                        label: tr('role_management'),
                        accent: AppColors.info,
                        tint: AppColors.infoContainer,
                        onTap: () => context.push('/admin/roles'),
                      ),
                    ]),
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
