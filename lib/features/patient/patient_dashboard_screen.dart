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
import 'package:gram_aarogya_seva/shared/widgets/emergency_helpline_sheet.dart';
import 'package:gram_aarogya_seva/features/patient/patient_providers.dart';

/// Patient Home Screen — Rural Healthcare Interface.
/// Features high contrast, prominent multilingual toggling (Marathi, Hindi, English),
/// intuitive service cards, accessible 56dp+ touch targets, and interactive Guided Tour.
class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => GuidedTourDialog.show(context),
          ),
          const NotificationBell(),
          const LogoutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GuidedTourDialog.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.school_rounded, size: 22),
        label: Text(
          tr('guided_tour'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientProfileProvider);
          ref.invalidate(myAppointmentsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Language Bar
              const _QuickLanguageBar(),
              const SizedBox(height: 14),

              // 2. Profile Greeting or Warning Card
              profileAsync.when(
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
              const SizedBox(height: 16),

              // 3. Guided Tour Banner
              const _GuidedTourCard(),
              const SizedBox(height: 20),

              // 4. Quick Services (2x2 Grid)
              Text(
                tr('quick_actions'),
                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ServicesGrid(profileAsync: profileAsync),
              const SizedBox(height: 24),

              // 5. My Appointments Section
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
      ),
    );
  }

  static void _handleBookNavigation(
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
}

/// Prominent 1-tap language toggle bar for rural users.
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
          const Spacer(),
          _buildPill(context, 'mr', 'मराठी', currentCode == 'mr'),
          const SizedBox(width: 6),
          _buildPill(context, 'hi', 'हिंदी', currentCode == 'hi'),
          const SizedBox(width: 6),
          _buildPill(context, 'en', 'English', currentCode == 'en'),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Reassuring Guided Tour Card at the top of the dashboard.
class _GuidedTourCard extends StatelessWidget {
  const _GuidedTourCard();

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
          onTap: () => GuidedTourDialog.show(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF2E7D32), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tr('guided_tour_title'),
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
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
                                fontSize: 10,
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
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
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

/// 2x2 Services Grid for high-contrast, effortless rural navigation.
class _ServicesGrid extends ConsumerWidget {
  const _ServicesGrid({required this.profileAsync});

  final AsyncValue<dynamic> profileAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            // 1. Book Appointment
            Expanded(
              child: _ActionTile(
                title: tr('book_appointment'),
                subtitle: tr('book_apt_subtitle'),
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF1B5E20),
                backgroundColor: const Color(0xFFE8F5E9),
                borderColor: const Color(0xFFC8E6C9),
                onTap: () => PatientDashboardScreen._handleBookNavigation(context, profileAsync),
              ),
            ),
            const SizedBox(width: 12),
            // 2. Health Records
            Expanded(
              child: _ActionTile(
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
      constraints: const BoxConstraints(minHeight: 140),
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
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
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: iconColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0B2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_rounded, color: Color(0xFFE65100), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('complete_profile_first'),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr('tap_create_profile'),
                  style: AppTextStyles.caption.copyWith(color: const Color(0xFFBF360C)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push(AppConstants.routePatientProfile),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('create_profile')),
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
      padding: const EdgeInsets.all(16),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('patient_greeting', args: [name]),
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${tr("village_label_short")}: ${villageName ?? tr("loading")}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(28),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 18),
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

/// Individual Appointment Card with clear badges and rural accessibility.
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${AppDateUtils.toDisplayDate(apt.date)} • ${AppDateUtils.formatSlotForDisplay(apt.timeSlot)}',
                        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: apt.status),
              ],
            ),
            const Divider(height: 20),
            if (apt.doctorName.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    tr('doctor_name', args: [apt.doctorName]),
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            if (centerName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      centerName,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              tr('reason_label', args: [apt.reason]),
              style: AppTextStyles.caption.copyWith(color: AppColors.onSurfaceVariant),
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
              const SizedBox(height: 12),
              if (_isCancelling)
                const Center(child: CircularProgressIndicator())
              else if (canCancel)
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _cancelAppointment,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                      tr('cancel_appointment'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
