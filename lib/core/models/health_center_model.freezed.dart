// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_center_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HealthCenterModel _$HealthCenterModelFromJson(Map<String, dynamic> json) {
  return _HealthCenterModel.fromJson(json);
}

/// @nodoc
mixin _$HealthCenterModel {
  String get centerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get villageId => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get updatedBy => throw _privateConstructorUsedError;

  /// Serializes this HealthCenterModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthCenterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthCenterModelCopyWith<HealthCenterModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthCenterModelCopyWith<$Res> {
  factory $HealthCenterModelCopyWith(
    HealthCenterModel value,
    $Res Function(HealthCenterModel) then,
  ) = _$HealthCenterModelCopyWithImpl<$Res, HealthCenterModel>;
  @useResult
  $Res call({
    String centerId,
    String name,
    String villageId,
    String address,
    String phone,
    bool isActive,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? createdAt,
    String? createdBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? updatedAt,
    String? updatedBy,
  });
}

/// @nodoc
class _$HealthCenterModelCopyWithImpl<$Res, $Val extends HealthCenterModel>
    implements $HealthCenterModelCopyWith<$Res> {
  _$HealthCenterModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthCenterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? centerId = null,
    Object? name = null,
    Object? villageId = null,
    Object? address = null,
    Object? phone = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            centerId: null == centerId
                ? _value.centerId
                : centerId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            villageId: null == villageId
                ? _value.villageId
                : villageId // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: null == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$HealthCenterModelImplCopyWith<$Res>
    implements $HealthCenterModelCopyWith<$Res> {
  factory _$$HealthCenterModelImplCopyWith(
    _$HealthCenterModelImpl value,
    $Res Function(_$HealthCenterModelImpl) then,
  ) = __$$HealthCenterModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String centerId,
    String name,
    String villageId,
    String address,
    String phone,
    bool isActive,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? createdAt,
    String? createdBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? updatedAt,
    String? updatedBy,
  });
}

/// @nodoc
class __$$HealthCenterModelImplCopyWithImpl<$Res>
    extends _$HealthCenterModelCopyWithImpl<$Res, _$HealthCenterModelImpl>
    implements _$$HealthCenterModelImplCopyWith<$Res> {
  __$$HealthCenterModelImplCopyWithImpl(
    _$HealthCenterModelImpl _value,
    $Res Function(_$HealthCenterModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HealthCenterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? centerId = null,
    Object? name = null,
    Object? villageId = null,
    Object? address = null,
    Object? phone = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
  }) {
    return _then(
      _$HealthCenterModelImpl(
        centerId: null == centerId
            ? _value.centerId
            : centerId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        villageId: null == villageId
            ? _value.villageId
            : villageId // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: null == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$HealthCenterModelImpl implements _HealthCenterModel {
  const _$HealthCenterModelImpl({
    required this.centerId,
    required this.name,
    required this.villageId,
    this.address = '',
    this.phone = '',
    this.isActive = true,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.createdAt,
    this.createdBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.updatedAt,
    this.updatedBy,
  });

  factory _$HealthCenterModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthCenterModelImplFromJson(json);

  @override
  final String centerId;
  @override
  final String name;
  @override
  final String villageId;
  @override
  @JsonKey()
  final String address;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? createdAt;
  @override
  final String? createdBy;
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
    return 'HealthCenterModel(centerId: $centerId, name: $name, villageId: $villageId, address: $address, phone: $phone, isActive: $isActive, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthCenterModelImpl &&
            (identical(other.centerId, centerId) ||
                other.centerId == centerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.villageId, villageId) ||
                other.villageId == villageId) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    centerId,
    name,
    villageId,
    address,
    phone,
    isActive,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
  );

  /// Create a copy of HealthCenterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthCenterModelImplCopyWith<_$HealthCenterModelImpl> get copyWith =>
      __$$HealthCenterModelImplCopyWithImpl<_$HealthCenterModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthCenterModelImplToJson(this);
  }
}

abstract class _HealthCenterModel implements HealthCenterModel {
  const factory _HealthCenterModel({
    required final String centerId,
    required final String name,
    required final String villageId,
    final String address,
    final String phone,
    final bool isActive,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? createdAt,
    final String? createdBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? updatedAt,
    final String? updatedBy,
  }) = _$HealthCenterModelImpl;

  factory _HealthCenterModel.fromJson(Map<String, dynamic> json) =
      _$HealthCenterModelImpl.fromJson;

  @override
  String get centerId;
  @override
  String get name;
  @override
  String get villageId;
  @override
  String get address;
  @override
  String get phone;
  @override
  bool get isActive;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get createdAt;
  @override
  String? get createdBy;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get updatedAt;
  @override
  String? get updatedBy;

  /// Create a copy of HealthCenterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthCenterModelImplCopyWith<_$HealthCenterModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
