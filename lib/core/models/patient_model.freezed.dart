// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PatientModel _$PatientModelFromJson(Map<String, dynamic> json) {
  return _PatientModel.fromJson(json);
}

/// @nodoc
mixin _$PatientModel {
  String get patientId => throw _privateConstructorUsedError;
  String? get userId =>
      throw _privateConstructorUsedError; // null if operator-registered without phone
  String get name => throw _privateConstructorUsedError;
  String get dob => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String get villageId => throw _privateConstructorUsedError;
  String? get mobile =>
      throw _privateConstructorUsedError; // nullable per SRS for non-phone patients
  String? get photoBase64 => throw _privateConstructorUsedError;
  EmergencyContact get emergencyContact => throw _privateConstructorUsedError;
  MedicalBackground get medicalBackground => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String? get createdByOperatorId => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PatientModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PatientModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PatientModelCopyWith<PatientModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PatientModelCopyWith<$Res> {
  factory $PatientModelCopyWith(
    PatientModel value,
    $Res Function(PatientModel) then,
  ) = _$PatientModelCopyWithImpl<$Res, PatientModel>;
  @useResult
  $Res call({
    String patientId,
    String? userId,
    String name,
    String dob,
    String gender,
    String villageId,
    String? mobile,
    String? photoBase64,
    EmergencyContact emergencyContact,
    MedicalBackground medicalBackground,
    String createdBy,
    String? createdByOperatorId,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? createdAt,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? updatedAt,
  });

  $EmergencyContactCopyWith<$Res> get emergencyContact;
  $MedicalBackgroundCopyWith<$Res> get medicalBackground;
}

/// @nodoc
class _$PatientModelCopyWithImpl<$Res, $Val extends PatientModel>
    implements $PatientModelCopyWith<$Res> {
  _$PatientModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PatientModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? patientId = null,
    Object? userId = freezed,
    Object? name = null,
    Object? dob = null,
    Object? gender = null,
    Object? villageId = null,
    Object? mobile = freezed,
    Object? photoBase64 = freezed,
    Object? emergencyContact = null,
    Object? medicalBackground = null,
    Object? createdBy = null,
    Object? createdByOperatorId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            patientId: null == patientId
                ? _value.patientId
                : patientId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            dob: null == dob
                ? _value.dob
                : dob // ignore: cast_nullable_to_non_nullable
                      as String,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
            villageId: null == villageId
                ? _value.villageId
                : villageId // ignore: cast_nullable_to_non_nullable
                      as String,
            mobile: freezed == mobile
                ? _value.mobile
                : mobile // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoBase64: freezed == photoBase64
                ? _value.photoBase64
                : photoBase64 // ignore: cast_nullable_to_non_nullable
                      as String?,
            emergencyContact: null == emergencyContact
                ? _value.emergencyContact
                : emergencyContact // ignore: cast_nullable_to_non_nullable
                      as EmergencyContact,
            medicalBackground: null == medicalBackground
                ? _value.medicalBackground
                : medicalBackground // ignore: cast_nullable_to_non_nullable
                      as MedicalBackground,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdByOperatorId: freezed == createdByOperatorId
                ? _value.createdByOperatorId
                : createdByOperatorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of PatientModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EmergencyContactCopyWith<$Res> get emergencyContact {
    return $EmergencyContactCopyWith<$Res>(_value.emergencyContact, (value) {
      return _then(_value.copyWith(emergencyContact: value) as $Val);
    });
  }

  /// Create a copy of PatientModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MedicalBackgroundCopyWith<$Res> get medicalBackground {
    return $MedicalBackgroundCopyWith<$Res>(_value.medicalBackground, (value) {
      return _then(_value.copyWith(medicalBackground: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PatientModelImplCopyWith<$Res>
    implements $PatientModelCopyWith<$Res> {
  factory _$$PatientModelImplCopyWith(
    _$PatientModelImpl value,
    $Res Function(_$PatientModelImpl) then,
  ) = __$$PatientModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String patientId,
    String? userId,
    String name,
    String dob,
    String gender,
    String villageId,
    String? mobile,
    String? photoBase64,
    EmergencyContact emergencyContact,
    MedicalBackground medicalBackground,
    String createdBy,
    String? createdByOperatorId,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? createdAt,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? updatedAt,
  });

  @override
  $EmergencyContactCopyWith<$Res> get emergencyContact;
  @override
  $MedicalBackgroundCopyWith<$Res> get medicalBackground;
}

/// @nodoc
class __$$PatientModelImplCopyWithImpl<$Res>
    extends _$PatientModelCopyWithImpl<$Res, _$PatientModelImpl>
    implements _$$PatientModelImplCopyWith<$Res> {
  __$$PatientModelImplCopyWithImpl(
    _$PatientModelImpl _value,
    $Res Function(_$PatientModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PatientModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? patientId = null,
    Object? userId = freezed,
    Object? name = null,
    Object? dob = null,
    Object? gender = null,
    Object? villageId = null,
    Object? mobile = freezed,
    Object? photoBase64 = freezed,
    Object? emergencyContact = null,
    Object? medicalBackground = null,
    Object? createdBy = null,
    Object? createdByOperatorId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PatientModelImpl(
        patientId: null == patientId
            ? _value.patientId
            : patientId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        dob: null == dob
            ? _value.dob
            : dob // ignore: cast_nullable_to_non_nullable
                  as String,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
        villageId: null == villageId
            ? _value.villageId
            : villageId // ignore: cast_nullable_to_non_nullable
                  as String,
        mobile: freezed == mobile
            ? _value.mobile
            : mobile // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoBase64: freezed == photoBase64
            ? _value.photoBase64
            : photoBase64 // ignore: cast_nullable_to_non_nullable
                  as String?,
        emergencyContact: null == emergencyContact
            ? _value.emergencyContact
            : emergencyContact // ignore: cast_nullable_to_non_nullable
                  as EmergencyContact,
        medicalBackground: null == medicalBackground
            ? _value.medicalBackground
            : medicalBackground // ignore: cast_nullable_to_non_nullable
                  as MedicalBackground,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdByOperatorId: freezed == createdByOperatorId
            ? _value.createdByOperatorId
            : createdByOperatorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PatientModelImpl implements _PatientModel {
  const _$PatientModelImpl({
    required this.patientId,
    this.userId,
    required this.name,
    required this.dob,
    required this.gender,
    required this.villageId,
    this.mobile,
    this.photoBase64,
    this.emergencyContact = const EmergencyContact(),
    this.medicalBackground = const MedicalBackground(),
    this.createdBy = 'self',
    this.createdByOperatorId,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.createdAt,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.updatedAt,
  });

  factory _$PatientModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PatientModelImplFromJson(json);

  @override
  final String patientId;
  @override
  final String? userId;
  // null if operator-registered without phone
  @override
  final String name;
  @override
  final String dob;
  @override
  final String gender;
  @override
  final String villageId;
  @override
  final String? mobile;
  // nullable per SRS for non-phone patients
  @override
  final String? photoBase64;
  @override
  @JsonKey()
  final EmergencyContact emergencyContact;
  @override
  @JsonKey()
  final MedicalBackground medicalBackground;
  @override
  @JsonKey()
  final String createdBy;
  @override
  final String? createdByOperatorId;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? createdAt;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PatientModel(patientId: $patientId, userId: $userId, name: $name, dob: $dob, gender: $gender, villageId: $villageId, mobile: $mobile, photoBase64: $photoBase64, emergencyContact: $emergencyContact, medicalBackground: $medicalBackground, createdBy: $createdBy, createdByOperatorId: $createdByOperatorId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PatientModelImpl &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.dob, dob) || other.dob == dob) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.villageId, villageId) ||
                other.villageId == villageId) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.photoBase64, photoBase64) ||
                other.photoBase64 == photoBase64) &&
            (identical(other.emergencyContact, emergencyContact) ||
                other.emergencyContact == emergencyContact) &&
            (identical(other.medicalBackground, medicalBackground) ||
                other.medicalBackground == medicalBackground) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdByOperatorId, createdByOperatorId) ||
                other.createdByOperatorId == createdByOperatorId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    patientId,
    userId,
    name,
    dob,
    gender,
    villageId,
    mobile,
    photoBase64,
    emergencyContact,
    medicalBackground,
    createdBy,
    createdByOperatorId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PatientModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PatientModelImplCopyWith<_$PatientModelImpl> get copyWith =>
      __$$PatientModelImplCopyWithImpl<_$PatientModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PatientModelImplToJson(this);
  }
}

abstract class _PatientModel implements PatientModel {
  const factory _PatientModel({
    required final String patientId,
    final String? userId,
    required final String name,
    required final String dob,
    required final String gender,
    required final String villageId,
    final String? mobile,
    final String? photoBase64,
    final EmergencyContact emergencyContact,
    final MedicalBackground medicalBackground,
    final String createdBy,
    final String? createdByOperatorId,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? createdAt,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? updatedAt,
  }) = _$PatientModelImpl;

  factory _PatientModel.fromJson(Map<String, dynamic> json) =
      _$PatientModelImpl.fromJson;

  @override
  String get patientId;
  @override
  String? get userId; // null if operator-registered without phone
  @override
  String get name;
  @override
  String get dob;
  @override
  String get gender;
  @override
  String get villageId;
  @override
  String? get mobile; // nullable per SRS for non-phone patients
  @override
  String? get photoBase64;
  @override
  EmergencyContact get emergencyContact;
  @override
  MedicalBackground get medicalBackground;
  @override
  String get createdBy;
  @override
  String? get createdByOperatorId;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get createdAt;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get updatedAt;

  /// Create a copy of PatientModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PatientModelImplCopyWith<_$PatientModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) {
  return _EmergencyContact.fromJson(json);
}

/// @nodoc
mixin _$EmergencyContact {
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;

  /// Serializes this EmergencyContact to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmergencyContactCopyWith<EmergencyContact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmergencyContactCopyWith<$Res> {
  factory $EmergencyContactCopyWith(
    EmergencyContact value,
    $Res Function(EmergencyContact) then,
  ) = _$EmergencyContactCopyWithImpl<$Res, EmergencyContact>;
  @useResult
  $Res call({String name, String phone});
}

/// @nodoc
class _$EmergencyContactCopyWithImpl<$Res, $Val extends EmergencyContact>
    implements $EmergencyContactCopyWith<$Res> {
  _$EmergencyContactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? name = null, Object? phone = null}) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EmergencyContactImplCopyWith<$Res>
    implements $EmergencyContactCopyWith<$Res> {
  factory _$$EmergencyContactImplCopyWith(
    _$EmergencyContactImpl value,
    $Res Function(_$EmergencyContactImpl) then,
  ) = __$$EmergencyContactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String phone});
}

