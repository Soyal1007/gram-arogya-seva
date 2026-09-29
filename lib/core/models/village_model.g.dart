// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'village_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VillageModelImpl _$$VillageModelImplFromJson(Map<String, dynamic> json) =>
    _$VillageModelImpl(
      villageId: json['villageId'] as String,
      name: json['name'] as String,
      taluka: json['taluka'] as String,
      district: json['district'] as String,
      state: json['state'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: TimestampConverter.fromJson(json['createdAt']),
      createdBy: json['createdBy'] as String?,
      updatedAt: TimestampConverter.fromJson(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
    );

Map<String, dynamic> _$$VillageModelImplToJson(_$VillageModelImpl instance) =>
    <String, dynamic>{
      'villageId': instance.villageId,
      'name': instance.name,
      'taluka': instance.taluka,
      'district': instance.district,
      'state': instance.state,
      'isActive': instance.isActive,
      'createdAt': TimestampConverter.toJson(instance.createdAt),
      'createdBy': instance.createdBy,
      'updatedAt': TimestampConverter.toJson(instance.updatedAt),
      'updatedBy': instance.updatedBy,
    };
