import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/security/device_fingerprint.dart';
import '../../../../core/services/security/rate_limiter.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/user_model.dart';

class AuthRemoteDatasource {
  // Lazy — accessed only when Supabase is guaranteed initialized
  SupabaseClient get _client => SupabaseService.client;

  // ── Téléphone OTP ────────────────────────────────────────────────
  Future<void> sendPhoneOtp(String phone) async {
    // Rate limiting côté client
    final rl = await RateLimiter.instance.checkAndRecord(
      RateLimitAction.otp,
    );
    if (!rl.allowed) throw Failure.rateLimited(retryAfter: rl.retryAfterMessage);

    await _client.auth.signInWithOtp(
      phone: phone,
      shouldCreateUser: true,
    );
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final rl = await RateLimiter.instance.checkAndRecord(
      RateLimitAction.authAttempt,
    );
    if (!rl.allowed) throw Failure.rateLimited(retryAfter: rl.retryAfterMessage);

    return _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // ── Google Sign-In ────────────────────────────────────────────────
  Future<AuthResponse> signInWithGoogle({
    required String idToken,
    required String accessToken,
  }) async {
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // ── Apple Sign-In ─────────────────────────────────────────────────
  Future<AuthResponse> signInWithApple({
    required String idToken,
    String? nonce,
  }) async {
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: nonce,
    );
  }

  // ── Email / Password ──────────────────────────────────────────────
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final rl = await RateLimiter.instance.checkAndRecord(
      RateLimitAction.authAttempt,
    );
    if (!rl.allowed) throw Failure.rateLimited(retryAfter: rl.retryAfterMessage);

    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  // ── Déconnexion ───────────────────────────────────────────────────
  Future<void> signOut() async {
    // Supprimer le token FCM côté serveur
    try {
      final fcmToken = await FcmService.getToken();
      if (fcmToken != null && SupabaseService.isAuthenticated) {
        await _client.from('profiles').update({'fcm_token': null}).eq(
          'user_id',
          SupabaseService.currentUser!.id,
        );
      }
    } catch (_) {}

    await FcmService.deleteToken();
    await _client.auth.signOut();
  }

  // ── Profil & Onboarding ───────────────────────────────────────────
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _client
        .from('users')
        .select('id')
        .eq('username', username)
        .limit(1);
    return (result as List).isEmpty;
  }

  Future<UserModel> createProfile({
    required String authId,
    required String username,
    required String displayName,
    required List<String> interests,
    String? avatarUrl,
  }) async {
    final deviceFp = await DeviceFingerprintService.getOrCreate();
    final fcmToken = await FcmService.getToken();

    // Transaction : créer user + profile
    final userData = await _client.from('users').insert({
      'auth_id': authId,
      'username': username,
    }).select().single();

    await _client.from('profiles').insert({
      'user_id': userData['id'],
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
      'notification_pref': {
        'alerts': 'all',
        'quiet_start': '23:00',
        'quiet_end': '07:00',
        'categories': interests,
      },
    });

    // Stocker le fingerprint pour détection multi-comptes
    await _client.from('device_fingerprints').upsert({
      'fingerprint': deviceFp,
      'user_id': userData['id'],
      'platform': 'ios',
    });

    return UserModel(
      id: userData['id'] as String,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  Future<UserModel?> getProfile(String authId) async {
    final result = await _client
        .from('users')
        .select('''
          id, username, role, is_banned,
          profiles!inner(
            display_name, bio, avatar_url, banner_url,
            city, level, followers_count, following_count,
            posts_count, is_verified, is_business
          )
        ''')
        .eq('auth_id', authId)
        .maybeSingle();

    if (result == null) return null;

    final profile = result['profiles'] as Map<String, dynamic>;
    return UserModel(
      id: result['id'] as String,
      username: result['username'] as String,
      displayName: profile['display_name'] as String,
      bio: profile['bio'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      bannerUrl: profile['banner_url'] as String?,
      city: profile['city'] as String? ?? 'Abidjan',
      level: profile['level'] as String? ?? 'debutant',
      followersCount: profile['followers_count'] as int? ?? 0,
      followingCount: profile['following_count'] as int? ?? 0,
      postsCount: profile['posts_count'] as int? ?? 0,
      isVerified: profile['is_verified'] as bool? ?? false,
      isBusiness: profile['is_business'] as bool? ?? false,
      isBanned: result['is_banned'] as bool? ?? false,
      role: result['role'] as String? ?? 'user',
    );
  }
}
