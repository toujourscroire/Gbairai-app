import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bootstrap.dart';
import 'diag/boot_diagnostics.dart' show bootLog;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bootLog('BOOT 0 — WidgetsFlutterBinding initialisé');

  // Lock à portrait uniquement — UX full-screen verticale
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparent pour le look iOS premium
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080810),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await bootstrap();
}
