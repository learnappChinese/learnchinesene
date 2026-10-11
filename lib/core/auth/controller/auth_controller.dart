import 'dart:async';

import 'package:get/get.dart';

import '../data/auth_repository.dart';
import '../model/auth_state.dart';
import '../service/guest_progress_migration_service.dart';

class AuthController extends GetxController {
  AuthController({
    required AuthRepository authRepository,
    GuestProgressMigrationService? migrationService,
  })  : _authRepository = authRepository,
        _migrationService = migrationService,
        status = authRepository.currentStatus.obs,
        currentUser = Rxn<AppAuthUser>(authRepository.currentUser);

  final AuthRepository _authRepository;
  final GuestProgressMigrationService? _migrationService;

  final Rx<UserAuthStatus> status;
  final Rxn<AppAuthUser> currentUser;
  final isLoading = false.obs;
  final isMigrating = false.obs;
  final errorMessage = ''.obs;

  StreamSubscription<UserAuthStatus>? _statusSubscription;

  bool get isSignedIn =>
      status.value == UserAuthStatus.authenticated &&
      currentUser.value != null &&
      !currentUser.value!.isGuest;

  bool get isGuest =>
      status.value == UserAuthStatus.guest ||
      (currentUser.value != null && currentUser.value!.isGuest);

  String get displayName =>
      currentUser.value?.displayName ??
      (isGuest ? 'Khách lãng du' : 'Đại hiệp Tiếng Trung');

  String get userEmail => currentUser.value?.email ?? '';

  @override
  void onInit() {
    super.onInit();
    _statusSubscription = _authRepository.statusStream.listen((newStatus) {
      status.value = newStatus;
      currentUser.value = _authRepository.currentUser;
    });
    initialize();
  }

  Future<void> initialize() async {
    try {
      await _authRepository.initialize();
      status.value = _authRepository.currentStatus;
      currentUser.value = _authRepository.currentUser;
    } catch (_) {
      status.value = UserAuthStatus.guest;
      currentUser.value = AppAuthUser.guest();
    }
  }

  Future<bool> signIn(
    String email,
    String password, {
    bool autoMigrate = true,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _authRepository.signInWithPassword(
        email: email,
        password: password,
      );
      currentUser.value = user;
      status.value = UserAuthStatus.authenticated;

      if (autoMigrate && _migrationService != null) {
        await migrateGuestData();
      }
      return true;
    } catch (e) {
      errorMessage.value = _cleanErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? displayName,
    bool autoMigrate = true,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _authRepository.signUpWithPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      currentUser.value = user;
      status.value = UserAuthStatus.authenticated;

      if (autoMigrate && _migrationService != null) {
        await migrateGuestData();
      }
      return true;
    } catch (e) {
      errorMessage.value = _cleanErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      errorMessage.value = _cleanErrorMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _authRepository.signOut();
      currentUser.value = _authRepository.currentUser;
      status.value = _authRepository.currentStatus;
    } catch (e) {
      errorMessage.value = _cleanErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> continueAsGuest() async {
    try {
      final guest = await _authRepository.continueAsGuest();
      currentUser.value = guest;
      status.value = UserAuthStatus.guest;
    } catch (_) {
      final guest = AppAuthUser.guest();
      currentUser.value = guest;
      status.value = UserAuthStatus.guest;
    }
  }

  Future<MigrationResult?> migrateGuestData() async {
    final migration = _migrationService;
    final user = currentUser.value;
    if (migration == null || user == null || user.isGuest) return null;

    final hasData = await migration.hasGuestDataToMigrate();
    if (!hasData) return null;

    isMigrating.value = true;
    try {
      final result =
          await migration.migrateGuestProgress(targetUserId: user.id);
      return result;
    } finally {
      isMigrating.value = false;
    }
  }

  String _cleanErrorMessage(Object error) {
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    if (msg.startsWith('AuthException(message: ')) {
      final end = msg.indexOf(',');
      if (end != -1) {
        return msg.substring(23, end);
      }
    }
    return msg;
  }

  @override
  void onClose() {
    _statusSubscription?.cancel();
    super.onClose();
  }
}
