import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';

/// Reusable dependent location picker widget per changes.md §8:
/// District -> Taluka -> Village -> Health Centre selector.
class LocationPickerWidget extends ConsumerStatefulWidget {
  final String? initialVillageId;
  final String? initialHealthCenterId;
  final ValueChanged<VillageModel?> onVillageSelected;
  final ValueChanged<HealthCenterModel?>? onHealthCenterSelected;
  final bool showHealthCenter;
  final String? Function(String?)? villageValidator;

  const LocationPickerWidget({
    super.key,
    this.initialVillageId,
    this.initialHealthCenterId,
    required this.onVillageSelected,
    this.onHealthCenterSelected,
    this.showHealthCenter = true,
    this.villageValidator,
  });

  @override
  ConsumerState<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends ConsumerState<LocationPickerWidget> {
  String? _selectedDistrict;
  String? _selectedTaluka;
  String? _selectedVillageId;
  String? _selectedHealthCenterId;

  @override
  void initState() {
    super.initState();
    _selectedVillageId = widget.initialVillageId;
    _selectedHealthCenterId = widget.initialHealthCenterId;
  }

  void _syncInitialHierarchy(Map<String, VillageModel> villages) {
    if (_selectedVillageId != null && villages.containsKey(_selectedVillageId)) {
      final v = villages[_selectedVillageId]!;
      if (_selectedDistrict == null) {
        _selectedDistrict = v.district;
        _selectedTaluka = v.taluka;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final villagesById = ref.watch(villagesByIdProvider);
    _syncInitialHierarchy(villagesById);

    final districts = ref.watch(availableDistrictsProvider);
    final talukas = ref.watch(talukasByDistrictProvider(_selectedDistrict));
    final villages = ref.watch(
      villagesByTalukaProvider((district: _selectedDistrict, taluka: _selectedTaluka)),
    );
    final healthCenters = ref.watch(healthCentersByVillageProvider(_selectedVillageId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District Selector
        DropdownButtonFormField<String>(
          value: districts.contains(_selectedDistrict) ? _selectedDistrict : null,
          decoration: InputDecoration(
            labelText: tr('district_label'),
            prefixIcon: const Icon(Icons.map_rounded),
          ),
          items: districts
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedDistrict = val;
              _selectedTaluka = null;
              _selectedVillageId = null;
              _selectedHealthCenterId = null;
            });
            widget.onVillageSelected(null);
            widget.onHealthCenterSelected?.call(null);
          },
        ),
        const SizedBox(height: 12),

        // Taluka Selector
        DropdownButtonFormField<String>(
          value: talukas.contains(_selectedTaluka) ? _selectedTaluka : null,
          decoration: InputDecoration(
            labelText: tr('taluka_label'),
            prefixIcon: const Icon(Icons.location_city_rounded),
          ),
          items: talukas
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  ))
              .toList(),
          onChanged: _selectedDistrict == null
              ? null
              : (val) {
                  setState(() {
                    _selectedTaluka = val;
                    _selectedVillageId = null;
                    _selectedHealthCenterId = null;
                  });
                  widget.onVillageSelected(null);
                  widget.onHealthCenterSelected?.call(null);
                },
        ),
        const SizedBox(height: 12),

        // Village Selector
        DropdownButtonFormField<String>(
          value: villages.any((v) => v.villageId == _selectedVillageId)
              ? _selectedVillageId
              : null,
          decoration: InputDecoration(
            labelText: tr('village_label'),
            prefixIcon: const Icon(Icons.home_work_rounded),
          ),
          validator: widget.villageValidator,
          items: villages
              .map((v) => DropdownMenuItem(
                    value: v.villageId,
                    child: Text(v.name),
                  ))
              .toList(),
          onChanged: _selectedTaluka == null
              ? null
              : (val) {
                  final vModel = val != null ? villages.cast<VillageModel?>().firstWhere((v) => v?.villageId == val, orElse: () => null) : null;
                  setState(() {
                    _selectedVillageId = val;
                    _selectedHealthCenterId = null;
                  });
                  widget.onVillageSelected(vModel);
                  widget.onHealthCenterSelected?.call(null);
                },
        ),

        // Health Center Selector (Optional)
        if (widget.showHealthCenter) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: healthCenters.any((c) => c.centerId == _selectedHealthCenterId)
                ? _selectedHealthCenterId
                : null,
            decoration: InputDecoration(
              labelText: tr('health_center_label'),
              prefixIcon: const Icon(Icons.local_hospital_rounded),
            ),
            items: healthCenters
                .map((c) => DropdownMenuItem(
                      value: c.centerId,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: _selectedVillageId == null
                ? null
                : (val) {
                    final cModel = val != null ? healthCenters.cast<HealthCenterModel?>().firstWhere((c) => c?.centerId == val, orElse: () => null) : null;
                    setState(() {
                      _selectedHealthCenterId = val;
                    });
                    widget.onHealthCenterSelected?.call(cModel);
                  },
          ),
        ],
      ],
    );
  }
}
