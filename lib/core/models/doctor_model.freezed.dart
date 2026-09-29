// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'doctor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DoctorModel _$DoctorModelFromJson(Map<String, dynamic> json) {
  return _DoctorModel.fromJson(json);
}

/// @nodoc
mixin _$DoctorModel {
  String get doctorId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get specialization => throw _privateConstructorUsedError;
  String get mobile => throw _privateConstructorUsedError;
  String get nmrId => throw _privateConstructorUsedError;
  String get hprId => throw _privateConstructorUsedError;
  String get aadhaarHash => throw _privateConstructorUsedError;
  String get aadhaarLastFour => throw _privateConstructorUsedError;
  String? get abdmTxnId => throw _privateConstructorUsedError;
  String? get photoBase64 => throw _privateConstructorUsedError;
  List<String> get villages => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get rejectionNote => throw _privateConstructorUsedError;
  String? get approvedBy => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get approvedAt => throw _privateConstructorUsedError;
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
  String? get updatedBy => throw _privateConstructorUsedError;

  /// Serializes this DoctorModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DoctorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DoctorModelCopyWith<DoctorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DoctorModelCopyWith<$Res> {
  factory $DoctorModelCopyWith(
    DoctorModel value,
    $Res Function(DoctorModel) then,
  ) = _$DoctorModelCopyWithImpl<$Res, DoctorModel>;
  @useResult
  $Res call({
    String doctorId,
    String name,
    String specialization,
    String mobile,
    String nmrId,
    String hprId,
    String aadhaarHash,
    String aadhaarLastFour,
    String? abdmTxnId,
    String? photoBase64,
    List<String> villages,
    String status,
    String? rejectionNote,
    String? approvedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? approvedAt,
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
    String? updatedBy,
  });
}

/// @nodoc
class _$DoctorModelCopyWithImpl<$Res, $Val extends DoctorModel>
    implements $DoctorModelCopyWith<$Res> {
  _$DoctorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DoctorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? doctorId = null,
    Object? name = null,
    Object? specialization = null,
    Object? mobile = null,
    Object? nmrId = null,
    Object? hprId = null,
    Object? aadhaarHash = null,
    Object? aadhaarLastFour = null,
    Object? abdmTxnId = freezed,
    Object? photoBase64 = freezed,
    Object? villages = null,
    Object? status = null,
    Object? rejectionNote = freezed,
    Object? approvedBy = freezed,
    Object? approvedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            doctorId: null == doctorId
                ? _value.doctorId
                : doctorId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            specialization: null == specialization
                ? _value.specialization
                : specialization // ignore: cast_nullable_to_non_nullable
                      as String,
            mobile: null == mobile
                ? _value.mobile
                : mobile // ignore: cast_nullable_to_non_nullable
                      as String,
            nmrId: null == nmrId
                ? _value.nmrId
                : nmrId // ignore: cast_nullable_to_non_nullable
                      as String,
            hprId: null == hprId
                ? _value.hprId
                : hprId // ignore: cast_nullable_to_non_nullable
                      as String,
            aadhaarHash: null == aadhaarHash
                ? _value.aadhaarHash
                : aadhaarHash // ignore: cast_nullable_to_non_nullable
                      as String,
            aadhaarLastFour: null == aadhaarLastFour
                ? _value.aadhaarLastFour
                : aadhaarLastFour // ignore: cast_nullable_to_non_nullable
                      as String,
            abdmTxnId: freezed == abdmTxnId
                ? _value.abdmTxnId
                : abdmTxnId // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoBase64: freezed == photoBase64
                ? _value.photoBase64
                : photoBase64 // ignore: cast_nullable_to_non_nullable
                      as String?,
            villages: null == villages
                ? _value.villages
                : villages // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            rejectionNote: freezed == rejectionNote
                ? _value.rejectionNote
                : rejectionNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            approvedBy: freezed == approvedBy
                ? _value.approvedBy
                : approvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            approvedAt: freezed == approvedAt
                ? _value.approvedAt
                : approvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedBy: freezed == updatedBy
                ? _value.updatedBy
                : updatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DoctorModelImplCopyWith<$Res>
    implements $DoctorModelCopyWith<$Res> {
  factory _$$DoctorModelImplCopyWith(
    _$DoctorModelImpl value,
    $Res Function(_$DoctorModelImpl) then,
  ) = __$$DoctorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String doctorId,
    String name,
    String specialization,
    String mobile,
    String nmrId,
    String hprId,
    String aadhaarHash,
    String aadhaarLastFour,
    String? abdmTxnId,
    String? photoBase64,
    List<String> villages,
    String status,
    String? rejectionNote,
    String? approvedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? approvedAt,
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
    String? updatedBy,
  });
}

