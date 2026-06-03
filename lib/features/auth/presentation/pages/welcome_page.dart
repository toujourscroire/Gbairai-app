import 'package:flutter/material.dart';
import '../../../../diag/boot_diagnostics.dart' show bootLog;

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    bootLog('BOOT 9 — WelcomePage TEST BUILD — écran rouge visible ?');
    return const Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Text(
          'WELCOME TEST',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
          ),
        ),
      ),
    );
  }
}
