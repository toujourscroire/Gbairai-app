import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../routing/route_names.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      body: Stack(
        children: [
          // Fond vidéo / gradient dynamique
          const _AnimatedBackground(),

          // Contenu
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Logo Gbairai
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: GColors.orange,
                        borderRadius: BorderRadius.circular(GRadius.xl),
                        boxShadow: GShadow.orangeGlow,
                      ),
                      child: const Center(
                        child: Text(
                          '⚡',
                          style: TextStyle(fontSize: 40),
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1200.ms),

                    const SizedBox(height: GSpacing.lg),

                    Text(
                      'GBAIRAI',
                      style: GTextStyle.displayMedium.copyWith(
                        color: GColors.textPrimary,
                        letterSpacing: 4.0,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

                    const SizedBox(height: GSpacing.sm),

                    Text(
                      'Abidjan brûle.\nTu regardes où ?',
                      textAlign: TextAlign.center,
                      style: GTextStyle.bodyLarge.copyWith(
                        color: GColors.textSecondary,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),

                const Spacer(),

                // CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go(RouteNames.authChoice),
                        child: const Text('Rejoindre Gbairai'),
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.5),

                      const SizedBox(height: GSpacing.md),

                      TextButton(
                        onPressed: () => context.go(RouteNames.authEmail),
                        child: Text(
                          'J\'ai déjà un compte',
                          style: GTextStyle.labelLarge.copyWith(
                            color: GColors.textSecondary,
                          ),
                        ),
                      ).animate().fadeIn(delay: 900.ms),

                      const SizedBox(height: GSpacing.md),

                      // CGU & Confidentialité
                      Text.rich(
                        TextSpan(
                          text: 'En continuant, vous acceptez nos ',
                          style: GTextStyle.bodySmall.copyWith(
                            color: GColors.textTertiary,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => launchUrl(Uri.parse('https://gbairai.ci/terms')),
                                child: Text(
                                  'CGU',
                                  style: GTextStyle.bodySmall.copyWith(
                                    color: GColors.orange,
                                    decoration: TextDecoration.underline,
                                    decorationColor: GColors.orange,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' et notre '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => launchUrl(Uri.parse('https://gbairai.ci/privacy')),
                                child: Text(
                                  'Politique de confidentialité',
                                  style: GTextStyle.bodySmall.copyWith(
                                    color: GColors.orange,
                                    decoration: TextDecoration.underline,
                                    decorationColor: GColors.orange,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 1000.ms),

                      const SizedBox(height: GSpacing.lg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 0.8,
            colors: [
              GColors.orange.withValues(alpha: _pulse.value),
              GColors.void_,
            ],
          ),
        ),
      ),
    );
  }
}
