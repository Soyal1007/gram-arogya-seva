import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'village_model.freezed.dart';
part 'village_model.g.dart';

/// SRS §7.1 — villages/{villageId} geographic anchor.
@freezed
class VillageModel with _$VillageModel {
  const factory VillageModel({
    required String villageId,
    required String name,
    required String taluka,
    required String district,
    required String state,
    @Default(true) bool isActive,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
    String? createdBy,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? updatedAt,
    String? updatedBy,
  }) = _VillageModel;

  factory VillageModel.fromJson(Map<String, dynamic> json) =>
      _$VillageModelFromJson(json);
}


