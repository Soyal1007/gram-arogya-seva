import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'health_center_model.freezed.dart';
part 'health_center_model.g.dart';

/// SRS §7.2 — health_centers/{centerId}.
@freezed
class HealthCenterModel with _$HealthCenterModel {
  const factory HealthCenterModel({
    required String centerId,
    required String name,
    required String villageId,
    @Default('') String address,
    @Default('') String phone,
    @Default(true) bool isActive,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
    String? createdBy,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? updatedAt,
    String? updatedBy,
  }) = _HealthCenterModel;

  factory HealthCenterModel.fromJson(Map<String, dynamic> json) =>
      _$HealthCenterModelFromJson(json);
}


