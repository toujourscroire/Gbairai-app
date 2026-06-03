import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/app_theme.dart';
import 'diag/boot_diagnostics.dart';
import 'routing/app_router.dart';

class GbairaiApp extends ConsumerWidget {
  const GbairaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bootLog('BOOT 7 — GbairaiApp.build() appelé');
    final router = ref.watch(routerProvider);
    bootLog('BOOT 7 OK — routerProvider prêt, MaterialApp.router monte');

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
