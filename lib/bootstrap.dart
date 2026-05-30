import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'app.dart';

Future<void> bootstrap() async {
  // 1. Supabase
  await SupabaseService.initialize();

  // 2. Firebase + FCM
  await FcmService.initialize();

  // 3. Analytics (PostHog)
  await AnalyticsService.initialize();

  // 4. Lancement app dans ProviderScope Riverpod
  runApp(
    const ProviderScope(
      child: GbairaiApp(),
    ),
  );
}
