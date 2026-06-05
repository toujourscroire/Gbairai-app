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
          // Fallback rouge visible — GoRouter n'a pas résolu de route
          // Si tu vois cet écran : le routeur est bloqué avant la WelcomePage
          debugPrint('[APP] builder child==null — GoRouter not resolved yet');
          return const ColoredBox(
            color: Color(0xFFCC0000), // Rouge vif — impossible à confondre avec le fond noir
            child: Center(
              child: Text(
                '[APP] child==null\nGoRouter not resolved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
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
