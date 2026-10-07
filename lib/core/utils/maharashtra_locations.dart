import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';

/// Authoritative dataset of Maharashtra administrative structure (Districts -> Talukas -> Villages -> PHCs).
/// SRS §7 & changes.md §7: Authentic Maharashtra location data for Gram Aarogya Seva.
class MaharashtraLocationData {
  static const String state = 'Maharashtra';

  /// Initial districts and their talukas with authentic villages and Primary Health Centres (PHCs).
  static final List<Map<String, dynamic>> rawLocationHierarchy = [
    {
      'district': 'Pune',
      'talukas': [
        {
          'taluka': 'Haveli',
          'villages': [
            {
              'name': 'Wagholi',
              'phc': 'Wagholi Primary Health Centre',
              'address': 'Nagar Road, Wagholi, Haveli, Pune 412207',
              'phone': '+91 20 27050123'
            },
            {
              'name': 'Uruli Kanchan',
              'phc': 'Uruli Kanchan Primary Health Centre',
              'address': 'Solapur Highway, Uruli Kanchan, Haveli, Pune 412202',
              'phone': '+91 20 26926222'
            },
            {
              'name': 'Khadakwasla',
              'phc': 'Khadakwasla Rural Hospital',
              'address': 'Near Dam, Khadakwasla, Haveli, Pune 411024',
              'phone': '+91 20 24389010'
            },
          ]
        },
        {
          'taluka': 'Baramati',
          'villages': [
            {
              'name': 'Malegaon Budruk',
              'phc': 'Malegaon BK Primary Health Centre',
              'address': 'Baramati-Nira Road, Malegaon BK, Baramati, Pune 413115',
              'phone': '+91 2112 254200'
            },
            {
              'name': 'Supe',
              'phc': 'Supe Rural Hospital & PHC',
              'address': 'Main Market, Supe, Baramati, Pune 412204',
              'phone': '+91 2112 283100'
            }
          ]
        },
        {
          'taluka': 'Junar',
          'villages': [
            {
              'name': 'Ozar',
              'phc': 'Ozar Primary Health Centre',
              'address': 'Near Temple Complex, Ozar, Junnar, Pune 410502',
              'phone': '+91 2132 288340'
            },
            {
              'name': 'Narayangaon',
              'phc': 'Narayangaon Rural Hospital',
              'address': 'Nashik Highway, Narayangaon, Junnar, Pune 410504',
              'phone': '+91 2132 242030'
            }
          ]
        }
      ]
    },
    {
      'district': 'Nashik',
      'talukas': [
        {
          'taluka': 'Niphad',
          'villages': [
            {
              'name': 'Pimpalgaon Baswant',
              'phc': 'Pimpalgaon Baswant PHC',
              'address': 'NH-3, Pimpalgaon Baswant, Niphad, Nashik 422209',
              'phone': '+91 2550 250100'
            },
            {
              'name': 'Lasalgaon',
              'phc': 'Lasalgaon Rural Health Centre',
              'address': 'Station Road, Lasalgaon, Niphad, Nashik 422306',
              'phone': '+91 2550 266220'
            }
          ]
        },
        {
          'taluka': 'Dindori',
          'villages': [
            {
              'name': 'Vani',
              'phc': 'Vani Primary Health Centre',
              'address': 'Saptashrungi Road, Vani, Dindori, Nashik 422215',
              'phone': '+91 2557 235210'
            }
          ]
        }
      ]
    },
    {
      'district': 'Satara',
      'talukas': [
        {
          'taluka': 'Karad',
          'villages': [
            {
              'name': 'Umbraj',
              'phc': 'Umbraj Primary Health Centre',
              'address': 'NH-48, Umbraj, Karad, Satara 415109',
              'phone': '+91 2164 264050'
            },
            {
              'name': 'Rethare Budruk',
              'phc': 'Rethare BK Health Centre',
              'address': 'Factory Area, Rethare BK, Karad, Satara 415108',
              'phone': '+91 2164 252110'
            }
          ]
        }
      ]
    }
  ];

  /// Generates initial seed models for Firestore / local initialization.
  static Map<String, dynamic> generateInitialSeedData() {
    final List<VillageModel> villages = [];
    final List<HealthCenterModel> healthCenters = [];

    int vId = 100;
    int cId = 500;

    for (var dist in rawLocationHierarchy) {
      final districtName = dist['district'] as String;
      final talukas = dist['talukas'] as List<dynamic>;

      for (var tal in talukas) {
        final talukaName = tal['taluka'] as String;
        final vList = tal['villages'] as List<dynamic>;

        for (var v in vList) {
          final villageId = 'v_$vId';
          final centerId = 'hc_$cId';

          villages.add(
            VillageModel(
              villageId: villageId,
              name: v['name'] as String,
              taluka: talukaName,
              district: districtName,
              state: state,
              isActive: true,
            ),
          );

          healthCenters.add(
            HealthCenterModel(
              centerId: centerId,
              name: v['phc'] as String,
              villageId: villageId,
              address: v['address'] as String,
              phone: v['phone'] as String,
              isActive: true,
            ),
          );

          vId++;
          cId++;
        }
      }
    }

    return {
      'villages': villages,
      'healthCenters': healthCenters,
    };
  }
}
