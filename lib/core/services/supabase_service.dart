import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  // ── ID interne (users.id, gen_random_uuid) ────────────────────────
  // DISTINCT de currentUser.id (qui est users.auth_id, le UUID Supabase auth).
  // Toutes les FK de la DB (reactions, follows, comments…) référencent users.id.
  // Settée par AuthController après _postAuth(), clearée après signOut/deleteAccount.
  static String? _internalUserId;

  /// L'UUID interne de l'utilisateur courant dans la table `users` (≠ auth UUID).
  /// Null si non connecté ou avant que _postAuth n'ait été appelé.
  static String? get internalUserId => _internalUserId;

  static void setInternalUserId(String id) => _internalUserId = id;
  static void clearInternalUserId() => _internalUserId = null;

  static Future<void> initialize() async {
    if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY is empty — check dart-define');
    }
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      debug: false,
    );
    _initialized = true;
  }

  static bool get isReady => _initialized;

  static SupabaseClient? get clientOrNull =>
      _initialized ? Supabase.instance.client : null;

  // Throws if not initialized — use clientOrNull for safe access
  static SupabaseClient get client {
    if (!_initialized) throw StateError('SupabaseService not initialized');
    return Supabase.instance.client;
  }

  static Session? get currentSession => clientOrNull?.auth.currentSession;
  static User? get currentUser => clientOrNull?.auth.currentUser;
  static bool get isAuthenticated => currentSession != null;
  static String? get accessToken => currentSession?.accessToken;

  static bool get isTokenValid {
    final session = currentSession;
    if (session == null) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    return expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 5)));
  }
}
