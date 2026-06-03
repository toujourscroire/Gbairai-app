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
        bootLog('BOOT 7b — MaterialApp.builder exécuté');
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BootOverlay(),
              ),
            ],
          ),
        );
      },
    );
  }
}
