import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:convert';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/security/rate_limiter.dart';
import '../../../../core/services/security/secure_storage_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';

// ── State ─────────────────────────────────────────────────────────────
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}
class AuthNeedsOnboarding extends AuthState {
  final String authId;
  const AuthNeedsOnboarding(this.authId);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final Failure failure;
  const AuthError(this.failure);
}

// ── Providers ─────────────────────────────────────────────────────────
final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource();
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: ['email', 'profile'],
    // Client ID iOS configuré dans GoogleService-Info.plist
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.read(authDatasourceProvider),
    ref.read(googleSignInProvider),
    ref.read(secureStorageProvider),
  );
});

// Stream d'authentification Supabase
final authStateStreamProvider = StreamProvider<AuthState>((ref) async* {
  if (!SupabaseService.isReady) return;
  await for (final event in SupabaseService.client.auth.onAuthStateChange) {
    final session = event.session;
    if (session == null) {
      yield AuthUnauthenticated();
    } else {
      final ds = ref.read(authDatasourceProvider);
      final user = await ds.getProfile(session.user.id);
      if (user == null) {
        yield AuthNeedsOnboarding(session.user.id);
      } else {
        yield AuthAuthenticated(user);
      }
    }
  }
});

// ── Controller ────────────────────────────────────────────────────────
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ds, this._googleSignIn, this._secureStorage)
      : super(AuthInitial()) {
    _init();
  }

  final AuthRemoteDatasource _ds;
  final GoogleSignIn _googleSignIn;
  final SecureStorageService _secureStorage;

  Future<void> _init() async {
    try {
      if (!SupabaseService.isReady) {
        state = AuthUnauthenticated();
        return;
      }
      final session = SupabaseService.currentSession;
      if (session == null) {
        state = AuthUnauthenticated();
        return;
      }
      final user = await _ds.getProfile(session.user.id);
      state = user != null
          ? AuthAuthenticated(user)
          : AuthNeedsOnboarding(session.user.id);
    } catch (e) {
      state = AuthUnauthenticated();
    }
  }

  // ── Téléphone OTP ──────────────────────────────────────────────────
  Future<bool> sendPhoneOtp(String phone) async {
    state = AuthLoading();
    try {
      await _ds.sendPhoneOtp(phone);
      state = AuthUnauthenticated(); // Attente OTP
      return true;
    } on Failure catch (f) {
      state = AuthError(f);
      return false;
    } catch (e) {
      state = AuthError(Failure.unknown(message: e.toString()));
      return false;
    }
  }

  Future<bool> verifyPhoneOtp({required String phone, required String token}) async {
    state = AuthLoading();
    try {
      final response = await _ds.verifyPhoneOtp(phone: phone, token: token);
      if (response.session == null) {
        state = AuthError(const Failure.otpInvalid());
        return false;
      }
      await _postAuth(response.session!);
      return true;
    } on Failure catch (f) {
      state = AuthError(f);
      return false;
    } catch (e) {
      state = AuthError(const Failure.otpInvalid());
      return false;
    }
  }

  // ── Google Sign-In ──────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    state = AuthLoading();
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        state = AuthUnauthenticated();
        return false;
      }

      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        state = AuthError(const Failure.invalidCredentials());
        return false;
      }

      final response = await _ds.signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );
      if (response.session == null) {
        state = AuthError(const Failure.serverError());
        return false;
      }
      await _postAuth(response.session!);
      await AnalyticsService.authCompleted('google');
      return true;
    } on Failure catch (f) {
      state = AuthError(f);
      return false;
    } catch (e) {
      state = AuthError(Failure.unknown(message: e.toString()));
      return false;
    }
  }

  // ── Apple Sign-In ────────────────────────────────────────────────────
  Future<bool> signInWithApple() async {
    state = AuthLoading();
    try {
      // Générer un nonce sécurisé pour Apple Sign-In (protection CSRF)
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        state = AuthError(const Failure.invalidCredentials());
        return false;
      }

      final response = await _ds.signInWithApple(
        idToken: idToken,
        nonce: rawNonce,
      );
      if (response.session == null) {
        state = AuthError(const Failure.serverError());
        return false;
      }
      await _postAuth(response.session!);
      await AnalyticsService.authCompleted('apple');
      return true;
    } on SignInWithAppleAuthorizationException {
      state = AuthUnauthenticated(); // Annulé par l'utilisateur
      return false;
    } on Failure catch (f) {
      state = AuthError(f);
      return false;
    } catch (e) {
      state = AuthError(Failure.unknown(message: e.toString()));
      return false;
    }
  }

  // ── Email ─────────────────────────────────────────────────────────────
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final response = await _ds.signInWithEmail(
        email: email,
        password: password,
      );
      if (response.session == null) {
        state = AuthError(const Failure.invalidCredentials());
        return false;
      }
      await _postAuth(response.session!);
      await AnalyticsService.authCompleted('email');
      return true;
    } on AuthException catch (e) {
      state = AuthError(
        e.statusCode == '400'
            ? const Failure.invalidCredentials()
            : Failure.serverError(message: e.message),
      );
      return false;
    } on Failure catch (f) {
      state = AuthError(f);
      return false;
    }
  }

  // ── Onboarding ─────────────────────────────────────────────────────
  Future<bool> completeOnboarding({
    required String authId,
    required String username,
    required String displayName,
    required List<String> interests,
    String? avatarUrl,
  }) async {
    state = AuthLoading();
    try {
      final user = await _ds.createProfile(
        authId: authId,
        username: username,
        displayName: displayName,
        interests: interests,
        avatarUrl: avatarUrl,
      );
      state = AuthAuthenticated(user);
      await AnalyticsService.track('onboarding_completed');
      return true;
    } catch (e) {
      state = AuthError(Failure.unknown(message: e.toString()));
      return false;
    }
  }

  // ── Déconnexion ───────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _ds.signOut();
    await _secureStorage.deleteAll();
    await RateLimiter.instance.reset(RateLimitAction.authAttempt);
    state = AuthUnauthenticated();
  }

  // ── Helpers privés ───────────────────────────────────────────────
  Future<void> _postAuth(Session session) async {
    final user = await _ds.getProfile(session.user.id);
    state = user != null
        ? AuthAuthenticated(user)
        : AuthNeedsOnboarding(session.user.id);
  }

  // Nonce sécurisé pour Apple Sign-In (protection replay attack)
  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
