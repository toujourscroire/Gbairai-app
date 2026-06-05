import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bootstrap.dart';

void main() {
  // Zone de protection globale — capture toutes les exceptions non gérées
  // Visible dans la console Xcode (Xcode → Window → Devices and Simulators)
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('[STARTUP] main() — WidgetsFlutterBinding OK');

      // Capture les erreurs Flutter (build, layout, paint)
      FlutterError.onError = (details) {
        debugPrint('[FLUTTER_ERROR] ${details.exception}');
        debugPrint('[FLUTTER_ERROR] ${details.stack}');
        FlutterError.presentError(details);
      };

      debugPrint('[STARTUP] setPreferredOrientations...');
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF080810),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      debugPrint('[STARTUP] calling bootstrap()...');
      await bootstrap();
      debugPrint('[STARTUP] bootstrap() returned');
    },
    (error, stack) {
      debugPrint('[ZONE_ERROR] Uncaught error: $error');
      debugPrint('[ZONE_ERROR] Stack: $stack');
    },
  );
}
