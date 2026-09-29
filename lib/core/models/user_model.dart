import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gram_aarogya_seva/core/converters/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// SRS §7.3 — users/{uid} auth identity for all roles.
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String name,
    required String phone,
    required String role,
    String? villageId,
    @Default('en') String language,
    String? photoBase64,
    String? fcmToken,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? createdAt,
    @JsonKey(fromJson: TimestampConverter.fromJson, toJson: TimestampConverter.toJson)
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Creates a new user document on first OTP login.
  factory UserModel.newPatient({
    required String uid,
    required String phone,
  }) {
    return UserModel(
      uid: uid,
      name: '',
      phone: phone,
      role: 'patient',
      language: 'en',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}


