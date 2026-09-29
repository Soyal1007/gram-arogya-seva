// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppointmentModelImpl _$$AppointmentModelImplFromJson(
  Map<String, dynamic> json,
) => _$AppointmentModelImpl(
  appointmentId: json['appointmentId'] as String,
  patientId: json['patientId'] as String,
  patientUserId: json['patientUserId'] as String?,
  patientName: json['patientName'] as String? ?? '',
  doctorId: json['doctorId'] as String,
  doctorName: json['doctorName'] as String? ?? '',
  healthCenterId: json['healthCenterId'] as String,
  villageId: json['villageId'] as String,
  date: json['date'] as String,
  timeSlot: json['timeSlot'] as String,
  slotStartAt: TimestampConverter.fromJson(json['slotStartAt']),
  reason: json['reason'] as String,
  status: json['status'] as String? ?? 'pending',
  createdBy: json['createdBy'] as String? ?? 'self',
  createdByOperatorId: json['createdByOperatorId'] as String?,
  prepInstructions: json['prepInstructions'] as String?,
  rejectionReason: json['rejectionReason'] as String?,
  cancelledAt: TimestampConverter.fromJson(json['cancelledAt']),
  cancelledBy: json['cancelledBy'] as String?,
  intakeForm: json['intakeForm'] == null
      ? const IntakeForm()
      : IntakeForm.fromJson(json['intakeForm'] as Map<String, dynamic>),
  visitSummary: json['visitSummary'] == null
      ? null
      : VisitSummary.fromJson(json['visitSummary'] as Map<String, dynamic>),
  reminderSent: json['reminderSent'] as bool? ?? false,
  createdAt: TimestampConverter.fromJson(json['createdAt']),
  updatedAt: TimestampConverter.fromJson(json['updatedAt']),
);

Map<String, dynamic> _$$AppointmentModelImplToJson(
  _$AppointmentModelImpl instance,
) => <String, dynamic>{
  'appointmentId': instance.appointmentId,
  'patientId': instance.patientId,
  'patientUserId': instance.patientUserId,
  'patientName': instance.patientName,
  'doctorId': instance.doctorId,
  'doctorName': instance.doctorName,
  'healthCenterId': instance.healthCenterId,
  'villageId': instance.villageId,
  'date': instance.date,
  'timeSlot': instance.timeSlot,
  'slotStartAt': TimestampConverter.toJson(instance.slotStartAt),
  'reason': instance.reason,
  'status': instance.status,
  'createdBy': instance.createdBy,
  'createdByOperatorId': instance.createdByOperatorId,
  'prepInstructions': instance.prepInstructions,
  'rejectionReason': instance.rejectionReason,
  'cancelledAt': TimestampConverter.toJson(instance.cancelledAt),
  'cancelledBy': instance.cancelledBy,
  'intakeForm': instance.intakeForm.toJson(),
  'visitSummary': instance.visitSummary?.toJson(),
  'reminderSent': instance.reminderSent,
  'createdAt': TimestampConverter.toJson(instance.createdAt),
  'updatedAt': TimestampConverter.toJson(instance.updatedAt),
};

_$IntakeFormImpl _$$IntakeFormImplFromJson(Map<String, dynamic> json) =>
    _$IntakeFormImpl(
      symptoms: json['symptoms'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
    );

Map<String, dynamic> _$$IntakeFormImplToJson(_$IntakeFormImpl instance) =>
    <String, dynamic>{
      'symptoms': instance.symptoms,
      'duration': instance.duration,
      'severity': instance.severity,
    };

_$VisitSummaryImpl _$$VisitSummaryImplFromJson(Map<String, dynamic> json) =>
    _$VisitSummaryImpl(
      notes: json['notes'] as String? ?? '',
      prescription: json['prescription'] as String? ?? '',
      nextSteps: json['nextSteps'] as String? ?? '',
      followUpDate: json['followUpDate'] as String?,
    );

Map<String, dynamic> _$$VisitSummaryImplToJson(_$VisitSummaryImpl instance) =>
    <String, dynamic>{
      'notes': instance.notes,
      'prescription': instance.prescription,
      'nextSteps': instance.nextSteps,
      'followUpDate': instance.followUpDate,
    };
