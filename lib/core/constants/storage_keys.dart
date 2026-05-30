abstract final class StorageKeys {
  // Secure Storage (chiffré)
  static const String authToken = 'gbairai_auth_token';
  static const String refreshToken = 'gbairai_refresh_token';
  static const String userId = 'gbairai_user_id';
  static const String biometricEnabled = 'gbairai_biometric_enabled';
  static const String deviceFingerprint = 'gbairai_device_fp';

  // SharedPreferences (non-sensible)
  static const String onboardingCompleted = 'onboarding_completed';
  static const String pushPermissionAsked = 'push_permission_asked';
  static const String selectedInterests = 'selected_interests';
  static const String notificationPrefs = 'notification_prefs';
  static const String feedScrollPosition = 'feed_scroll_pos';
  static const String appVersion = 'app_version';
  static const String lastAlertSeen = 'last_alert_seen';
  static const String networkQualityMode = 'network_quality_mode';
}
