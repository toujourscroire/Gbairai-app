import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/app_theme.dart';
import 'routing/app_router.dart';

class GbairaiApp extends ConsumerWidget {
  const GbairaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[APP] GbairaiApp.build() called');
    final router = ref.watch(routerProvider);
    debugPrint('[APP] routerProvider resolved');

    return MaterialApp.router(
      title: 'Gbairai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) {
          // GoRouter n'a pas encore résolu de route — fallback visible
          debugPrint('[APP] builder child==null — GoRouter not resolved yet');
          return const ColoredBox(
            color: Color(0xFF080810),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFE85D04)),
                ),
              ),
            ),
          );
        }
        return MediaQuery(
          // Empêche le text scaling automatique — préserve le design
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child,
        );
      },
    );
  }
}
