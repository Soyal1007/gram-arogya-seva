// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DoctorModelImpl _$$DoctorModelImplFromJson(Map<String, dynamic> json) =>
    _$DoctorModelImpl(
      doctorId: json['doctorId'] as String,
      name: json['name'] as String,
      specialization: json['specialization'] as String,
      mobile: json['mobile'] as String,
      nmrId: json['nmrId'] as String,
      hprId: json['hprId'] as String,
      aadhaarHash: json['aadhaarHash'] as String,
      aadhaarLastFour: json['aadhaarLastFour'] as String,
      abdmTxnId: json['abdmTxnId'] as String?,
      photoBase64: json['photoBase64'] as String?,
      villages:
          (json['villages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'pending_approval',
      rejectionNote: json['rejectionNote'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: TimestampConverter.fromJson(json['approvedAt']),
      createdAt: TimestampConverter.fromJson(json['createdAt']),
      updatedAt: TimestampConverter.fromJson(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
    );

Map<String, dynamic> _$$DoctorModelImplToJson(_$DoctorModelImpl instance) =>
    <String, dynamic>{
      'doctorId': instance.doctorId,
      'name': instance.name,
      'specialization': instance.specialization,
      'mobile': instance.mobile,
      'nmrId': instance.nmrId,
      'hprId': instance.hprId,
      'aadhaarHash': instance.aadhaarHash,
      'aadhaarLastFour': instance.aadhaarLastFour,
      'abdmTxnId': instance.abdmTxnId,
      'photoBase64': instance.photoBase64,
      'villages': instance.villages,
      'status': instance.status,
      'rejectionNote': instance.rejectionNote,
      'approvedBy': instance.approvedBy,
      'approvedAt': TimestampConverter.toJson(instance.approvedAt),
      'createdAt': TimestampConverter.toJson(instance.createdAt),
      'updatedAt': TimestampConverter.toJson(instance.updatedAt),
      'updatedBy': instance.updatedBy,
    };
