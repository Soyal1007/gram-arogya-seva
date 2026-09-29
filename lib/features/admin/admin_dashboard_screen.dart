import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_toggle.dart';
import 'package:gram_aarogya_seva/shared/widgets/notification_bell.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// Admin Dashboard — SRS §11.1 A-FLOW-01.
/// Stat cards + grid navigation to all admin modules.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('dashboard')),
        actions: [
          const NotificationBell(),
          const LanguageToggle(),
          const LogoutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stat Cards
              statsAsync.when(
                data: (stats) => _StatsGrid(stats: stats),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(tr('error_generic')),
              ),
              const SizedBox(height: 24),

              // ── Navigation Grid
              Text(tr('management'), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              _NavigationGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: tr('manage_villages'),
          value: '${stats.totalVillages}',
          icon: Icons.location_on,
          color: AppColors.primary,
        ),
        _StatCard(
          label: tr('manage_doctors'),
          value: '${stats.totalDoctors}',
          icon: Icons.medical_services,
          color: AppColors.secondary,
        ),
        _StatCard(
          label: tr('pending_approvals'),
          value: '${stats.pendingDoctors}',
          icon: Icons.pending_actions,
          color: AppColors.statusPending,
        ),
        _StatCard(
          label: tr('view_patients'),
          value: '${stats.totalPatients}',
          icon: Icons.people,
          color: AppColors.info,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const Spacer(),
              Text(value,
                  style: AppTextStyles.headlineMedium.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _NavigationGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(tr('pending_approvals'), Icons.pending_actions, '/admin/pending-approvals'),
      _NavItem(tr('manage_villages'), Icons.location_on, '/admin/villages'),
      _NavItem(tr('manage_health_centers'), Icons.local_hospital, '/admin/health-centers'),
      _NavItem(tr('manage_doctors'), Icons.medical_services, '/admin/doctors'),
      _NavItem(tr('view_patients'), Icons.people, '/admin/patients'),
      _NavItem(tr('monitor_appointments'), Icons.calendar_today, '/admin/appointments'),
      _NavItem(tr('role_management'), Icons.admin_panel_settings, '/admin/roles'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((item) => _NavCard(item: item)).toList(),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

class _NavCard extends StatelessWidget {
  final _NavItem item;
  const _NavCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 36, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(item.label,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
