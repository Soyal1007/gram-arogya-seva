// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'availability_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AvailabilityModel _$AvailabilityModelFromJson(Map<String, dynamic> json) {
  return _AvailabilityModel.fromJson(json);
}

/// @nodoc
mixin _$AvailabilityModel {
  String get doctorId => throw _privateConstructorUsedError;
  String get healthCenterId => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  List<SlotModel> get slots => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String? get lastUpdatedBy => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this AvailabilityModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AvailabilityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AvailabilityModelCopyWith<AvailabilityModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AvailabilityModelCopyWith<$Res> {
  factory $AvailabilityModelCopyWith(
    AvailabilityModel value,
    $Res Function(AvailabilityModel) then,
  ) = _$AvailabilityModelCopyWithImpl<$Res, AvailabilityModel>;
  @useResult
  $Res call({
    String doctorId,
    String healthCenterId,
    String date,
    List<SlotModel> slots,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? createdAt,
    String? lastUpdatedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$AvailabilityModelCopyWithImpl<$Res, $Val extends AvailabilityModel>
    implements $AvailabilityModelCopyWith<$Res> {
  _$AvailabilityModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AvailabilityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? doctorId = null,
    Object? healthCenterId = null,
    Object? date = null,
    Object? slots = null,
    Object? createdAt = freezed,
    Object? lastUpdatedBy = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            doctorId: null == doctorId
                ? _value.doctorId
                : doctorId // ignore: cast_nullable_to_non_nullable
                      as String,
            healthCenterId: null == healthCenterId
                ? _value.healthCenterId
                : healthCenterId // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            slots: null == slots
                ? _value.slots
                : slots // ignore: cast_nullable_to_non_nullable
                      as List<SlotModel>,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastUpdatedBy: freezed == lastUpdatedBy
                ? _value.lastUpdatedBy
                : lastUpdatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AvailabilityModelImplCopyWith<$Res>
    implements $AvailabilityModelCopyWith<$Res> {
  factory _$$AvailabilityModelImplCopyWith(
    _$AvailabilityModelImpl value,
    $Res Function(_$AvailabilityModelImpl) then,
  ) = __$$AvailabilityModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String doctorId,
    String healthCenterId,
    String date,
    List<SlotModel> slots,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? createdAt,
    String? lastUpdatedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$AvailabilityModelImplCopyWithImpl<$Res>
    extends _$AvailabilityModelCopyWithImpl<$Res, _$AvailabilityModelImpl>
    implements _$$AvailabilityModelImplCopyWith<$Res> {
  __$$AvailabilityModelImplCopyWithImpl(
    _$AvailabilityModelImpl _value,
    $Res Function(_$AvailabilityModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AvailabilityModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? doctorId = null,
    Object? healthCenterId = null,
    Object? date = null,
    Object? slots = null,
    Object? createdAt = freezed,
    Object? lastUpdatedBy = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$AvailabilityModelImpl(
        doctorId: null == doctorId
            ? _value.doctorId
            : doctorId // ignore: cast_nullable_to_non_nullable
                  as String,
        healthCenterId: null == healthCenterId
            ? _value.healthCenterId
            : healthCenterId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        slots: null == slots
            ? _value._slots
            : slots // ignore: cast_nullable_to_non_nullable
                  as List<SlotModel>,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastUpdatedBy: freezed == lastUpdatedBy
            ? _value.lastUpdatedBy
            : lastUpdatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$AvailabilityModelImpl implements _AvailabilityModel {
  const _$AvailabilityModelImpl({
    required this.doctorId,
    required this.healthCenterId,
    required this.date,
    final List<SlotModel> slots = const [],
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.createdAt,
    this.lastUpdatedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.updatedAt,
  }) : _slots = slots;

  factory _$AvailabilityModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AvailabilityModelImplFromJson(json);

  @override
  final String doctorId;
  @override
  final String healthCenterId;
  @override
  final String date;
  final List<SlotModel> _slots;
  @override
  @JsonKey()
  List<SlotModel> get slots {
    if (_slots is EqualUnmodifiableListView) return _slots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_slots);
  }

  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? createdAt;
  @override
  final String? lastUpdatedBy;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'AvailabilityModel(doctorId: $doctorId, healthCenterId: $healthCenterId, date: $date, slots: $slots, createdAt: $createdAt, lastUpdatedBy: $lastUpdatedBy, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AvailabilityModelImpl &&
            (identical(other.doctorId, doctorId) ||
                other.doctorId == doctorId) &&
            (identical(other.healthCenterId, healthCenterId) ||
                other.healthCenterId == healthCenterId) &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality().equals(other._slots, _slots) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastUpdatedBy, lastUpdatedBy) ||
                other.lastUpdatedBy == lastUpdatedBy) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    doctorId,
    healthCenterId,
    date,
    const DeepCollectionEquality().hash(_slots),
    createdAt,
    lastUpdatedBy,
    updatedAt,
  );

  /// Create a copy of AvailabilityModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AvailabilityModelImplCopyWith<_$AvailabilityModelImpl> get copyWith =>
      __$$AvailabilityModelImplCopyWithImpl<_$AvailabilityModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AvailabilityModelImplToJson(this);
  }
}

abstract class _AvailabilityModel implements AvailabilityModel {
  const factory _AvailabilityModel({
    required final String doctorId,
    required final String healthCenterId,
    required final String date,
    final List<SlotModel> slots,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? createdAt,
    final String? lastUpdatedBy,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? updatedAt,
  }) = _$AvailabilityModelImpl;

  factory _AvailabilityModel.fromJson(Map<String, dynamic> json) =
      _$AvailabilityModelImpl.fromJson;

  @override
  String get doctorId;
  @override
  String get healthCenterId;
  @override
  String get date;
  @override
  List<SlotModel> get slots;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get createdAt;
  @override
  String? get lastUpdatedBy;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get updatedAt;

  /// Create a copy of AvailabilityModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AvailabilityModelImplCopyWith<_$AvailabilityModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SlotModel _$SlotModelFromJson(Map<String, dynamic> json) {
  return _SlotModel.fromJson(json);
}

/// @nodoc
mixin _$SlotModel {
  String get time => throw _privateConstructorUsedError;
  bool get isBooked => throw _privateConstructorUsedError;
  String? get appointmentId => throw _privateConstructorUsedError;

  /// Serializes this SlotModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SlotModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SlotModelCopyWith<SlotModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SlotModelCopyWith<$Res> {
  factory $SlotModelCopyWith(SlotModel value, $Res Function(SlotModel) then) =
      _$SlotModelCopyWithImpl<$Res, SlotModel>;
  @useResult
  $Res call({String time, bool isBooked, String? appointmentId});
}

/// @nodoc
class _$SlotModelCopyWithImpl<$Res, $Val extends SlotModel>
    implements $SlotModelCopyWith<$Res> {
  _$SlotModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SlotModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? isBooked = null,
    Object? appointmentId = freezed,
  }) {
    return _then(
      _value.copyWith(
            time: null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as String,
            isBooked: null == isBooked
                ? _value.isBooked
                : isBooked // ignore: cast_nullable_to_non_nullable
                      as bool,
            appointmentId: freezed == appointmentId
                ? _value.appointmentId
                : appointmentId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SlotModelImplCopyWith<$Res>
    implements $SlotModelCopyWith<$Res> {
  factory _$$SlotModelImplCopyWith(
    _$SlotModelImpl value,
    $Res Function(_$SlotModelImpl) then,
  ) = __$$SlotModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String time, bool isBooked, String? appointmentId});
}

/// @nodoc
class __$$SlotModelImplCopyWithImpl<$Res>
    extends _$SlotModelCopyWithImpl<$Res, _$SlotModelImpl>
    implements _$$SlotModelImplCopyWith<$Res> {
  __$$SlotModelImplCopyWithImpl(
    _$SlotModelImpl _value,
    $Res Function(_$SlotModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SlotModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? isBooked = null,
    Object? appointmentId = freezed,
  }) {
    return _then(
      _$SlotModelImpl(
        time: null == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as String,
        isBooked: null == isBooked
            ? _value.isBooked
            : isBooked // ignore: cast_nullable_to_non_nullable
                  as bool,
        appointmentId: freezed == appointmentId
            ? _value.appointmentId
            : appointmentId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SlotModelImpl implements _SlotModel {
  const _$SlotModelImpl({
    required this.time,
    this.isBooked = false,
    this.appointmentId,
  });

  factory _$SlotModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SlotModelImplFromJson(json);

  @override
  final String time;
  @override
  @JsonKey()
  final bool isBooked;
  @override
  final String? appointmentId;

  @override
  String toString() {
    return 'SlotModel(time: $time, isBooked: $isBooked, appointmentId: $appointmentId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SlotModelImpl &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.isBooked, isBooked) ||
                other.isBooked == isBooked) &&
            (identical(other.appointmentId, appointmentId) ||
                other.appointmentId == appointmentId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, time, isBooked, appointmentId);

  /// Create a copy of SlotModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SlotModelImplCopyWith<_$SlotModelImpl> get copyWith =>
      __$$SlotModelImplCopyWithImpl<_$SlotModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SlotModelImplToJson(this);
  }
}

abstract class _SlotModel implements SlotModel {
  const factory _SlotModel({
    required final String time,
    final bool isBooked,
    final String? appointmentId,
  }) = _$SlotModelImpl;

  factory _SlotModel.fromJson(Map<String, dynamic> json) =
      _$SlotModelImpl.fromJson;

  @override
  String get time;
  @override
  bool get isBooked;
  @override
  String? get appointmentId;

  /// Create a copy of SlotModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SlotModelImplCopyWith<_$SlotModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