/// @nodoc
class __$$DoctorModelImplCopyWithImpl<$Res>
    extends _$DoctorModelCopyWithImpl<$Res, _$DoctorModelImpl>
    implements _$$DoctorModelImplCopyWith<$Res> {
  __$$DoctorModelImplCopyWithImpl(
    _$DoctorModelImpl _value,
    $Res Function(_$DoctorModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DoctorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? doctorId = null,
    Object? name = null,
    Object? specialization = null,
    Object? mobile = null,
    Object? nmrId = null,
    Object? hprId = null,
    Object? aadhaarHash = null,
    Object? aadhaarLastFour = null,
    Object? abdmTxnId = freezed,
    Object? photoBase64 = freezed,
    Object? villages = null,
    Object? status = null,
    Object? rejectionNote = freezed,
    Object? approvedBy = freezed,
    Object? approvedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
  }) {
    return _then(
      _$DoctorModelImpl(
        doctorId: null == doctorId
            ? _value.doctorId
            : doctorId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        specialization: null == specialization
            ? _value.specialization
            : specialization // ignore: cast_nullable_to_non_nullable
                  as String,
        mobile: null == mobile
            ? _value.mobile
            : mobile // ignore: cast_nullable_to_non_nullable
                  as String,
        nmrId: null == nmrId
            ? _value.nmrId
            : nmrId // ignore: cast_nullable_to_non_nullable
                  as String,
        hprId: null == hprId
            ? _value.hprId
            : hprId // ignore: cast_nullable_to_non_nullable
                  as String,
        aadhaarHash: null == aadhaarHash
            ? _value.aadhaarHash
            : aadhaarHash // ignore: cast_nullable_to_non_nullable
                  as String,
        aadhaarLastFour: null == aadhaarLastFour
            ? _value.aadhaarLastFour
            : aadhaarLastFour // ignore: cast_nullable_to_non_nullable
                  as String,
        abdmTxnId: freezed == abdmTxnId
            ? _value.abdmTxnId
            : abdmTxnId // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoBase64: freezed == photoBase64
            ? _value.photoBase64
            : photoBase64 // ignore: cast_nullable_to_non_nullable
                  as String?,
        villages: null == villages
            ? _value._villages
            : villages // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        rejectionNote: freezed == rejectionNote
            ? _value.rejectionNote
            : rejectionNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        approvedBy: freezed == approvedBy
            ? _value.approvedBy
            : approvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        approvedAt: freezed == approvedAt
            ? _value.approvedAt
            : approvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedBy: freezed == updatedBy
            ? _value.updatedBy
            : updatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DoctorModelImpl implements _DoctorModel {
  const _$DoctorModelImpl({
    required this.doctorId,
    required this.name,
    required this.specialization,
    required this.mobile,
    required this.nmrId,
    required this.hprId,
    required this.aadhaarHash,
    required this.aadhaarLastFour,
    this.abdmTxnId,
    this.photoBase64,
    final List<String> villages = const [],
    this.status = 'pending_approval',
    this.rejectionNote,
    this.approvedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.approvedAt,
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
    this.updatedBy,
  }) : _villages = villages;

  factory _$DoctorModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DoctorModelImplFromJson(json);

  @override
  final String doctorId;
  @override
  final String name;
  @override
  final String specialization;
  @override
  final String mobile;
  @override
  final String nmrId;
  @override
  final String hprId;
  @override
  final String aadhaarHash;
  @override
  final String aadhaarLastFour;
  @override
  final String? abdmTxnId;
  @override
  final String? photoBase64;
  final List<String> _villages;
  @override
  @JsonKey()
  List<String> get villages {
    if (_villages is EqualUnmodifiableListView) return _villages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_villages);
  }

  @override
  @JsonKey()
  final String status;
  @override
  final String? rejectionNote;
  @override
  final String? approvedBy;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? approvedAt;
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
  final String? updatedBy;

  @override
  String toString() {
    return 'DoctorModel(doctorId: $doctorId, name: $name, specialization: $specialization, mobile: $mobile, nmrId: $nmrId, hprId: $hprId, aadhaarHash: $aadhaarHash, aadhaarLastFour: $aadhaarLastFour, abdmTxnId: $abdmTxnId, photoBase64: $photoBase64, villages: $villages, status: $status, rejectionNote: $rejectionNote, approvedBy: $approvedBy, approvedAt: $approvedAt, createdAt: $createdAt, updatedAt: $updatedAt, updatedBy: $updatedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DoctorModelImpl &&
            (identical(other.doctorId, doctorId) ||
                other.doctorId == doctorId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.specialization, specialization) ||
                other.specialization == specialization) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.nmrId, nmrId) || other.nmrId == nmrId) &&
            (identical(other.hprId, hprId) || other.hprId == hprId) &&
            (identical(other.aadhaarHash, aadhaarHash) ||
                other.aadhaarHash == aadhaarHash) &&
            (identical(other.aadhaarLastFour, aadhaarLastFour) ||
                other.aadhaarLastFour == aadhaarLastFour) &&
            (identical(other.abdmTxnId, abdmTxnId) ||
                other.abdmTxnId == abdmTxnId) &&
            (identical(other.photoBase64, photoBase64) ||
                other.photoBase64 == photoBase64) &&
            const DeepCollectionEquality().equals(other._villages, _villages) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.rejectionNote, rejectionNote) ||
                other.rejectionNote == rejectionNote) &&
            (identical(other.approvedBy, approvedBy) ||
                other.approvedBy == approvedBy) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    doctorId,
    name,
    specialization,
    mobile,
    nmrId,
    hprId,
    aadhaarHash,
    aadhaarLastFour,
    abdmTxnId,
    photoBase64,
    const DeepCollectionEquality().hash(_villages),
    status,
    rejectionNote,
    approvedBy,
    approvedAt,
    createdAt,
    updatedAt,
    updatedBy,
  );

  /// Create a copy of DoctorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DoctorModelImplCopyWith<_$DoctorModelImpl> get copyWith =>
      __$$DoctorModelImplCopyWithImpl<_$DoctorModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DoctorModelImplToJson(this);
  }
}

