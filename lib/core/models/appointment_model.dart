import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'appointment_model.freezed.dart';
part 'appointment_model.g.dart';

/// SRS §7.7 — appointments/{appointmentId}.
/// Includes all corrected fields: patientUserId, patientName,
/// cancelled/no_show statuses, reminderSent, cancelledAt/By.
@freezed
class AppointmentModel with _$AppointmentModel {
  @JsonSerializable(explicitToJson: true)
  const factory AppointmentModel({
    required String appointmentId,
    required String patientId,
    String? patientUserId, // denormalized for security rules
    @Default('') String patientName, // denormalized for doctor display
    required String doctorId,
    @Default('') String doctorName, // denormalized for patient display
    required String healthCenterId,
    required String villageId,
    required String date,
    required String timeSlot,
    // Absolute instant of the slot, computed server-side from date + timeSlot
    // in Asia/Kolkata. String date/time cannot be ordered or compared, which
    // is what made the cancellation window unenforceable (Assessment A17-2).
    // Nullable: documents written before this field existed do not carry it.
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? slotStartAt,
    required String reason,
    @Default('pending') String status,
    @Default('self') String createdBy,
    String? createdByOperatorId,
    String? prepInstructions,
    String? rejectionReason,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? cancelledAt,
    String? cancelledBy,
    @Default(IntakeForm()) IntakeForm intakeForm,
    VisitSummary? visitSummary,
    @Default(false) bool reminderSent,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? updatedAt,
  }) = _AppointmentModel;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      _$AppointmentModelFromJson(json);
}

@freezed
class IntakeForm with _$IntakeForm {
  const factory IntakeForm({
    @Default('') String symptoms,
    @Default('') String duration,
    @Default('') String severity, // "mild" | "moderate" | "severe"
  }) = _IntakeForm;

  factory IntakeForm.fromJson(Map<String, dynamic> json) =>
      _$IntakeFormFromJson(json);
}

@freezed
class VisitSummary with _$VisitSummary {
  const factory VisitSummary({
    @Default('') String notes,
    @Default('') String prescription,
    @Default('') String nextSteps,
    String? followUpDate,
  }) = _VisitSummary;

  factory VisitSummary.fromJson(Map<String, dynamic> json) =>
      _$VisitSummaryFromJson(json);
}


