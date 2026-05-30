// ignore_for_file: do_not_use_environment
import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  // ── Environnement ──────────────────────────────────────────────────
  static bool get isProduction => !kDebugMode && !kProfileMode;
  static String get environment => kDebugMode ? 'development' : 'production';

  // ── Supabase (injectés via dart-define au build) ───────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // ── Monitoring ────────────────────────────────────────────────────
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://app.posthog.com',
  );

  // ── Auth ──────────────────────────────────────────────────────────
  static const Duration sessionDuration = Duration(days: 30);
  static const int otpLength = 6;
  static const Duration otpExpiry = Duration(minutes: 10);
  static const int otpMaxRetries = 3;
  static const List<Duration> otpRetryDelays = [
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(minutes: 10),
  ];
  static const int anonymousPostsQuota = 3;
  static const Duration anonymousQuotaReset = Duration(days: 30);

  // ── Rate Limiting ─────────────────────────────────────────────────
  static const int maxPostsPerHour = 10;
  static const int maxReactionsPerMinute = 30;
  static const int maxCommentsPerHour = 50;
  static const int maxReportsPerDay = 20;

  // ── Feed ──────────────────────────────────────────────────────────
  static const int feedPageSize = 10;
  static const int preloadCount = 2;
  static const int maxCacheSizeMb = 300;
  static const Duration contentCacheDuration = Duration(hours: 12);

  // ── Contenu ───────────────────────────────────────────────────────
  static const int maxCaptionLength = 280;
  static const int maxBioLength = 150;
  static const int maxCommentLength = 300;
  static const int maxVoiceTitleLength = 80;
  static const int maxHashtagsPerPost = 10;
  static const Duration minVideoDuration = Duration(seconds: 3);
  static const Duration maxVideoDuration = Duration(minutes: 3);
  static const Duration minVoiceDuration = Duration(seconds: 5);
  static const Duration maxVoiceDuration = Duration(minutes: 2);
  static const Duration maxVoiceReactionDuration = Duration(seconds: 30);

  // ── Alertes Gbairai ───────────────────────────────────────────────
  static const int maxNationalAlertsPerDay = 3;
  static const int alertOpenRateThresholdPercent = 15;

  // ── Scoring de viralité ───────────────────────────────────────────
  static const int scoreWeight_view = 1;
  static const int scoreWeight_reaction = 3;
  static const int scoreWeight_comment = 5;
  static const int scoreWeight_share = 10;
  static const int scoreWeight_voiceReaction = 8;
  static const double scoreDecayFactor = 1.5;
  static const Duration scoringWindow = Duration(hours: 6);

  // ── Seuils alerte ─────────────────────────────────────────────────
  static const int preGbairaiViews = 300;
  static const int preGbairaiMinutes = 10;
  static const double preGbairaiEngagement = 0.6;
  static const int localGbairaiViews = 1500;
  static const int localGbairaiMinutes = 20;
  static const int localGbairaiReactions = 80;
  static const int nationalGbairaiViews = 8000;
  static const int nationalGbairaiMinutes = 60;
  static const int legendaireGbairaiViews = 40000;

  // ── Modération ────────────────────────────────────────────────────
  static const double moderationAutoApproveThreshold = 0.3;
  static const double moderationManualReviewThreshold = 0.7;
  static const int flagsForPreventiveSuspension = 5;
  static const Duration flagsWindowForSuspension = Duration(hours: 1);
  static const int flagsForImmediateRemoval = 10;

  // ── Deep Links ────────────────────────────────────────────────────
  static const String appScheme = 'gbairai';
  static const String appDomain = 'gbairai.ci';
  static const String whatsappShareBaseUrl = 'https://wa.me/?text=';
}
