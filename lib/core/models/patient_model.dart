import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'patient_model.freezed.dart';
part 'patient_model.g.dart';

/// SRS §7.5 — patients/{patientId} clinical and demographic data.
@freezed
class PatientModel with _$PatientModel {
  @JsonSerializable(explicitToJson: true)
  const factory PatientModel({
    required String patientId,
    String? userId, // null if operator-registered without phone
    required String name,
    required String dob,
    required String gender,
    required String villageId,
    String? mobile, // nullable per SRS for non-phone patients
    String? photoBase64,
    @Default(EmergencyContact()) EmergencyContact emergencyContact,
    @Default(MedicalBackground()) MedicalBackground medicalBackground,
    @Default('self') String createdBy,
    String? createdByOperatorId,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? updatedAt,
  }) = _PatientModel;

  factory PatientModel.fromJson(Map<String, dynamic> json) =>
      _$PatientModelFromJson(json);
}

@freezed
class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    @Default('') String name,
    @Default('') String phone,
  }) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);
}

@freezed
class MedicalBackground with _$MedicalBackground {
  const factory MedicalBackground({
    @Default([]) List<String> conditions,
    @Default([]) List<String> medications,
    @Default([]) List<String> allergies,
  }) = _MedicalBackground;

  factory MedicalBackground.fromJson(Map<String, dynamic> json) =>
      _$MedicalBackgroundFromJson(json);
}


