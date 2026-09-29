import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/core/models/patient_model.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';
import 'package:gram_aarogya_seva/core/models/availability_model.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/notification_model.dart';

/// Single data access layer. ONLY file in the project that imports
/// `cloud_firestore` (with `TimestampConverter`). SRS §6.2.
///
/// Scope note: this class owns **reads** and the single-document writes that
/// Firestore security rules can fully validate. Mutations that span documents
/// or decide authorisation — booking, cancellation, appointment status
/// transitions, doctor registration, availability — live in Cloud Functions
/// and are reached through [FunctionsService]. Security rules deny those
/// writes from the client, so re-adding them here would only produce
/// permission errors (TECHNICAL_ASSESSMENT.md §A17-1).
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Enables the offline cache (SRS DP-2).
  ///
  /// Lives here rather than in `main.dart` so that `cloud_firestore` stays
  /// confined to this file and `TimestampConverter` — the invariant that makes
  /// the data layer swappable and testable (SRS §6.2).
  static void configureOfflinePersistence() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ═══════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════

  /// Reads user document. Returns null if not found.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson({...doc.data()!, 'uid': uid});
  }

  /// Creates or updates the user document on login.
  ///
  /// `createdAt` is only written when the document is new. Stamping it on
  /// every merge turned it into "last login" and destroyed the audit trail
  /// DP-5 depends on.
  Future<void> createOrUpdateUser(UserModel user) async {
    final ref = _db.collection(AppConstants.usersCollection).doc(user.uid);
    final existing = await ref.get();

    final data = user.toJson()..remove('createdAt');
    // Server timestamps avoid device clock skew.
    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    data['updatedAt'] = FieldValue.serverTimestamp();

    await ref.set(data, SetOptions(merge: true));
  }

  /// Streams user document for real-time role changes.
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection(AppConstants.usersCollection).doc(uid).snapshots().map(
      (doc) {
        if (!doc.exists || doc.data() == null) return null;
        return UserModel.fromJson({...doc.data()!, 'uid': uid});
      },
    );
  }

  /// Updates user role (admin only).
  Future<void> updateUserRole(String uid, String newRole) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'role': newRole,
    });
  }

  /// Searches users by phone number prefix (for admin role management).
  Future<List<UserModel>> searchUsersByPhone(String phonePrefix) async {
    final query = await _db
        .collection(AppConstants.usersCollection)
        .orderBy('phone')
        .startAt([phonePrefix])
        .endAt(['$phonePrefix\uf8ff'])
        .limit(AppConstants.paginationLimit)
        .get();
    return query.docs.map((doc) {
      return UserModel.fromJson({...doc.data(), 'uid': doc.id});
    }).toList();
  }

  /// Updates FCM token for push notifications.
  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'fcmToken': token,
    });
  }

  // ═══════════════════════════════════════════════════
  // VILLAGES
  // ═══════════════════════════════════════════════════

  /// Streams all active villages.
  Stream<List<VillageModel>> streamActiveVillages() {
    return _db
        .collection(AppConstants.villagesCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return VillageModel.fromJson({...doc.data(), 'villageId': doc.id});
            }).toList());
  }

  /// Streams the `reference/current` aggregate — all villages and health
  /// centres in one document.
  ///
  /// Emits null when the document does not exist yet, which is the signal for
  /// callers to fall back to the collection streams below. That happens only
  /// between deploying and the first `rebuildReferenceData` call.
  ///
  /// Returns the raw map rather than models because the aggregate stores a
  /// projection (name and status only), not whole documents.
  Stream<Map<String, dynamic>?> streamReferenceData() {
    return _db.collection('reference').doc('current').snapshots().map(
          (doc) => doc.exists ? doc.data() : null,
        );
  }

  /// Streams all villages (for admin — includes inactive).
  Stream<List<VillageModel>> streamAllVillages() {
    return _db.collection(AppConstants.villagesCollection).snapshots().map(
        (snap) => snap.docs.map((doc) {
              return VillageModel.fromJson({...doc.data(), 'villageId': doc.id});
            }).toList());
  }

  /// Creates a new village.
  Future<String> createVillage(VillageModel village) async {
    final ref = _db.collection(AppConstants.villagesCollection).doc();
    final data = village.copyWith(villageId: ref.id).toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  /// Deactivates a village (never deletes).
  Future<void> deactivateVillage(String villageId, String adminUid) async {
    await _db.collection(AppConstants.villagesCollection).doc(villageId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminUid,
    });
  }

  // ═══════════════════════════════════════════════════
  // HEALTH CENTRES
  // ═══════════════════════════════════════════════════

  /// Streams active health centres, optionally filtered by village.
  Stream<List<HealthCenterModel>> streamHealthCenters({String? villageId}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.healthCentersCollection)
        .where('isActive', isEqualTo: true);

    if (villageId != null) {
      query = query.where('villageId', isEqualTo: villageId);
    }

    return query.snapshots().map((snap) => snap.docs.map((doc) {
          return HealthCenterModel.fromJson({...doc.data(), 'centerId': doc.id});
        }).toList());
  }

  /// Creates a new health centre.
  Future<String> createHealthCenter(HealthCenterModel center) async {
    final ref = _db.collection(AppConstants.healthCentersCollection).doc();
    final data = center.copyWith(centerId: ref.id).toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  /// Deactivates a health centre.
  Future<void> deactivateHealthCenter(String centerId, String adminUid) async {
    await _db
        .collection(AppConstants.healthCentersCollection)
        .doc(centerId)
        .update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminUid,
    });
  }

  // ═══════════════════════════════════════════════════
  // DOCTORS
  // ═══════════════════════════════════════════════════

  /// Streams a single doctor document.
  Stream<DoctorModel?> streamDoctor(String doctorId) {
    return _db
        .collection(AppConstants.doctorsCollection)
        .doc(doctorId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return DoctorModel.fromJson({...doc.data()!, 'doctorId': doc.id});
    });
  }

  /// Streams doctors pending approval (for admin).
  Stream<List<DoctorModel>> streamPendingDoctors() {
    return _db
        .collection(AppConstants.doctorsCollection)
        .where('status', isEqualTo: AppConstants.doctorPendingApproval)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return DoctorModel.fromJson({...doc.data(), 'doctorId': doc.id});
            }).toList());
  }

  /// Streams active doctors, optionally filtered by village.
  Stream<List<DoctorModel>> streamActiveDoctors({String? villageId}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.doctorsCollection)
        .where('status', isEqualTo: AppConstants.doctorActive);

    if (villageId != null) {
      query = query.where('villages', arrayContains: villageId);
    }

    return query.snapshots().map((snap) => snap.docs.map((doc) {
          return DoctorModel.fromJson({...doc.data(), 'doctorId': doc.id});
        }).toList());
  }

  /// Streams all doctors (for admin — includes all statuses).
  Stream<List<DoctorModel>> streamAllDoctors() {
    return _db.collection(AppConstants.doctorsCollection).snapshots().map(
        (snap) => snap.docs.map((doc) {
              return DoctorModel.fromJson({...doc.data(), 'doctorId': doc.id});
            }).toList());
  }

  /// Updates doctor status (approve/reject/activate/deactivate).
  Future<void> updateDoctorStatus({
    required String doctorId,
    required String status,
    String? rejectionNote,
    String? approvedBy,
  }) async {
    final Map<String, dynamic> data = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionNote != null) data['rejectionNote'] = rejectionNote;
    if (approvedBy != null) {
      data['approvedBy'] = approvedBy;
      data['approvedAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection(AppConstants.doctorsCollection).doc(doctorId).update(data);
  }

  /// Updates doctor's editable (non-credential) fields.
  /// SRS §5.1: "Profile: view/edit non-credential fields."
  Future<void> updateDoctorProfile({
    required String doctorId,
    required String name,
    required String specialization,
    required String mobile,
    String? photoBase64,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'specialization': specialization,
      'mobile': mobile,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoBase64 != null) {
      // Empty string signals "remove photo" — delete the field entirely.
      data['photoBase64'] =
          photoBase64.isEmpty ? FieldValue.delete() : photoBase64;
    }
    await _db.collection(AppConstants.doctorsCollection).doc(doctorId).update(data);
  }

  // ═══════════════════════════════════════════════════
  // PATIENTS
  // ═══════════════════════════════════════════════════

  /// Gets patient by userId (Firebase Auth UID).
  Future<PatientModel?> getPatientByUserId(String userId) async {
    final query = await _db
        .collection(AppConstants.patientsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return PatientModel.fromJson({...doc.data(), 'patientId': doc.id});
  }

  /// Creates a new patient profile.
  Future<String> createPatient(PatientModel patient) async {
    final ref = _db.collection(AppConstants.patientsCollection).doc();
    final data = patient.copyWith(patientId: ref.id).toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  /// Searches patients by name prefix (server-side, not client filter).
  Stream<List<PatientModel>> searchPatients(
    String namePrefix, {
    int limit = AppConstants.paginationLimit,
  }) {
    return _db
        .collection(AppConstants.patientsCollection)
        .orderBy('name')
        .startAt([namePrefix])
        .endAt(['$namePrefix\uf8ff'])
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return PatientModel.fromJson({...doc.data(), 'patientId': doc.id});
            }).toList());
  }

  /// Checks for duplicate patient by mobile number (operator flow).
  Future<PatientModel?> findPatientByMobile(String mobile) async {
    final query = await _db
        .collection(AppConstants.patientsCollection)
        .where('mobile', isEqualTo: mobile)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return PatientModel.fromJson({...doc.data(), 'patientId': doc.id});
  }

  /// Updates a patient profile.
  ///
  /// Immutable and server-owned fields are stripped: `patientId` and `userId`
  /// are identity (the rules reject changes to `userId` outright), and
  /// `createdAt` arrives as null from a round-tripped model, which would
  /// erase the original value.
  Future<void> updatePatient(String patientId, Map<String, dynamic> data) async {
    final sanitised = Map<String, dynamic>.from(data)
      ..remove('patientId')
      ..remove('userId')
      ..remove('createdAt')
      ..remove('createdBy')
      ..remove('createdByOperatorId');
    sanitised['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection(AppConstants.patientsCollection)
        .doc(patientId)
        .update(sanitised);
  }

  /// Reads a single patient by document id (operator booking flow).
  Future<PatientModel?> getPatient(String patientId) async {
    final doc = await _db
        .collection(AppConstants.patientsCollection)
        .doc(patientId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return PatientModel.fromJson({...doc.data()!, 'patientId': doc.id});
  }

  // ═══════════════════════════════════════════════════
  // DOCTOR AVAILABILITY
  // ═══════════════════════════════════════════════════

  /// Gets availability for a specific doctor on a specific date.
  Future<AvailabilityModel?> getAvailability(String doctorId, String date) async {
    final docId = '${doctorId}_$date';
    final doc = await _db.collection(AppConstants.availabilityCollection).doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AvailabilityModel.fromJson(doc.data()!);
  }

  /// Streams availability for a doctor on a date.
  Stream<AvailabilityModel?> streamAvailability(String doctorId, String date) {
    final docId = '${doctorId}_$date';
    return _db
        .collection(AppConstants.availabilityCollection)
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AvailabilityModel.fromJson(doc.data()!);
    });
  }

  /// Streams dates with availability for a doctor within a date range.
  Stream<List<AvailabilityModel>> streamDoctorAvailabilityRange(
    String doctorId,
    String startDate,
    String endDate,
  ) {
    return _db
        .collection(AppConstants.availabilityCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return AvailabilityModel.fromJson(doc.data());
            }).toList());
  }

  // ═══════════════════════════════════════════════════
  // APPOINTMENTS
  // ═══════════════════════════════════════════════════

  // Booking, cancellation and status transitions are Cloud Functions
  // (`bookAppointment`, `cancelAppointment`, `updateAppointmentStatus`,
  // `cancelDoctorDay`) reached through FunctionsService. They each mutate an
  // appointment *and* a slot together, which security rules cannot validate,
  // so the client is denied those writes outright. See §A17-1.

  /// Streams appointments for a doctor.
  Stream<List<AppointmentModel>> streamDoctorAppointments(
    String doctorId, {
    String? status,
    int limit = AppConstants.paginationLimit,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true)
        .limit(limit);

    if (status != null) {
      query = _db
          .collection(AppConstants.appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: status)
          .orderBy('date', descending: true)
          .limit(limit);
    }

    return query.snapshots().map((snap) => snap.docs.map((doc) {
          return AppointmentModel.fromJson(
              {...doc.data(), 'appointmentId': doc.id});
        }).toList());
  }

  /// Streams a doctor's appointments for one specific date.
  ///
  /// The dashboard previously took the 20 most recent appointments overall
  /// and filtered for today in the widget. Because the ordering is
  /// descending, future-dated appointments fill that window first and today's
  /// queue silently renders empty once a doctor has 20 of them
  /// (TECHNICAL_ASSESSMENT.md §11.6). Filtering in the query removes both the
  /// data loss and the wasted reads.
  Stream<List<AppointmentModel>> streamDoctorAppointmentsForDate(
    String doctorId,
    String date, {
    int limit = 50,
  }) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: date)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return AppointmentModel.fromJson(
                  {...doc.data(), 'appointmentId': doc.id});
            }).toList());
  }

  /// Streams a doctor's appointments from [fromDate] onward (upcoming queue).
  Stream<List<AppointmentModel>> streamDoctorAppointmentsFrom(
    String doctorId,
    String fromDate, {
    int limit = AppConstants.paginationLimit,
  }) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: fromDate)
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return AppointmentModel.fromJson(
                  {...doc.data(), 'appointmentId': doc.id});
            }).toList());
  }

  /// Streams appointments for a patient.
  Stream<List<AppointmentModel>> streamPatientAppointments(
    String patientUserId, {
    int limit = AppConstants.paginationLimit,
  }) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('patientUserId', isEqualTo: patientUserId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return AppointmentModel.fromJson(
                  {...doc.data(), 'appointmentId': doc.id});
            }).toList());
  }

  /// Streams a patient's completed appointments — the source of their health
  /// record (SRS §5.1 Patient module).
  ///
  /// Deliberately a query of its own rather than a filter over the dashboard's
  /// appointment list. Deriving clinical history from a UI list meant it
  /// inherited that list's page size, so a patient with more than a page of
  /// appointments silently lost their older visit summaries — with nothing on
  /// screen to say anything was missing (PATIENT_MODULE.md P-01).
  Stream<List<AppointmentModel>> streamPatientCompletedAppointments(
    String patientUserId, {
    int limit = AppConstants.paginationLimit,
  }) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('patientUserId', isEqualTo: patientUserId)
        .where('status', isEqualTo: AppConstants.appointmentCompleted)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return AppointmentModel.fromJson(
                  {...doc.data(), 'appointmentId': doc.id});
            }).toList());
  }

  /// Streams all appointments (admin monitoring), optionally filtered by status.
  Stream<List<AppointmentModel>> streamAllAppointments({
    String? status,
    int limit = AppConstants.paginationLimit,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.appointmentsCollection)
        .orderBy('date', descending: true)
        .limit(limit);

    if (status != null) {
      query = _db
          .collection(AppConstants.appointmentsCollection)
          .where('status', isEqualTo: status)
          .orderBy('date', descending: true)
          .limit(limit);
    }

    return query.snapshots().map((snap) => snap.docs.map((doc) {
          return AppointmentModel.fromJson(
              {...doc.data(), 'appointmentId': doc.id});
        }).toList());
  }

  /// Streams operator-created appointments for today.
  Stream<List<AppointmentModel>> streamOperatorAppointments(
    String operatorUid, {
    String? date,
    int limit = AppConstants.paginationLimit,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppConstants.appointmentsCollection)
        .where('createdByOperatorId', isEqualTo: operatorUid)
        .orderBy('date', descending: true)
        .limit(limit);

    if (date != null) {
      // Equality on both fields, so no ordering is needed — dropping the
      // redundant `orderBy` also removes the second composite index this
      // query used to require.
      query = _db
          .collection(AppConstants.appointmentsCollection)
          .where('createdByOperatorId', isEqualTo: operatorUid)
          .where('date', isEqualTo: date)
          .limit(limit);
    }

    return query.snapshots().map((snap) => snap.docs.map((doc) {
          return AppointmentModel.fromJson(
              {...doc.data(), 'appointmentId': doc.id});
        }).toList());
  }

  // ═══════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════

  /// Streams a user's notification inbox, newest first.
  ///
  /// Documents are written exclusively by Cloud Functions (security rules
  /// deny client creates), so their contents are a trustworthy record of what
  /// the system did rather than of what a client claimed.
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return NotificationModel.fromJson(
                  {...doc.data(), 'notificationId': doc.id});
            }).toList());
  }

  /// Streams the unread notification count for the app-bar badge.
  Stream<int> streamUnreadNotificationCount(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Marks a notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  // ═══════════════════════════════════════════════════
  // AGGREGATE COUNTS (for dashboard stat cards)
  // ═══════════════════════════════════════════════════

  /// Counts documents matching a query. Uses aggregation for efficiency.
  Future<int> countDocuments(String collection, {String? field, dynamic value}) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    if (field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }
    final snap = await query.count().get();
    return snap.count ?? 0;
  }
}