abstract class _DoctorModel implements DoctorModel {
  const factory _DoctorModel({
    required final String doctorId,
    required final String name,
    required final String specialization,
    required final String mobile,
    required final String nmrId,
    required final String hprId,
    required final String aadhaarHash,
    required final String aadhaarLastFour,
    final String? abdmTxnId,
    final String? photoBase64,
    final List<String> villages,
    final String status,
    final String? rejectionNote,
    final String? approvedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? approvedAt,
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
    final String? updatedBy,
  }) = _$DoctorModelImpl;

  factory _DoctorModel.fromJson(Map<String, dynamic> json) =
      _$DoctorModelImpl.fromJson;

  @override
  String get doctorId;
  @override
  String get name;
  @override
  String get specialization;
  @override
  String get mobile;
  @override
  String get nmrId;
  @override
  String get hprId;
  @override
  String get aadhaarHash;
  @override
  String get aadhaarLastFour;
  @override
  String? get abdmTxnId;
  @override
  String? get photoBase64;
  @override
  List<String> get villages;
  @override
  String get status;
  @override
  String? get rejectionNote;
  @override
  String? get approvedBy;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get approvedAt;
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
  @override
  String? get updatedBy;

  /// Create a copy of DoctorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DoctorModelImplCopyWith<_$DoctorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
