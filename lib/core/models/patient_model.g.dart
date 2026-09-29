// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PatientModelImpl _$$PatientModelImplFromJson(Map<String, dynamic> json) =>
    _$PatientModelImpl(
      patientId: json['patientId'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      dob: json['dob'] as String,
      gender: json['gender'] as String,
      villageId: json['villageId'] as String,
      mobile: json['mobile'] as String?,
      photoBase64: json['photoBase64'] as String?,
      emergencyContact: json['emergencyContact'] == null
          ? const EmergencyContact()
          : EmergencyContact.fromJson(
              json['emergencyContact'] as Map<String, dynamic>,
            ),
      medicalBackground: json['medicalBackground'] == null
          ? const MedicalBackground()
          : MedicalBackground.fromJson(
              json['medicalBackground'] as Map<String, dynamic>,
            ),
      createdBy: json['createdBy'] as String? ?? 'self',
      createdByOperatorId: json['createdByOperatorId'] as String?,
      createdAt: TimestampConverter.fromJson(json['createdAt']),
      updatedAt: TimestampConverter.fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$PatientModelImplToJson(_$PatientModelImpl instance) =>
    <String, dynamic>{
      'patientId': instance.patientId,
      'userId': instance.userId,
      'name': instance.name,
      'dob': instance.dob,
      'gender': instance.gender,
      'villageId': instance.villageId,
      'mobile': instance.mobile,
      'photoBase64': instance.photoBase64,
      'emergencyContact': instance.emergencyContact.toJson(),
      'medicalBackground': instance.medicalBackground.toJson(),
      'createdBy': instance.createdBy,
      'createdByOperatorId': instance.createdByOperatorId,
      'createdAt': TimestampConverter.toJson(instance.createdAt),
      'updatedAt': TimestampConverter.toJson(instance.updatedAt),
    };

_$EmergencyContactImpl _$$EmergencyContactImplFromJson(
  Map<String, dynamic> json,
) => _$EmergencyContactImpl(
  name: json['name'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
);

Map<String, dynamic> _$$EmergencyContactImplToJson(
  _$EmergencyContactImpl instance,
) => <String, dynamic>{'name': instance.name, 'phone': instance.phone};

_$MedicalBackgroundImpl _$$MedicalBackgroundImplFromJson(
  Map<String, dynamic> json,
) => _$MedicalBackgroundImpl(
  conditions:
      (json['conditions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  medications:
      (json['medications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  allergies:
      (json['allergies'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$MedicalBackgroundImplToJson(
  _$MedicalBackgroundImpl instance,
) => <String, dynamic>{
  'conditions': instance.conditions,
  'medications': instance.medications,
  'allergies': instance.allergies,
};
