// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'village_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VillageModel _$VillageModelFromJson(Map<String, dynamic> json) {
  return _VillageModel.fromJson(json);
}

/// @nodoc
mixin _$VillageModel {
  String get villageId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get taluka => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
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

  /// Serializes this VillageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VillageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VillageModelCopyWith<VillageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VillageModelCopyWith<$Res> {
  factory $VillageModelCopyWith(
    VillageModel value,
    $Res Function(VillageModel) then,
  ) = _$VillageModelCopyWithImpl<$Res, VillageModel>;
  @useResult
  $Res call({
    String villageId,
    String name,
    String taluka,
    String district,
    String state,
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
class _$VillageModelCopyWithImpl<$Res, $Val extends VillageModel>
    implements $VillageModelCopyWith<$Res> {
  _$VillageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VillageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? villageId = null,
    Object? name = null,
    Object? taluka = null,
    Object? district = null,
    Object? state = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            villageId: null == villageId
                ? _value.villageId
                : villageId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            taluka: null == taluka
                ? _value.taluka
                : taluka // ignore: cast_nullable_to_non_nullable
                      as String,
            district: null == district
                ? _value.district
                : district // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
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
abstract class _$$VillageModelImplCopyWith<$Res>
    implements $VillageModelCopyWith<$Res> {
  factory _$$VillageModelImplCopyWith(
    _$VillageModelImpl value,
    $Res Function(_$VillageModelImpl) then,
  ) = __$$VillageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String villageId,
    String name,
    String taluka,
    String district,
    String state,
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
class __$$VillageModelImplCopyWithImpl<$Res>
    extends _$VillageModelCopyWithImpl<$Res, _$VillageModelImpl>
    implements _$$VillageModelImplCopyWith<$Res> {
  __$$VillageModelImplCopyWithImpl(
    _$VillageModelImpl _value,
    $Res Function(_$VillageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VillageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? villageId = null,
    Object? name = null,
    Object? taluka = null,
    Object? district = null,
    Object? state = null,
    Object? isActive = null,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
    Object? updatedAt = freezed,
    Object? updatedBy = freezed,
  }) {
    return _then(
      _$VillageModelImpl(
        villageId: null == villageId
            ? _value.villageId
            : villageId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        taluka: null == taluka
            ? _value.taluka
            : taluka // ignore: cast_nullable_to_non_nullable
                  as String,
        district: null == district
            ? _value.district
            : district // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
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
class _$VillageModelImpl implements _VillageModel {
  const _$VillageModelImpl({
    required this.villageId,
    required this.name,
    required this.taluka,
    required this.district,
    required this.state,
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

  factory _$VillageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VillageModelImplFromJson(json);

  @override
  final String villageId;
  @override
  final String name;
  @override
  final String taluka;
  @override
  final String district;
  @override
  final String state;
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
    return 'VillageModel(villageId: $villageId, name: $name, taluka: $taluka, district: $district, state: $state, isActive: $isActive, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VillageModelImpl &&
            (identical(other.villageId, villageId) ||
                other.villageId == villageId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.taluka, taluka) || other.taluka == taluka) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.state, state) || other.state == state) &&
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
    villageId,
    name,
    taluka,
    district,
    state,
    isActive,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
  );

  /// Create a copy of VillageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VillageModelImplCopyWith<_$VillageModelImpl> get copyWith =>
      __$$VillageModelImplCopyWithImpl<_$VillageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VillageModelImplToJson(this);
  }
}

abstract class _VillageModel implements VillageModel {
  const factory _VillageModel({
    required final String villageId,
    required final String name,
    required final String taluka,
    required final String district,
    required final String state,
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
  }) = _$VillageModelImpl;

  factory _VillageModel.fromJson(Map<String, dynamic> json) =
      _$VillageModelImpl.fromJson;

  @override
  String get villageId;
  @override
  String get name;
  @override
  String get taluka;
  @override
  String get district;
  @override
  String get state;
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

  /// Create a copy of VillageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VillageModelImplCopyWith<_$VillageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
