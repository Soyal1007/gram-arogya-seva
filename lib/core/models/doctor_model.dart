import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'doctor_model.freezed.dart';
part 'doctor_model.g.dart';

/// SRS §7.4 — doctors/{doctorId} professional profile.
@freezed
class DoctorModel with _$DoctorModel {
  const factory DoctorModel({
    required String doctorId,
    required String name,
    required String specialization,
    required String mobile,
    required String nmrId,
    required String hprId,
    required String aadhaarHash,
    required String aadhaarLastFour,
    String? abdmTxnId,
    String? photoBase64,
    @Default([]) List<String> villages,
    @Default('pending_approval') String status,
    String? rejectionNote,
    String? approvedBy,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? approvedAt,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? updatedAt,
    String? updatedBy,
  }) = _DoctorModel;

  factory DoctorModel.fromJson(Map<String, dynamic> json) =>
      _$DoctorModelFromJson(json);
}


