import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import 'security/deep_link_security.dart';

// Handler pour les messages en background (top-level function requise)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Pas de traitement de données sensibles en background
  debugPrint('[FCM Background] message received: ${message.messageId}');
}

class FcmService {
  static final _log = Logger(printer: PrettyPrinter(methodCount: 0));
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Enregistrer le handler background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurer les options iOS — demande permission séparément (géré dans onboarding)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Écouter les messages foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Écouter les taps sur notifications (app en background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Vérifier si app ouverte depuis une notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
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
