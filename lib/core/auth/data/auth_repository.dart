import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/auth_state.dart';

abstract interface class AuthRepository {
  Stream<UserAuthStatus> get statusStream;
  UserAuthStatus get currentStatus;
  AppAuthUser? get currentUser;
  bool get isSignedIn;
  bool get isGuest;

  Future<void> initialize();
  Future<AppAuthUser> signInWithPassword({
    required String email,
    required String password,
  });
  Future<AppAuthUser> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<AppAuthUser> continueAsGuest();
  void dispose();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    SupabaseClient? client,
    SharedPreferences? prefs,
  })  : _client = client,
        _prefs = prefs;

  final SupabaseClient? _client;
  SharedPreferences? _prefs;

  static const String keyHasSeenWelcome = 'has_seen_welcome_v1';
  static const String keyGuestEnabled = 'guest_mode_enabled_v1';
  static const String keyGuestId = 'guest_unique_id_v1';

  final _statusController = StreamController<UserAuthStatus>.broadcast();
  UserAuthStatus _status = UserAuthStatus.initializing;
  AppAuthUser? _currentUser;
  StreamSubscription<AuthState>? _authSubscription;

  SupabaseClient get _activeClient {
    if (_client != null) return _client;
    return Supabase.instance.client;
  }

  Future<SharedPreferences> get _getPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Stream<UserAuthStatus> get statusStream => _statusController.stream;

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

  void _setStatus(UserAuthStatus status, {AppAuthUser? user}) {
    _status = status;
    if (user != null || status == UserAuthStatus.guest) {
      _currentUser = user;
    } else if (status == UserAuthStatus.signingOut) {
      _currentUser = null;
    }
    _statusController.add(status);
  }

  @override
  Future<void> initialize() async {
    _setStatus(UserAuthStatus.initializing);
    try {
      final client = _activeClient;
      final currentSession = client.auth.currentSession;
      final prefs = await _getPrefs;

      _authSubscription?.cancel();
      _authSubscription = client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          _setStatus(
            UserAuthStatus.authenticated,
            user: AppAuthUser.fromSupabaseUser(session.user),
          );
        } else {
          // Check if guest mode is preserved
          if (_status != UserAuthStatus.signingOut) {
            _restoreGuestOrLogin(prefs);
          }
        }
      });

      if (currentSession != null) {
        _setStatus(
          UserAuthStatus.authenticated,
          user: AppAuthUser.fromSupabaseUser(currentSession.user),
        );
      } else {
        _restoreGuestOrLogin(prefs);
      }
    } catch (_) {
      final prefs = await _getPrefs;
      _restoreGuestOrLogin(prefs);
    }
  }

  void _restoreGuestOrLogin(SharedPreferences prefs) {
    final guestEnabled = prefs.getBool(keyGuestEnabled) ?? false;
    final guestId = prefs.getString(keyGuestId);
    if (guestEnabled) {
      _setStatus(
        UserAuthStatus.guest,
        user: AppAuthUser.guest(guestId: guestId),
      );
    } else {
      _setStatus(UserAuthStatus.guest,
          user: AppAuthUser.guest(guestId: guestId));
    }
  }

  @override
  Future<AppAuthUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _setStatus(UserAuthStatus.authenticating);
    try {
      final client = _activeClient;
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
            'Đăng nhập thất bại: người dùng không tồn tại.');
      }

      final authUser = AppAuthUser.fromSupabaseUser(user);
      final prefs = await _getPrefs;
      await prefs.setBool(keyGuestEnabled, false);

      _setStatus(UserAuthStatus.authenticated, user: authUser);
      return authUser;
    } on AuthException catch (e) {
      _setStatus(UserAuthStatus.authError);
      throw _mapAuthException(e);
    } catch (e) {
      _setStatus(UserAuthStatus.authError);
      throw Exception('Lỗi kết nối khi đăng nhập: $e');
    }
  }

  @override
  Future<AppAuthUser> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setStatus(UserAuthStatus.authenticating);
    try {
      final client = _activeClient;
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null && displayName.isNotEmpty
            ? {'display_name': displayName.trim()}
            : null,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Đăng ký thất bại. Vui lòng thử lại.');
      }

      final authUser = AppAuthUser.fromSupabaseUser(user);
      final prefs = await _getPrefs;
      await prefs.setBool(keyGuestEnabled, false);

      _setStatus(UserAuthStatus.authenticated, user: authUser);
      return authUser;
    } on AuthException catch (e) {
      _setStatus(UserAuthStatus.authError);
      throw _mapAuthException(e);
    } catch (e) {
      _setStatus(UserAuthStatus.authError);
      throw Exception('Lỗi kết nối khi đăng ký: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final client = _activeClient;
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw Exception('Lỗi khi gửi email khôi phục mật khẩu: $e');
    }
  }

  @override
  Future<void> signOut() async {
    _setStatus(UserAuthStatus.signingOut);
    try {
      final client = _activeClient;
      await client.auth.signOut();
    } catch (_) {
      // Continue cleanup even if server signOut encounters network error
    } finally {
      final prefs = await _getPrefs;
      await prefs.setBool(keyGuestEnabled, true);
      _setStatus(
        UserAuthStatus.guest,
        user: AppAuthUser.guest(guestId: prefs.getString(keyGuestId)),
      );
    }
  }

  @override
  Future<AppAuthUser> continueAsGuest() async {
    final prefs = await _getPrefs;
    await prefs.setBool(keyGuestEnabled, true);
    await prefs.setBool(keyHasSeenWelcome, true);

    var guestId = prefs.getString(keyGuestId);
    if (guestId == null) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(keyGuestId, guestId);
    }

    final guestUser = AppAuthUser.guest(guestId: guestId);
    _setStatus(UserAuthStatus.guest, user: guestUser);
    return guestUser;
  }

  AuthException _mapAuthException(AuthException exception) {
    final msg = exception.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credential') ||
        msg.contains('wrong password')) {
      return const AuthException('Email hoặc mật khẩu không chính xác.');
    }
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        msg.contains('email address already')) {
      return const AuthException(
          'Email này đã được đăng ký. Vui lòng đăng nhập.');
    }
    if (msg.contains('password should be at least') ||
        msg.contains('weak password')) {
      return const AuthException(
          'Mật khẩu quá ngắn (yêu cầu tối thiểu 6 ký tự).');
    }
    if (msg.contains('invalid email')) {
      return const AuthException('Định dạng email không hợp lệ.');
    }
    if (msg.contains('rate limit')) {
      return const AuthException(
          'Bạn đã gửi quá nhiều yêu cầu. Vui lòng đợi trong giây lát.');
    }
    return exception;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _statusController.close();
  }
}
