// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      uid: json['uid'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      villageId: json['villageId'] as String?,
      language: json['language'] as String? ?? 'en',
      photoBase64: json['photoBase64'] as String?,
      fcmToken: json['fcmToken'] as String?,
      createdAt: TimestampConverter.fromJson(json['createdAt']),
      updatedAt: TimestampConverter.fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'phone': instance.phone,
      'role': instance.role,
      'villageId': instance.villageId,
      'language': instance.language,
      'photoBase64': instance.photoBase64,
      'fcmToken': instance.fcmToken,
      'createdAt': TimestampConverter.toJson(instance.createdAt),
      'updatedAt': TimestampConverter.toJson(instance.updatedAt),
    };
