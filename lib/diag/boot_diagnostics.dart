import 'package:flutter/material.dart';

// Global notifier — mis à jour depuis bootstrap, app, auth_provider, welcome_page
final ValueNotifier<List<String>> bootSteps = ValueNotifier<List<String>>([]);

void bootLog(String step) {
  debugPrint(step);
  bootSteps.value = [...bootSteps.value, step];
}

// Affiché avant runApp(GbairaiApp) — montre chaque étape en temps réel
class BootDiagnosticApp extends StatelessWidget {
  const BootDiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF080810),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ValueListenableBuilder<List<String>>(
              valueListenable: bootSteps,
              builder: (_, steps, __) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GBAIRAI — BOOT DIAGNOSTIC',
                      style: TextStyle(
                        color: Color(0xFFE85D04),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: const Color(0xFF2A2A3A),
                    ),
                    const SizedBox(height: 16),
                    if (steps.isEmpty)
                      const Text(
                        'Démarrage...',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      ...steps.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '✓ ',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Indicateur d'activité si dernier step en cours
                    if (steps.isNotEmpty)
                      const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE85D04),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'En attente...',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
