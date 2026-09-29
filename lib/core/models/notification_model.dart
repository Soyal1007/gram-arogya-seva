import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// SRS §7.8 — notifications/{notificationId}.
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    // Document id, needed to mark the notification read.
    @Default('') String notificationId,
    required String userId,
    required String type,
    required String title,
    required String message,
    @Default('') String relatedId,
    @Default(false) bool isRead,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}


