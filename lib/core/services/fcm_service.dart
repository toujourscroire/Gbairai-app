import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'security/deep_link_security.dart';

// ── Constantes compile-time (dart-define injectées par Codemagic) ────────────
// Zéro plist dans le bundle — évite SWBUtil.PropertyListConversionError sur
// Xcode 16+ quand la plist est dans Copy Bundle Resources avec contenu invalide.
const _kFirebaseApiKey    = String.fromEnvironment('FIREBASE_API_KEY');
const _kFirebaseAppId     = String.fromEnvironment('FIREBASE_APP_ID');
const _kFirebaseSenderId  = String.fromEnvironment('FIREBASE_SENDER_ID');
const _kFirebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _kFirebaseStorage   = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
const _kFirebaseBundle    = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'ci.gbairai.app');

/// Retourne les options Firebase si toutes les valeurs essentielles sont présentes,
/// null sinon (Firebase désactivé silencieusement — l'app ne crashe pas).
FirebaseOptions? _buildFirebaseOptions() {
  if (_kFirebaseApiKey.isEmpty ||
      _kFirebaseAppId.isEmpty ||
      _kFirebaseSenderId.isEmpty ||
      _kFirebaseProjectId.isEmpty) {
    return null;
  }
  return FirebaseOptions(
    apiKey: _kFirebaseApiKey,
    appId: _kFirebaseAppId,
    messagingSenderId: _kFirebaseSenderId,
    projectId: _kFirebaseProjectId,
    storageBucket: _kFirebaseStorage.isEmpty ? null : _kFirebaseStorage,
    iosBundleId: _kFirebaseBundle,
  );
}

// Handler pour les messages en background (top-level function requise)
// Tourne dans un isolate séparé — dart-defines disponibles car constantes compile-time.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final opts = _buildFirebaseOptions();
  if (opts != null && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: opts);
  }
  debugPrint('[FCM Background] message received: ${message.messageId}');
}

class FcmService {
  static final _log = Logger(printer: PrettyPrinter(methodCount: 0));
  // Lazy getter — NE PAS utiliser static final (évalué au chargement de la classe)
  static FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  static Future<void> initialize() async {
    debugPrint('[BOOT 4a] FcmService.initialize() entered');
    final opts = _buildFirebaseOptions();
    if (opts == null) {
      debugPrint('[BOOT 4b] dart-defines Firebase absents — FCM désactivé');
      _log.w('[FCM] dart-defines Firebase absents — FCM désactivé (builds locaux OK)');
      return;
    }
    debugPrint('[BOOT 4b] Firebase options built — FIREBASE_PROJECT_ID=$_kFirebaseProjectId');

    // Firebase.apps.isEmpty évite "App already initialized"
    if (Firebase.apps.isEmpty) {
      debugPrint('[BOOT 4c] Firebase.initializeApp() starting...');
      await Firebase.initializeApp(options: opts);
      debugPrint('[BOOT 4c] Firebase.initializeApp() DONE');
    } else {
      debugPrint('[BOOT 4c] Firebase already initialized — skipping');
    }

    // Enregistrer le handler background
    debugPrint('[BOOT 4d] Registering background message handler');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurer les options iOS
    debugPrint('[BOOT 4e] setForegroundNotificationPresentationOptions...');
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[BOOT 4e] setForegroundNotificationPresentationOptions DONE');

    // Écouter les messages foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Vérifier si app ouverte depuis une notification
    debugPrint('[BOOT 4f] getInitialMessage() starting... (can be slow)');
    final initial = await _fcm.getInitialMessage();
    debugPrint('[BOOT 4f] getInitialMessage() DONE — hasMessage=${initial != null}');
    if (initial != null) _handleNotificationTap(initial);

    debugPrint('[BOOT 4g] FcmService.initialize() complete');
  }

  // Demander la permission iOS (appelé dans l'onboarding)
  static Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Récupérer le token FCM
  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      _log.e('[FCM] getToken error: $e');
      return null;
    }
  }

  // Supprimer le token (déconnexion)
  static Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
    } catch (e) {
      _log.e('[FCM] deleteToken error: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _log.d('[FCM] Foreground: ${message.notification?.title}');
    // Les alertes Gbairai sont traitées via le provider Riverpod
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final deepLink = data['deep_link'] as String?;

    if (deepLink != null) {
      // SÉCURITÉ : valider le deep link avant de router
      final result = DeepLinkSecurity.validate(deepLink);
      if (!result.isValid) {
        _log.w('[FCM] Deep link invalide: $deepLink — ${result.error}');
        return;
      }
      // Le routing est délégué au AppRouter via un notifier global
      _pendingDeepLink = result.uri.toString();
    }
  }

  // Deep link en attente de traitement par le router
  static String? _pendingDeepLink;
  static String? consumePendingDeepLink() {
    final link = _pendingDeepLink;
    _pendingDeepLink = null;
    return link;
  }

  // Notification type identifiers
  static const String typeAlert = 'gbairai_alert';
  static const String typeReaction = 'reaction';
  static const String typeComment = 'comment';
  static const String typeFollow = 'follow';
  static const String typeMention = 'mention';
}
