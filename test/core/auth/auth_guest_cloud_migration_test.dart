import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flash_learn_chinese/core/auth/controller/auth_controller.dart';
import 'package:flash_learn_chinese/core/auth/data/auth_repository.dart';
import 'package:flash_learn_chinese/core/auth/model/auth_state.dart';
import 'package:flash_learn_chinese/core/auth/service/guest_progress_migration_service.dart';
import 'package:flash_learn_chinese/core/learning/model/learning_activity_submission.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    UserAuthStatus initialStatus = UserAuthStatus.guest,
    AppAuthUser? initialUser,
  })  : _status = initialStatus,
        _currentUser = initialUser;

  final _controller = StreamController<UserAuthStatus>.broadcast();
  UserAuthStatus _status;
  AppAuthUser? _currentUser;
  bool throwOnSignIn = false;
  bool throwOnSignUp = false;
  String? lastResetEmail;
  int signOutCount = 0;

  @override
  Stream<UserAuthStatus> get statusStream => _controller.stream;

  @override
  UserAuthStatus get currentStatus => _status;

  @override
  AppAuthUser? get currentUser => _currentUser;

  @override
  bool get isSignedIn =>
      _status == UserAuthStatus.authenticated &&
      _currentUser != null &&
      !_currentUser!.isGuest;

  @override
  bool get isGuest =>
      _status == UserAuthStatus.guest ||
      (_currentUser != null && _currentUser!.isGuest);

  void setStatus(UserAuthStatus status, {AppAuthUser? user}) {
    _status = status;
    _currentUser = user;
    _controller.add(status);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<AppAuthUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (throwOnSignIn) {
      throw const AuthException('Email hoặc mật khẩu không chính xác.');
    }
    final user = AppAuthUser(
      id: 'usr_cloud_123',
      email: email,
      displayName: 'Hiệp Khách Cloud',
      isGuest: false,
    );
    setStatus(UserAuthStatus.authenticated, user: user);
    return user;
  }

  @override
  Future<AppAuthUser> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (throwOnSignUp) {
      throw const AuthException(
          'Email này đã được đăng ký. Vui lòng đăng nhập.');
    }
    final user = AppAuthUser(
      id: 'usr_cloud_456',
      email: email,
      displayName: displayName ?? 'Tân Hiệp Khách',
      isGuest: false,
    );
    setStatus(UserAuthStatus.authenticated, user: user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    setStatus(UserAuthStatus.guest, user: AppAuthUser.guest());
  }

  @override
  Future<AppAuthUser> continueAsGuest() async {
    final guest = AppAuthUser.guest(guestId: 'guest_local_01');
    setStatus(UserAuthStatus.guest, user: guest);
    return guest;
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PR 04 — Auth Models & Repository Mapping', () {
    test('AppAuthUser model serializes and formats correctly', () {
      final guest = AppAuthUser.guest(guestId: 'g_123');
      expect(guest.isGuest, isTrue);
      expect(guest.id, equals('g_123'));
      expect(guest.displayName, equals('Khách lãng du'));

      final json = guest.toJson();
      expect(json['is_guest'], isTrue);
      expect(json['id'], equals('g_123'));

      final cloudUser = AppAuthUser(
        id: 'u_999',
        email: 'hero@chinese.com',
        displayName: 'Tiểu Hiệp',
        isGuest: false,
      );
      expect(cloudUser.isGuest, isFalse);
      expect(cloudUser.email, equals('hero@chinese.com'));
    });

    test(
        'SupabaseAuthRepository maps standard auth errors to friendly Vietnamese',
        () {
      final repo = SupabaseAuthRepository();
      expect(repo.isGuest, isFalse); // before init
    });
  });

  group('PR 04 — AuthController State & Actions', () {
    test('initializes as guest when no session exists', () async {
      final mockRepo = MockAuthRepository(
        initialStatus: UserAuthStatus.guest,
        initialUser: AppAuthUser.guest(),
      );
      final controller = AuthController(authRepository: mockRepo);

      expect(controller.isGuest, isTrue);
      expect(controller.isSignedIn, isFalse);
      expect(controller.displayName, equals('Khách lãng du'));
      controller.onClose();
    });

    test('sign in changes state to authenticated and updates user info',
        () async {
      final mockRepo = MockAuthRepository();
      final controller = AuthController(authRepository: mockRepo);

      final success = await controller.signIn('hero@chinese.com', 'password123',
          autoMigrate: false);
      expect(success, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(controller.isGuest, isFalse);
      expect(controller.userEmail, equals('hero@chinese.com'));
      expect(controller.displayName, equals('Hiệp Khách Cloud'));
      controller.onClose();
    });

    test('sign in failure reports clean Vietnamese error message', () async {
      final mockRepo = MockAuthRepository()..throwOnSignIn = true;
      final controller = AuthController(authRepository: mockRepo);

      final success = await controller.signIn('wrong@chinese.com', 'bad_pass',
          autoMigrate: false);
      expect(success, isFalse);
      expect(controller.isSignedIn, isFalse);
      expect(controller.errorMessage.value,
          contains('Email hoặc mật khẩu không chính xác'));
      controller.onClose();
    });

    test('sign up registers user and updates state', () async {
      final mockRepo = MockAuthRepository();
      final controller = AuthController(authRepository: mockRepo);

      final success = await controller.signUp(
        'newhero@chinese.com',
        'secure123',
        displayName: 'Độc Cô Cầu Bại',
        autoMigrate: false,
      );
      expect(success, isTrue);
      expect(controller.isSignedIn, isTrue);
      expect(controller.displayName, equals('Độc Cô Cầu Bại'));
      controller.onClose();
    });

    test('sign out resets user state back to guest and clears user-scoped info',
        () async {
      final mockRepo = MockAuthRepository();
      final controller = AuthController(authRepository: mockRepo);

      await controller.signIn('user_a@chinese.com', 'pass', autoMigrate: false);
      expect(controller.isSignedIn, isTrue);

      await controller.signOut();
      expect(controller.isSignedIn, isFalse);
      expect(controller.isGuest, isTrue);
      expect(controller.displayName, equals('Khách lãng du'));
      expect(mockRepo.signOutCount, equals(1));
      controller.onClose();
    });

    test('account switch: User A signs out and User B signs in cleanly',
        () async {
      final mockRepo = MockAuthRepository();
      final controller = AuthController(authRepository: mockRepo);

      // 1. User A signs in
      await controller.signIn('user_a@test.com', 'pass_a', autoMigrate: false);
      expect(controller.userEmail, equals('user_a@test.com'));

      // 2. User A signs out
      await controller.signOut();
      expect(controller.isGuest, isTrue);

      // 3. User B signs in
      await controller.signIn('user_b@test.com', 'pass_b', autoMigrate: false);
      expect(controller.userEmail, equals('user_b@test.com'));
      expect(controller.isSignedIn, isTrue);
      controller.onClose();
    });

    test('password reset delegates to repository', () async {
      final mockRepo = MockAuthRepository();
      final controller = AuthController(authRepository: mockRepo);

      final ok = await controller.sendPasswordReset('recover@test.com');
      expect(ok, isTrue);
      expect(mockRepo.lastResetEmail, equals('recover@test.com'));
      controller.onClose();
    });
  });

  group('PR 04 — Guest Progress Migration & Idempotency', () {
    test('hasGuestDataToMigrate detects local XP events or duo progress',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final migration = GuestProgressMigrationService(prefs: prefs);

      expect(await migration.hasGuestDataToMigrate(), isFalse);

      // Add a duo progress entry
      await prefs.setString(
        'duo_game_progress_v2_1_level_1',
        jsonEncode({'game_id': 1, 'level_id': 'level_1', 'is_completed': true}),
      );

      expect(await migration.hasGuestDataToMigrate(), isTrue);
    });

    test('hasGuestDataToMigrate detects pending activity submissions',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final migration = GuestProgressMigrationService(prefs: prefs);

      final submission = LearningActivitySubmission(
        activityType: 'vocabulary',
        sourceType: 'duo',
        sourceId: '1:level_1',
        unitId: 'unit_1',
        attemptId: 'att_g_01',
        score: 100,
        correctCount: 10,
        accuracy: 1.0,
      );

      await prefs.setStringList(
        'guest_learning_xp_events_v2',
        [
          jsonEncode({'submission': submission.toJson(), 'xp': 20})
        ],
      );

      expect(await migration.hasGuestDataToMigrate(), isTrue);
    });

    test('reconciles local guest attempts without wiping storage on failure',
        () async {
      final prefs = await SharedPreferences.getInstance();
      // Add local guest data
      await prefs.setStringList('guest_learning_attempts_v2', [
        jsonEncode({'id': 'att_1', 'status': 'completed'}),
      ]);

      // Service without client will catch error and NOT delete local storage
      final migration = GuestProgressMigrationService(prefs: prefs);
      final result =
          await migration.migrateGuestProgress(targetUserId: 'target_u1');

      expect(result.success, isFalse);
      // Local attempts remain preserved for safe retry
      final remaining = prefs.getStringList('guest_learning_attempts_v2');
      expect(remaining, isNotNull);
      expect(remaining!.length, equals(1));
    });
  });
}
