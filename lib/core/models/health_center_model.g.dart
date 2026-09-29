// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_center_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HealthCenterModelImpl _$$HealthCenterModelImplFromJson(
  Map<String, dynamic> json,
) => _$HealthCenterModelImpl(
  centerId: json['centerId'] as String,
  name: json['name'] as String,
  villageId: json['villageId'] as String,
  address: json['address'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? true,
  createdAt: TimestampConverter.fromJson(json['createdAt']),
  createdBy: json['createdBy'] as String?,
  updatedAt: TimestampConverter.fromJson(json['updatedAt']),
  updatedBy: json['updatedBy'] as String?,
);

Map<String, dynamic> _$$HealthCenterModelImplToJson(
  _$HealthCenterModelImpl instance,
) => <String, dynamic>{
  'centerId': instance.centerId,
  'name': instance.name,
  'villageId': instance.villageId,
  'address': instance.address,
  'phone': instance.phone,
  'isActive': instance.isActive,
  'createdAt': TimestampConverter.toJson(instance.createdAt),
  'createdBy': instance.createdBy,
  'updatedAt': TimestampConverter.toJson(instance.updatedAt),
  'updatedBy': instance.updatedBy,
};
