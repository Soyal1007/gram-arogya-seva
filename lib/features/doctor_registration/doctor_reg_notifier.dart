import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the multi-step doctor registration form state.
/// SRS §11.2 D-FLOW-01: 4-step registration.
enum DoctorRegStep { basicInfo, governmentIds, villageSelection, abdmVerification }

class DoctorRegState {
  final DoctorRegStep currentStep;
  final bool isLoading;
  final String? errorMessage;

  // Step 1: Basic Info
  final String name;
  final String specialization;
  final String mobile;

  // Step 2: Government IDs
  final String nmrId;
  final String hprId;
  final String aadhaarNumber;

  // Step 3: Villages
  final List<String> selectedVillageIds;

  // Step 4: ABDM
  final String? abdmTxnId;
  final bool abdmVerified;
  final bool otpSent;

  const DoctorRegState({
    this.currentStep = DoctorRegStep.basicInfo,
    this.isLoading = false,
    this.errorMessage,
    this.name = '',
    this.specialization = '',
    this.mobile = '',
    this.nmrId = '',
    this.hprId = '',
    this.aadhaarNumber = '',
    this.selectedVillageIds = const [],
    this.abdmTxnId,
    this.abdmVerified = false,
    this.otpSent = false,
  });

  DoctorRegState copyWith({
    DoctorRegStep? currentStep,
    bool? isLoading,
    String? errorMessage,
    String? name,
    String? specialization,
    String? mobile,
    String? nmrId,
    String? hprId,
    String? aadhaarNumber,
    List<String>? selectedVillageIds,
    String? abdmTxnId,
    bool? abdmVerified,
    bool? otpSent,
  }) {
    return DoctorRegState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      mobile: mobile ?? this.mobile,
      nmrId: nmrId ?? this.nmrId,
      hprId: hprId ?? this.hprId,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      selectedVillageIds: selectedVillageIds ?? this.selectedVillageIds,
      abdmTxnId: abdmTxnId ?? this.abdmTxnId,
      abdmVerified: abdmVerified ?? this.abdmVerified,
      otpSent: otpSent ?? this.otpSent,
    );
  }

  int get stepIndex => DoctorRegStep.values.indexOf(currentStep);
  int get totalSteps => DoctorRegStep.values.length;

  /// All specializations available for selection.
  static const List<String> specializations = [
    'General Physician',
    'Pediatrician',
    'Gynecologist',
    'Orthopedic',
    'Dermatologist',
    'ENT Specialist',
    'Ophthalmologist',
    'Dentist',
    'Ayurveda',
    'Homeopathy',
    'Other',
  ];
}

class DoctorRegNotifier extends StateNotifier<DoctorRegState> {
  DoctorRegNotifier() : super(const DoctorRegState());

  // ── Step 1: Basic Info
  void updateBasicInfo({
    required String name,
    required String specialization,
    required String mobile,
  }) {
    state = state.copyWith(
      name: name,
      specialization: specialization,
      mobile: mobile,
      currentStep: DoctorRegStep.governmentIds,
      errorMessage: null,
    );
  }

  // ── Step 2: Government IDs
  void updateGovernmentIds({
    required String nmrId,
    required String hprId,
    required String aadhaarNumber,
  }) {
    state = state.copyWith(
      nmrId: nmrId,
      hprId: hprId,
      aadhaarNumber: aadhaarNumber,
      currentStep: DoctorRegStep.villageSelection,
      errorMessage: null,
    );
  }

  // ── Step 3: Village selection
  void toggleVillage(String villageId) {
    final current = List<String>.from(state.selectedVillageIds);
    if (current.contains(villageId)) {
      current.remove(villageId);
    } else {
      current.add(villageId);
    }
    state = state.copyWith(selectedVillageIds: current);
  }

  void confirmVillages() {
    if (state.selectedVillageIds.isEmpty) {
      state = state.copyWith(errorMessage: 'Select at least one village');
      return;
    }
    state = state.copyWith(
      currentStep: DoctorRegStep.abdmVerification,
      errorMessage: null,
    );
  }

  // ── Step 4: ABDM OTP
  void setAbdmOtpSent(String txnId) {
    state = state.copyWith(
      abdmTxnId: txnId,
      otpSent: true,
      isLoading: false,
      errorMessage: null,
    );
  }

  void setAbdmVerified() {
    state = state.copyWith(
      abdmVerified: true,
      isLoading: false,
      errorMessage: null,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String message) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: message,
    );
  }

  // ── Navigation
  void goBack() {
    final currentIndex = state.stepIndex;
    if (currentIndex > 0) {
      state = state.copyWith(
        currentStep: DoctorRegStep.values[currentIndex - 1],
        errorMessage: null,
      );
    }
  }

  void reset() {
    state = const DoctorRegState();
  }
}

final doctorRegProvider =
    StateNotifierProvider<DoctorRegNotifier, DoctorRegState>((ref) {
  return DoctorRegNotifier();
});
