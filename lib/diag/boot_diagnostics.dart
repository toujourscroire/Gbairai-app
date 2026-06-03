import 'package:flutter/material.dart';

// Global notifier — mis à jour depuis bootstrap, app, auth_provider, welcome_page
final ValueNotifier<List<String>> bootSteps = ValueNotifier<List<String>>([]);

void bootLog(String step) {
  debugPrint(step);
  bootSteps.value = [...bootSteps.value, step];
}

// ── Overlay permanent ────────────────────────────────────────────────────────
// Rendu comme sibling de ProviderScope(GbairaiApp()) dans un Stack racine.
// Reste visible même si GbairaiApp crashe (écran noir) — affiché PAR-DESSUS.
// N'utilise pas ProviderScope, GoRouter, GColors, ni aucun asset custom.
class BootOverlay extends StatelessWidget {
  const BootOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: bootSteps,
      builder: (_, steps, __) {
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              color: const Color(0xE6080810), // 90% opaque — laisse voir l'app dessous si elle rend
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GBAIRAI — BOOT DIAGNOSTIC',
                    style: TextStyle(
                      color: Color(0xFFE85D04),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...steps.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '✓ $s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.4,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  if (steps.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFFE85D04),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'En cours...',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 11,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

