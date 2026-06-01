import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/app_theme.dart';
import 'routing/app_router.dart';

class GbairaiApp extends ConsumerWidget {
  const GbairaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[BOOT 6] GbairaiApp.build() called — router initializing');
    final router = ref.watch(routerProvider);
    debugPrint('[BOOT 6] routerProvider ready — MaterialApp.router mounting');

    return MaterialApp.router(
      title: 'Gbairai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          // Empêche le text scaling automatique — préserve le design
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
