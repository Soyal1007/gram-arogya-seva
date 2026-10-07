import 'package:flutter/foundation.dart';
import 'package:gram_aarogya_seva/core/services/firestore_service.dart';
import 'package:gram_aarogya_seva/core/utils/maharashtra_locations.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';

/// Seed service to populate authentic Maharashtra districts, talukas, villages, and health centres.
/// SRS §7 & changes.md §7: Authentic Maharashtra village & PHC dataset seed mechanism.
class SeedService {
  final FirestoreService _firestoreService;

  SeedService(this._firestoreService);

  /// Seeds Maharashtra locations if the villages collection is currently empty.
  Future<bool> seedMaharashtraLocationsIfEmpty() async {
    try {
      final villageCount = await _firestoreService.countDocuments('villages');
      if (villageCount > 0) {
        debugPrint('[SeedService] Villages collection already populated ($villageCount docs). Skipping seed.');
        return false;
      }

      debugPrint('[SeedService] Starting seed of Maharashtra location data...');
      final seedData = MaharashtraLocationData.generateInitialSeedData();
      final villages = seedData['villages'] as List<VillageModel>;
      final healthCenters = seedData['healthCenters'] as List<HealthCenterModel>;

      for (final village in villages) {
        await _firestoreService.createVillage(village);
      }

      for (final center in healthCenters) {
        await _firestoreService.createHealthCenter(center);
      }

      debugPrint('[SeedService] Successfully seeded ${villages.length} villages & ${healthCenters.length} health centres!');
      return true;
    } catch (e) {
      debugPrint('[SeedService] Error seeding Maharashtra locations: $e');
      return false;
    }
  }
}