/// @nodoc
class __$$EmergencyContactImplCopyWithImpl<$Res>
    extends _$EmergencyContactCopyWithImpl<$Res, _$EmergencyContactImpl>
    implements _$$EmergencyContactImplCopyWith<$Res> {
  __$$EmergencyContactImplCopyWithImpl(
    _$EmergencyContactImpl _value,
    $Res Function(_$EmergencyContactImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? name = null, Object? phone = null}) {
    return _then(
      _$EmergencyContactImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EmergencyContactImpl implements _EmergencyContact {
  const _$EmergencyContactImpl({this.name = '', this.phone = ''});

  factory _$EmergencyContactImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmergencyContactImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String phone;

  @override
  String toString() {
    return 'EmergencyContact(name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmergencyContactImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, phone);

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmergencyContactImplCopyWith<_$EmergencyContactImpl> get copyWith =>
      __$$EmergencyContactImplCopyWithImpl<_$EmergencyContactImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EmergencyContactImplToJson(this);
  }
}

abstract class _EmergencyContact implements EmergencyContact {
  const factory _EmergencyContact({final String name, final String phone}) =
      _$EmergencyContactImpl;

  factory _EmergencyContact.fromJson(Map<String, dynamic> json) =
      _$EmergencyContactImpl.fromJson;

  @override
  String get name;
  @override
  String get phone;

  /// Create a copy of EmergencyContact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmergencyContactImplCopyWith<_$EmergencyContactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MedicalBackground _$MedicalBackgroundFromJson(Map<String, dynamic> json) {
  return _MedicalBackground.fromJson(json);
}

/// @nodoc
mixin _$MedicalBackground {
  List<String> get conditions => throw _privateConstructorUsedError;
  List<String> get medications => throw _privateConstructorUsedError;
  List<String> get allergies => throw _privateConstructorUsedError;

  /// Serializes this MedicalBackground to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MedicalBackground
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MedicalBackgroundCopyWith<MedicalBackground> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicalBackgroundCopyWith<$Res> {
  factory $MedicalBackgroundCopyWith(
    MedicalBackground value,
    $Res Function(MedicalBackground) then,
  ) = _$MedicalBackgroundCopyWithImpl<$Res, MedicalBackground>;
  @useResult
  $Res call({
    List<String> conditions,
    List<String> medications,
    List<String> allergies,
  });
}

/// @nodoc
class _$MedicalBackgroundCopyWithImpl<$Res, $Val extends MedicalBackground>
    implements $MedicalBackgroundCopyWith<$Res> {
  _$MedicalBackgroundCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MedicalBackground
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conditions = null,
    Object? medications = null,
    Object? allergies = null,
  }) {
    return _then(
      _value.copyWith(
            conditions: null == conditions
                ? _value.conditions
                : conditions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            medications: null == medications
                ? _value.medications
                : medications // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            allergies: null == allergies
                ? _value.allergies
                : allergies // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MedicalBackgroundImplCopyWith<$Res>
    implements $MedicalBackgroundCopyWith<$Res> {
  factory _$$MedicalBackgroundImplCopyWith(
    _$MedicalBackgroundImpl value,
    $Res Function(_$MedicalBackgroundImpl) then,
  ) = __$$MedicalBackgroundImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> conditions,
    List<String> medications,
    List<String> allergies,
  });
}

/// @nodoc
class __$$MedicalBackgroundImplCopyWithImpl<$Res>
    extends _$MedicalBackgroundCopyWithImpl<$Res, _$MedicalBackgroundImpl>
    implements _$$MedicalBackgroundImplCopyWith<$Res> {
  __$$MedicalBackgroundImplCopyWithImpl(
    _$MedicalBackgroundImpl _value,
    $Res Function(_$MedicalBackgroundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MedicalBackground
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conditions = null,
    Object? medications = null,
    Object? allergies = null,
  }) {
    return _then(
      _$MedicalBackgroundImpl(
        conditions: null == conditions
            ? _value._conditions
            : conditions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        medications: null == medications
            ? _value._medications
            : medications // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        allergies: null == allergies
            ? _value._allergies
            : allergies // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MedicalBackgroundImpl implements _MedicalBackground {
  const _$MedicalBackgroundImpl({
    final List<String> conditions = const [],
    final List<String> medications = const [],
    final List<String> allergies = const [],
  }) : _conditions = conditions,
       _medications = medications,
       _allergies = allergies;

  factory _$MedicalBackgroundImpl.fromJson(Map<String, dynamic> json) =>
      _$$MedicalBackgroundImplFromJson(json);

  final List<String> _conditions;
  @override
  @JsonKey()
  List<String> get conditions {
    if (_conditions is EqualUnmodifiableListView) return _conditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conditions);
  }

  final List<String> _medications;
  @override
  @JsonKey()
  List<String> get medications {
    if (_medications is EqualUnmodifiableListView) return _medications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_medications);
  }

  final List<String> _allergies;
  @override
  @JsonKey()
  List<String> get allergies {
    if (_allergies is EqualUnmodifiableListView) return _allergies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allergies);
  }

  @override
  String toString() {
    return 'MedicalBackground(conditions: $conditions, medications: $medications, allergies: $allergies)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicalBackgroundImpl &&
            const DeepCollectionEquality().equals(
              other._conditions,
              _conditions,
            ) &&
            const DeepCollectionEquality().equals(
              other._medications,
              _medications,
            ) &&
            const DeepCollectionEquality().equals(
              other._allergies,
              _allergies,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_conditions),
    const DeepCollectionEquality().hash(_medications),
    const DeepCollectionEquality().hash(_allergies),
  );

  /// Create a copy of MedicalBackground
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicalBackgroundImplCopyWith<_$MedicalBackgroundImpl> get copyWith =>
      __$$MedicalBackgroundImplCopyWithImpl<_$MedicalBackgroundImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MedicalBackgroundImplToJson(this);
  }
}

abstract class _MedicalBackground implements MedicalBackground {
  const factory _MedicalBackground({
    final List<String> conditions,
    final List<String> medications,
    final List<String> allergies,
  }) = _$MedicalBackgroundImpl;

  factory _MedicalBackground.fromJson(Map<String, dynamic> json) =
      _$MedicalBackgroundImpl.fromJson;

  @override
  List<String> get conditions;
  @override
  List<String> get medications;
  @override
  List<String> get allergies;

  /// Create a copy of MedicalBackground
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MedicalBackgroundImplCopyWith<_$MedicalBackgroundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
