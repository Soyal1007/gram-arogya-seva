import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'availability_model.freezed.dart';
part 'availability_model.g.dart';

/// SRS §7.6 — doctor_availability/{doctorId}_{YYYY-MM-DD}.
@freezed
class AvailabilityModel with _$AvailabilityModel {
  @JsonSerializable(explicitToJson: true)
  const factory AvailabilityModel({
    required String doctorId,
    required String healthCenterId,
    required String date,
    @Default([]) List<SlotModel> slots,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
    String? lastUpdatedBy,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? updatedAt,
  }) = _AvailabilityModel;

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityModelFromJson(json);
}

@freezed
class SlotModel with _$SlotModel {
  const factory SlotModel({
    required String time,
    @Default(false) bool isBooked,
    String? appointmentId,
  }) = _SlotModel;

  factory SlotModel.fromJson(Map<String, dynamic> json) =>
      _$SlotModelFromJson(json);
}


