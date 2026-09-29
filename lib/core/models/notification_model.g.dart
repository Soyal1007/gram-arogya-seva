// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationModelImpl(
  notificationId: json['notificationId'] as String? ?? '',
  userId: json['userId'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  message: json['message'] as String,
  relatedId: json['relatedId'] as String? ?? '',
  isRead: json['isRead'] as bool? ?? false,
  createdAt: TimestampConverter.fromJson(json['createdAt']),
);

Map<String, dynamic> _$$NotificationModelImplToJson(
  _$NotificationModelImpl instance,
) => <String, dynamic>{
  'notificationId': instance.notificationId,
  'userId': instance.userId,
  'type': instance.type,
  'title': instance.title,
  'message': instance.message,
  'relatedId': instance.relatedId,
  'isRead': instance.isRead,
  'createdAt': TimestampConverter.toJson(instance.createdAt),
};
