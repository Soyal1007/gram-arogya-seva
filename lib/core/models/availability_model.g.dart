// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AvailabilityModelImpl _$$AvailabilityModelImplFromJson(
  Map<String, dynamic> json,
) => _$AvailabilityModelImpl(
  doctorId: json['doctorId'] as String,
  healthCenterId: json['healthCenterId'] as String,
  date: json['date'] as String,
  slots:
      (json['slots'] as List<dynamic>?)
          ?.map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: TimestampConverter.fromJson(json['createdAt']),
  lastUpdatedBy: json['lastUpdatedBy'] as String?,
  updatedAt: TimestampConverter.fromJson(json['updatedAt']),
);

Map<String, dynamic> _$$AvailabilityModelImplToJson(
  _$AvailabilityModelImpl instance,
) => <String, dynamic>{
  'doctorId': instance.doctorId,
  'healthCenterId': instance.healthCenterId,
  'date': instance.date,
  'slots': instance.slots.map((e) => e.toJson()).toList(),
  'createdAt': TimestampConverter.toJson(instance.createdAt),
  'lastUpdatedBy': instance.lastUpdatedBy,
  'updatedAt': TimestampConverter.toJson(instance.updatedAt),
};

_$SlotModelImpl _$$SlotModelImplFromJson(Map<String, dynamic> json) =>
    _$SlotModelImpl(
      time: json['time'] as String,
      isBooked: json['isBooked'] as bool? ?? false,
      appointmentId: json['appointmentId'] as String?,
    );

Map<String, dynamic> _$$SlotModelImplToJson(_$SlotModelImpl instance) =>
    <String, dynamic>{
      'time': instance.time,
      'isBooked': instance.isBooked,
      'appointmentId': instance.appointmentId,
    };
