import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    debugPrint('[BOOT 3a] SupabaseService.initialize() entered');
    debugPrint('[BOOT 3b] SUPABASE_URL empty=${AppConstants.supabaseUrl.isEmpty}');
    debugPrint('[BOOT 3b] SUPABASE_ANON_KEY empty=${AppConstants.supabaseAnonKey.isEmpty}');
    if (AppConstants.supabaseUrl.isEmpty || AppConstants.supabaseAnonKey.isEmpty) {
      debugPrint('[BOOT 3c] FATAL — dart-define SUPABASE_URL or SUPABASE_ANON_KEY missing');
      throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY is empty — check dart-define');
    }
    debugPrint('[BOOT 3c] Calling Supabase.initialize()...');
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
    debugPrint('[BOOT 3d] Supabase.initialize() DONE — _initialized=true');
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
