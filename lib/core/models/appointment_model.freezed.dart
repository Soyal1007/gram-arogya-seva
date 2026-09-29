// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppointmentModel _$AppointmentModelFromJson(Map<String, dynamic> json) {
  return _AppointmentModel.fromJson(json);
}

/// @nodoc
mixin _$AppointmentModel {
  String get appointmentId => throw _privateConstructorUsedError;
  String get patientId => throw _privateConstructorUsedError;
  String? get patientUserId =>
      throw _privateConstructorUsedError; // denormalized for security rules
  String get patientName =>
      throw _privateConstructorUsedError; // denormalized for doctor display
  String get doctorId => throw _privateConstructorUsedError;
  String get doctorName =>
      throw _privateConstructorUsedError; // denormalized for patient display
  String get healthCenterId => throw _privateConstructorUsedError;
  String get villageId => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  String get timeSlot =>
      throw _privateConstructorUsedError; // Absolute instant of the slot, computed server-side from date + timeSlot
  // in Asia/Kolkata. String date/time cannot be ordered or compared, which
  // is what made the cancellation window unenforceable (Assessment A17-2).
  // Nullable: documents written before this field existed do not carry it.
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get slotStartAt => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String? get createdByOperatorId => throw _privateConstructorUsedError;
  String? get prepInstructions => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get cancelledAt => throw _privateConstructorUsedError;
  String? get cancelledBy => throw _privateConstructorUsedError;
  IntakeForm get intakeForm => throw _privateConstructorUsedError;
  VisitSummary? get visitSummary => throw _privateConstructorUsedError;
  bool get reminderSent => throw _privateConstructorUsedError;
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

  /// Serializes this AppointmentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppointmentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppointmentModelCopyWith<AppointmentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppointmentModelCopyWith<$Res> {
  factory $AppointmentModelCopyWith(
    AppointmentModel value,
    $Res Function(AppointmentModel) then,
  ) = _$AppointmentModelCopyWithImpl<$Res, AppointmentModel>;
  @useResult
  $Res call({
    String appointmentId,
    String patientId,
    String? patientUserId,
    String patientName,
    String doctorId,
    String doctorName,
    String healthCenterId,
    String villageId,
    String date,
    String timeSlot,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? slotStartAt,
    String reason,
    String status,
    String createdBy,
    String? createdByOperatorId,
    String? prepInstructions,
    String? rejectionReason,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? cancelledAt,
    String? cancelledBy,
    IntakeForm intakeForm,
    VisitSummary? visitSummary,
    bool reminderSent,
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

  $IntakeFormCopyWith<$Res> get intakeForm;
  $VisitSummaryCopyWith<$Res>? get visitSummary;
}

/// @nodoc
class _$AppointmentModelCopyWithImpl<$Res, $Val extends AppointmentModel>
    implements $AppointmentModelCopyWith<$Res> {
  _$AppointmentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppointmentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appointmentId = null,
    Object? patientId = null,
    Object? patientUserId = freezed,
    Object? patientName = null,
    Object? doctorId = null,
    Object? doctorName = null,
    Object? healthCenterId = null,
    Object? villageId = null,
    Object? date = null,
    Object? timeSlot = null,
    Object? slotStartAt = freezed,
    Object? reason = null,
    Object? status = null,
    Object? createdBy = null,
    Object? createdByOperatorId = freezed,
    Object? prepInstructions = freezed,
    Object? rejectionReason = freezed,
    Object? cancelledAt = freezed,
    Object? cancelledBy = freezed,
    Object? intakeForm = null,
    Object? visitSummary = freezed,
    Object? reminderSent = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            appointmentId: null == appointmentId
                ? _value.appointmentId
                : appointmentId // ignore: cast_nullable_to_non_nullable
                      as String,
            patientId: null == patientId
                ? _value.patientId
                : patientId // ignore: cast_nullable_to_non_nullable
                      as String,
            patientUserId: freezed == patientUserId
                ? _value.patientUserId
                : patientUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            patientName: null == patientName
                ? _value.patientName
                : patientName // ignore: cast_nullable_to_non_nullable
                      as String,
            doctorId: null == doctorId
                ? _value.doctorId
                : doctorId // ignore: cast_nullable_to_non_nullable
                      as String,
            doctorName: null == doctorName
                ? _value.doctorName
                : doctorName // ignore: cast_nullable_to_non_nullable
                      as String,
            healthCenterId: null == healthCenterId
                ? _value.healthCenterId
                : healthCenterId // ignore: cast_nullable_to_non_nullable
                      as String,
            villageId: null == villageId
                ? _value.villageId
                : villageId // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            timeSlot: null == timeSlot
                ? _value.timeSlot
                : timeSlot // ignore: cast_nullable_to_non_nullable
                      as String,
            slotStartAt: freezed == slotStartAt
                ? _value.slotStartAt
                : slotStartAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdByOperatorId: freezed == createdByOperatorId
                ? _value.createdByOperatorId
                : createdByOperatorId // ignore: cast_nullable_to_non_nullable
                      as String?,
            prepInstructions: freezed == prepInstructions
                ? _value.prepInstructions
                : prepInstructions // ignore: cast_nullable_to_non_nullable
                      as String?,
            rejectionReason: freezed == rejectionReason
                ? _value.rejectionReason
                : rejectionReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            cancelledAt: freezed == cancelledAt
                ? _value.cancelledAt
                : cancelledAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cancelledBy: freezed == cancelledBy
                ? _value.cancelledBy
                : cancelledBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            intakeForm: null == intakeForm
                ? _value.intakeForm
                : intakeForm // ignore: cast_nullable_to_non_nullable
                      as IntakeForm,
            visitSummary: freezed == visitSummary
                ? _value.visitSummary
                : visitSummary // ignore: cast_nullable_to_non_nullable
                      as VisitSummary?,
            reminderSent: null == reminderSent
                ? _value.reminderSent
                : reminderSent // ignore: cast_nullable_to_non_nullable
                      as bool,
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

  /// Create a copy of AppointmentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IntakeFormCopyWith<$Res> get intakeForm {
    return $IntakeFormCopyWith<$Res>(_value.intakeForm, (value) {
      return _then(_value.copyWith(intakeForm: value) as $Val);
    });
  }

  /// Create a copy of AppointmentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisitSummaryCopyWith<$Res>? get visitSummary {
    if (_value.visitSummary == null) {
      return null;
    }

    return $VisitSummaryCopyWith<$Res>(_value.visitSummary!, (value) {
      return _then(_value.copyWith(visitSummary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppointmentModelImplCopyWith<$Res>
    implements $AppointmentModelCopyWith<$Res> {
  factory _$$AppointmentModelImplCopyWith(
    _$AppointmentModelImpl value,
    $Res Function(_$AppointmentModelImpl) then,
  ) = __$$AppointmentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String appointmentId,
    String patientId,
    String? patientUserId,
    String patientName,
    String doctorId,
    String doctorName,
    String healthCenterId,
    String villageId,
    String date,
    String timeSlot,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? slotStartAt,
    String reason,
    String status,
    String createdBy,
    String? createdByOperatorId,
    String? prepInstructions,
    String? rejectionReason,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    DateTime? cancelledAt,
    String? cancelledBy,
    IntakeForm intakeForm,
    VisitSummary? visitSummary,
    bool reminderSent,
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
  $IntakeFormCopyWith<$Res> get intakeForm;
  @override
  $VisitSummaryCopyWith<$Res>? get visitSummary;
}

/// @nodoc
class __$$AppointmentModelImplCopyWithImpl<$Res>
    extends _$AppointmentModelCopyWithImpl<$Res, _$AppointmentModelImpl>
    implements _$$AppointmentModelImplCopyWith<$Res> {
  __$$AppointmentModelImplCopyWithImpl(
    _$AppointmentModelImpl _value,
    $Res Function(_$AppointmentModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppointmentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? appointmentId = null,
    Object? patientId = null,
    Object? patientUserId = freezed,
    Object? patientName = null,
    Object? doctorId = null,
    Object? doctorName = null,
    Object? healthCenterId = null,
    Object? villageId = null,
    Object? date = null,
    Object? timeSlot = null,
    Object? slotStartAt = freezed,
    Object? reason = null,
    Object? status = null,
    Object? createdBy = null,
    Object? createdByOperatorId = freezed,
    Object? prepInstructions = freezed,
    Object? rejectionReason = freezed,
    Object? cancelledAt = freezed,
    Object? cancelledBy = freezed,
    Object? intakeForm = null,
    Object? visitSummary = freezed,
    Object? reminderSent = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$AppointmentModelImpl(
        appointmentId: null == appointmentId
            ? _value.appointmentId
            : appointmentId // ignore: cast_nullable_to_non_nullable
                  as String,
        patientId: null == patientId
            ? _value.patientId
            : patientId // ignore: cast_nullable_to_non_nullable
                  as String,
        patientUserId: freezed == patientUserId
            ? _value.patientUserId
            : patientUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        patientName: null == patientName
            ? _value.patientName
            : patientName // ignore: cast_nullable_to_non_nullable
                  as String,
        doctorId: null == doctorId
            ? _value.doctorId
            : doctorId // ignore: cast_nullable_to_non_nullable
                  as String,
        doctorName: null == doctorName
            ? _value.doctorName
            : doctorName // ignore: cast_nullable_to_non_nullable
                  as String,
        healthCenterId: null == healthCenterId
            ? _value.healthCenterId
            : healthCenterId // ignore: cast_nullable_to_non_nullable
                  as String,
        villageId: null == villageId
            ? _value.villageId
            : villageId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        timeSlot: null == timeSlot
            ? _value.timeSlot
            : timeSlot // ignore: cast_nullable_to_non_nullable
                  as String,
        slotStartAt: freezed == slotStartAt
            ? _value.slotStartAt
            : slotStartAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdByOperatorId: freezed == createdByOperatorId
            ? _value.createdByOperatorId
            : createdByOperatorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        prepInstructions: freezed == prepInstructions
            ? _value.prepInstructions
            : prepInstructions // ignore: cast_nullable_to_non_nullable
                  as String?,
        rejectionReason: freezed == rejectionReason
            ? _value.rejectionReason
            : rejectionReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        cancelledAt: freezed == cancelledAt
            ? _value.cancelledAt
            : cancelledAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cancelledBy: freezed == cancelledBy
            ? _value.cancelledBy
            : cancelledBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        intakeForm: null == intakeForm
            ? _value.intakeForm
            : intakeForm // ignore: cast_nullable_to_non_nullable
                  as IntakeForm,
        visitSummary: freezed == visitSummary
            ? _value.visitSummary
            : visitSummary // ignore: cast_nullable_to_non_nullable
                  as VisitSummary?,
        reminderSent: null == reminderSent
            ? _value.reminderSent
            : reminderSent // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$AppointmentModelImpl implements _AppointmentModel {
  const _$AppointmentModelImpl({
    required this.appointmentId,
    required this.patientId,
    this.patientUserId,
    this.patientName = '',
    required this.doctorId,
    this.doctorName = '',
    required this.healthCenterId,
    required this.villageId,
    required this.date,
    required this.timeSlot,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.slotStartAt,
    required this.reason,
    this.status = 'pending',
    this.createdBy = 'self',
    this.createdByOperatorId,
    this.prepInstructions,
    this.rejectionReason,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    this.cancelledAt,
    this.cancelledBy,
    this.intakeForm = const IntakeForm(),
    this.visitSummary,
    this.reminderSent = false,
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

  factory _$AppointmentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppointmentModelImplFromJson(json);

  @override
  final String appointmentId;
  @override
  final String patientId;
  @override
  final String? patientUserId;
  // denormalized for security rules
  @override
  @JsonKey()
  final String patientName;
  // denormalized for doctor display
  @override
  final String doctorId;
  @override
  @JsonKey()
  final String doctorName;
  // denormalized for patient display
  @override
  final String healthCenterId;
  @override
  final String villageId;
  @override
  final String date;
  @override
  final String timeSlot;
  // Absolute instant of the slot, computed server-side from date + timeSlot
  // in Asia/Kolkata. String date/time cannot be ordered or compared, which
  // is what made the cancellation window unenforceable (Assessment A17-2).
  // Nullable: documents written before this field existed do not carry it.
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? slotStartAt;
  @override
  final String reason;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String createdBy;
  @override
  final String? createdByOperatorId;
  @override
  final String? prepInstructions;
  @override
  final String? rejectionReason;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  final DateTime? cancelledAt;
  @override
  final String? cancelledBy;
  @override
  @JsonKey()
  final IntakeForm intakeForm;
  @override
  final VisitSummary? visitSummary;
  @override
  @JsonKey()
  final bool reminderSent;
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
    return 'AppointmentModel(appointmentId: $appointmentId, patientId: $patientId, patientUserId: $patientUserId, patientName: $patientName, doctorId: $doctorId, doctorName: $doctorName, healthCenterId: $healthCenterId, villageId: $villageId, date: $date, timeSlot: $timeSlot, slotStartAt: $slotStartAt, reason: $reason, status: $status, createdBy: $createdBy, createdByOperatorId: $createdByOperatorId, prepInstructions: $prepInstructions, rejectionReason: $rejectionReason, cancelledAt: $cancelledAt, cancelledBy: $cancelledBy, intakeForm: $intakeForm, visitSummary: $visitSummary, reminderSent: $reminderSent, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppointmentModelImpl &&
            (identical(other.appointmentId, appointmentId) ||
                other.appointmentId == appointmentId) &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.patientUserId, patientUserId) ||
                other.patientUserId == patientUserId) &&
            (identical(other.patientName, patientName) ||
                other.patientName == patientName) &&
            (identical(other.doctorId, doctorId) ||
                other.doctorId == doctorId) &&
            (identical(other.doctorName, doctorName) ||
                other.doctorName == doctorName) &&
            (identical(other.healthCenterId, healthCenterId) ||
                other.healthCenterId == healthCenterId) &&
            (identical(other.villageId, villageId) ||
                other.villageId == villageId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.timeSlot, timeSlot) ||
                other.timeSlot == timeSlot) &&
            (identical(other.slotStartAt, slotStartAt) ||
                other.slotStartAt == slotStartAt) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdByOperatorId, createdByOperatorId) ||
                other.createdByOperatorId == createdByOperatorId) &&
            (identical(other.prepInstructions, prepInstructions) ||
                other.prepInstructions == prepInstructions) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
            (identical(other.cancelledBy, cancelledBy) ||
                other.cancelledBy == cancelledBy) &&
            (identical(other.intakeForm, intakeForm) ||
                other.intakeForm == intakeForm) &&
            (identical(other.visitSummary, visitSummary) ||
                other.visitSummary == visitSummary) &&
            (identical(other.reminderSent, reminderSent) ||
                other.reminderSent == reminderSent) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    appointmentId,
    patientId,
    patientUserId,
    patientName,
    doctorId,
    doctorName,
    healthCenterId,
    villageId,
    date,
    timeSlot,
    slotStartAt,
    reason,
    status,
    createdBy,
    createdByOperatorId,
    prepInstructions,
    rejectionReason,
    cancelledAt,
    cancelledBy,
    intakeForm,
    visitSummary,
    reminderSent,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of AppointmentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppointmentModelImplCopyWith<_$AppointmentModelImpl> get copyWith =>
      __$$AppointmentModelImplCopyWithImpl<_$AppointmentModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppointmentModelImplToJson(this);
  }
}

abstract class _AppointmentModel implements AppointmentModel {
  const factory _AppointmentModel({
    required final String appointmentId,
    required final String patientId,
    final String? patientUserId,
    final String patientName,
    required final String doctorId,
    final String doctorName,
    required final String healthCenterId,
    required final String villageId,
    required final String date,
    required final String timeSlot,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? slotStartAt,
    required final String reason,
    final String status,
    final String createdBy,
    final String? createdByOperatorId,
    final String? prepInstructions,
    final String? rejectionReason,
    @JsonKey(
      fromJson: TimestampConverter.fromJson,
      toJson: TimestampConverter.toJson,
    )
    final DateTime? cancelledAt,
    final String? cancelledBy,
    final IntakeForm intakeForm,
    final VisitSummary? visitSummary,
    final bool reminderSent,
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
  }) = _$AppointmentModelImpl;

  factory _AppointmentModel.fromJson(Map<String, dynamic> json) =
      _$AppointmentModelImpl.fromJson;

  @override
  String get appointmentId;
  @override
  String get patientId;
  @override
  String? get patientUserId; // denormalized for security rules
  @override
  String get patientName; // denormalized for doctor display
  @override
  String get doctorId;
  @override
  String get doctorName; // denormalized for patient display
  @override
  String get healthCenterId;
  @override
  String get villageId;
  @override
  String get date;
  @override
  String get timeSlot; // Absolute instant of the slot, computed server-side from date + timeSlot
  // in Asia/Kolkata. String date/time cannot be ordered or compared, which
  // is what made the cancellation window unenforceable (Assessment A17-2).
  // Nullable: documents written before this field existed do not carry it.
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get slotStartAt;
  @override
  String get reason;
  @override
  String get status;
  @override
  String get createdBy;
  @override
  String? get createdByOperatorId;
  @override
  String? get prepInstructions;
  @override
  String? get rejectionReason;
  @override
  @JsonKey(
    fromJson: TimestampConverter.fromJson,
    toJson: TimestampConverter.toJson,
  )
  DateTime? get cancelledAt;
  @override
  String? get cancelledBy;
  @override
  IntakeForm get intakeForm;
  @override
  VisitSummary? get visitSummary;
  @override
  bool get reminderSent;
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

  /// Create a copy of AppointmentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppointmentModelImplCopyWith<_$AppointmentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IntakeForm _$IntakeFormFromJson(Map<String, dynamic> json) {
  return _IntakeForm.fromJson(json);
}

/// @nodoc
mixin _$IntakeForm {
  String get symptoms => throw _privateConstructorUsedError;
  String get duration => throw _privateConstructorUsedError;
  String get severity => throw _privateConstructorUsedError;

  /// Serializes this IntakeForm to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IntakeForm
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IntakeFormCopyWith<IntakeForm> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IntakeFormCopyWith<$Res> {
  factory $IntakeFormCopyWith(
    IntakeForm value,
    $Res Function(IntakeForm) then,
  ) = _$IntakeFormCopyWithImpl<$Res, IntakeForm>;
  @useResult
  $Res call({String symptoms, String duration, String severity});
}

/// @nodoc
class _$IntakeFormCopyWithImpl<$Res, $Val extends IntakeForm>
    implements $IntakeFormCopyWith<$Res> {
  _$IntakeFormCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IntakeForm
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symptoms = null,
    Object? duration = null,
    Object? severity = null,
  }) {
    return _then(
      _value.copyWith(
            symptoms: null == symptoms
                ? _value.symptoms
                : symptoms // ignore: cast_nullable_to_non_nullable
                      as String,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as String,
            severity: null == severity
                ? _value.severity
                : severity // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IntakeFormImplCopyWith<$Res>
    implements $IntakeFormCopyWith<$Res> {
  factory _$$IntakeFormImplCopyWith(
    _$IntakeFormImpl value,
    $Res Function(_$IntakeFormImpl) then,
  ) = __$$IntakeFormImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String symptoms, String duration, String severity});
}

/// @nodoc
class __$$IntakeFormImplCopyWithImpl<$Res>
    extends _$IntakeFormCopyWithImpl<$Res, _$IntakeFormImpl>
    implements _$$IntakeFormImplCopyWith<$Res> {
  __$$IntakeFormImplCopyWithImpl(
    _$IntakeFormImpl _value,
    $Res Function(_$IntakeFormImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IntakeForm
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symptoms = null,
    Object? duration = null,
    Object? severity = null,
  }) {
    return _then(
      _$IntakeFormImpl(
        symptoms: null == symptoms
            ? _value.symptoms
            : symptoms // ignore: cast_nullable_to_non_nullable
                  as String,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as String,
        severity: null == severity
            ? _value.severity
            : severity // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IntakeFormImpl implements _IntakeForm {
  const _$IntakeFormImpl({
    this.symptoms = '',
    this.duration = '',
    this.severity = '',
  });

  factory _$IntakeFormImpl.fromJson(Map<String, dynamic> json) =>
      _$$IntakeFormImplFromJson(json);

  @override
  @JsonKey()
  final String symptoms;
  @override
  @JsonKey()
  final String duration;
  @override
  @JsonKey()
  final String severity;

  @override
  String toString() {
    return 'IntakeForm(symptoms: $symptoms, duration: $duration, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IntakeFormImpl &&
            (identical(other.symptoms, symptoms) ||
                other.symptoms == symptoms) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, symptoms, duration, severity);

  /// Create a copy of IntakeForm
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IntakeFormImplCopyWith<_$IntakeFormImpl> get copyWith =>
      __$$IntakeFormImplCopyWithImpl<_$IntakeFormImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IntakeFormImplToJson(this);
  }
}

abstract class _IntakeForm implements IntakeForm {
  const factory _IntakeForm({
    final String symptoms,
    final String duration,
    final String severity,
  }) = _$IntakeFormImpl;

  factory _IntakeForm.fromJson(Map<String, dynamic> json) =
      _$IntakeFormImpl.fromJson;

  @override
  String get symptoms;
  @override
  String get duration;
  @override
  String get severity;

  /// Create a copy of IntakeForm
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IntakeFormImplCopyWith<_$IntakeFormImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VisitSummary _$VisitSummaryFromJson(Map<String, dynamic> json) {
  return _VisitSummary.fromJson(json);
}

/// @nodoc
mixin _$VisitSummary {
  String get notes => throw _privateConstructorUsedError;
  String get prescription => throw _privateConstructorUsedError;
  String get nextSteps => throw _privateConstructorUsedError;
  String? get followUpDate => throw _privateConstructorUsedError;

  /// Serializes this VisitSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisitSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisitSummaryCopyWith<VisitSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisitSummaryCopyWith<$Res> {
  factory $VisitSummaryCopyWith(
    VisitSummary value,
    $Res Function(VisitSummary) then,
  ) = _$VisitSummaryCopyWithImpl<$Res, VisitSummary>;
  @useResult
  $Res call({
    String notes,
    String prescription,
    String nextSteps,
    String? followUpDate,
  });
}

/// @nodoc
class _$VisitSummaryCopyWithImpl<$Res, $Val extends VisitSummary>
    implements $VisitSummaryCopyWith<$Res> {
  _$VisitSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisitSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notes = null,
    Object? prescription = null,
    Object? nextSteps = null,
    Object? followUpDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String,
            prescription: null == prescription
                ? _value.prescription
                : prescription // ignore: cast_nullable_to_non_nullable
                      as String,
            nextSteps: null == nextSteps
                ? _value.nextSteps
                : nextSteps // ignore: cast_nullable_to_non_nullable
                      as String,
            followUpDate: freezed == followUpDate
                ? _value.followUpDate
                : followUpDate // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VisitSummaryImplCopyWith<$Res>
    implements $VisitSummaryCopyWith<$Res> {
  factory _$$VisitSummaryImplCopyWith(
    _$VisitSummaryImpl value,
    $Res Function(_$VisitSummaryImpl) then,
  ) = __$$VisitSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String notes,
    String prescription,
    String nextSteps,
    String? followUpDate,
  });
}

/// @nodoc
class __$$VisitSummaryImplCopyWithImpl<$Res>
    extends _$VisitSummaryCopyWithImpl<$Res, _$VisitSummaryImpl>
    implements _$$VisitSummaryImplCopyWith<$Res> {
  __$$VisitSummaryImplCopyWithImpl(
    _$VisitSummaryImpl _value,
    $Res Function(_$VisitSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VisitSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notes = null,
    Object? prescription = null,
    Object? nextSteps = null,
    Object? followUpDate = freezed,
  }) {
    return _then(
      _$VisitSummaryImpl(
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
        prescription: null == prescription
            ? _value.prescription
            : prescription // ignore: cast_nullable_to_non_nullable
                  as String,
        nextSteps: null == nextSteps
            ? _value.nextSteps
            : nextSteps // ignore: cast_nullable_to_non_nullable
                  as String,
        followUpDate: freezed == followUpDate
            ? _value.followUpDate
            : followUpDate // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VisitSummaryImpl implements _VisitSummary {
  const _$VisitSummaryImpl({
    this.notes = '',
    this.prescription = '',
    this.nextSteps = '',
    this.followUpDate,
  });

  factory _$VisitSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisitSummaryImplFromJson(json);

  @override
  @JsonKey()
  final String notes;
  @override
  @JsonKey()
  final String prescription;
  @override
  @JsonKey()
  final String nextSteps;
  @override
  final String? followUpDate;

  @override
  String toString() {
    return 'VisitSummary(notes: $notes, prescription: $prescription, nextSteps: $nextSteps, followUpDate: $followUpDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisitSummaryImpl &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.prescription, prescription) ||
                other.prescription == prescription) &&
            (identical(other.nextSteps, nextSteps) ||
                other.nextSteps == nextSteps) &&
            (identical(other.followUpDate, followUpDate) ||
                other.followUpDate == followUpDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, notes, prescription, nextSteps, followUpDate);

  /// Create a copy of VisitSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisitSummaryImplCopyWith<_$VisitSummaryImpl> get copyWith =>
      __$$VisitSummaryImplCopyWithImpl<_$VisitSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisitSummaryImplToJson(this);
  }
}

abstract class _VisitSummary implements VisitSummary {
  const factory _VisitSummary({
    final String notes,
    final String prescription,
    final String nextSteps,
    final String? followUpDate,
  }) = _$VisitSummaryImpl;

  factory _VisitSummary.fromJson(Map<String, dynamic> json) =
      _$VisitSummaryImpl.fromJson;

  @override
  String get notes;
  @override
  String get prescription;
  @override
  String get nextSteps;
  @override
  String? get followUpDate;

  /// Create a copy of VisitSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisitSummaryImplCopyWith<_$VisitSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
