import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

// Singleton sécurisé pour le client Supabase
// Toutes les requêtes passent par ce service

class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      // Pas de log en production
      debug: false,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Session? get currentSession => client.auth.currentSession;
  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentSession != null;

  // Récupère le JWT actuel (pour les requêtes authentifiées)
  static String? get accessToken => currentSession?.accessToken;

  // Vérification que le token n'est pas expiré
  static bool get isTokenValid {
    final session = currentSession;
    if (session == null) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    // Considérer expiré 5 minutes avant l'expiration réelle
    return expiresAt.isAfter(
      DateTime.now().add(const Duration(minutes: 5)),
    );
  }
}
