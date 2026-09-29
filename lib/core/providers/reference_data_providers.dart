import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';

/// Reference data — villages and health centres.
///
/// These collections are small, slow-changing and referenced by id from almost
/// every other document, so the UI needs them constantly in order to render a
/// name where the database stores an id.
///
/// Reading them as two live collection streams (the first implementation) was
/// correct but expensive: every cold app start paid for the entire dataset, on
/// every screen that resolved a name — the largest avoidable read cost in the
/// system (FIREBASE_AUDIT.md §7.2a).
///
/// They are now read from a single `reference/current` document maintained by
/// Cloud Functions: ~150 reads per session become 1.
///
/// The collection streams survive as a **fallback** for the window between
/// deploying the rules and the first `rebuildReferenceData` call, so names
/// never regress to raw ids during a migration.

/// Raw aggregate document. Null when it has not been built yet.
final _referenceDocProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(firestoreServiceProvider).streamReferenceData();
});

/// Fallback: the villages collection, watched only while the aggregate is absent.
final _villagesFallbackProvider =
    StreamProvider<Map<String, VillageModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamAllVillages().map(
        (villages) => {for (final v in villages) v.villageId: v},
      );
});

/// Fallback: active health centres, watched only while the aggregate is absent.
final _healthCentersFallbackProvider =
    StreamProvider<Map<String, HealthCenterModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamHealthCenters().map(
        (centers) => {for (final c in centers) c.centerId: c},
      );
});

/// All villages, keyed by id.
final villagesByIdProvider = Provider<Map<String, VillageModel>>((ref) {
  final aggregate = ref.watch(_referenceDocProvider);

  // Still loading — return empty rather than starting a fallback listener we
  // would immediately throw away.
  if (aggregate.isLoading) return const {};

  final data = aggregate.valueOrNull;
  if (data == null) {
    // Aggregate not built yet: read the collection directly. The dependency is
    // conditional on purpose — once the aggregate exists this provider stops
    // watching the fallback and the collection listener is disposed.
    return ref.watch(_villagesFallbackProvider).valueOrNull ?? const {};
  }

  final villages = (data['villages'] as Map<String, dynamic>?) ?? const {};
  return villages.map((id, raw) {
    final entry = raw as Map<String, dynamic>;
    return MapEntry(
      id,
      VillageModel(
        villageId: id,
        name: entry['name'] as String? ?? '',
        taluka: entry['taluka'] as String? ?? '',
        district: entry['district'] as String? ?? '',
        state: entry['state'] as String? ?? '',
        isActive: entry['isActive'] as bool? ?? true,
      ),
    );
  });
});

/// All health centres, keyed by id.
final healthCentersByIdProvider =
    Provider<Map<String, HealthCenterModel>>((ref) {
  final aggregate = ref.watch(_referenceDocProvider);
  if (aggregate.isLoading) return const {};

  final data = aggregate.valueOrNull;
  if (data == null) {
    return ref.watch(_healthCentersFallbackProvider).valueOrNull ?? const {};
  }

  final centers = (data['healthCenters'] as Map<String, dynamic>?) ?? const {};
  return centers.map((id, raw) {
    final entry = raw as Map<String, dynamic>;
    return MapEntry(
      id,
      HealthCenterModel(
        centerId: id,
        name: entry['name'] as String? ?? '',
        villageId: entry['villageId'] as String? ?? '',
        address: entry['address'] as String? ?? '',
        phone: entry['phone'] as String? ?? '',
        isActive: entry['isActive'] as bool? ?? true,
      ),
    );
  });
});

/// Resolves a village name. Never returns a raw id — an id means nothing to a
/// villager.
final villageNameProvider = Provider.family<String?, String?>((ref, villageId) {
  if (villageId == null || villageId.isEmpty) return null;
  return ref.watch(villagesByIdProvider)[villageId]?.name;
});

/// Resolves a health centre name.
final healthCenterNameProvider =
    Provider.family<String?, String?>((ref, centerId) {
  if (centerId == null || centerId.isEmpty) return null;
  return ref.watch(healthCentersByIdProvider)[centerId]?.name;
});

/// Active villages, sorted by name — for pickers and filters.
final activeVillagesProvider = Provider<List<VillageModel>>((ref) {
  final villages = ref.watch(villagesByIdProvider).values
      .where((v) => v.isActive)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return villages;
});
