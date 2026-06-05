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
    debugPrint('[WELCOME] WelcomePage.build() called ✅');
    return Scaffold(
      backgroundColor: GColors.void_,
      body: Stack(
        children: [
          // Fond subtil — deux sources lumineuses statiques
          const _SubtleBackground(),

          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo + Identité ───────────────────────────────────────
                Column(
                  children: [
                    // Lettermark "G"
                    _GbairaiLettermark()
                        .animate()
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: GSpacing.xl),

                    // Nom de l'app
                    Text(
                      'Gbairai',
                      style: GTextStyle.displayMedium.copyWith(
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(
                          begin: 0.2,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: GSpacing.sm),

                    // Tagline
                    Text(
                      'Abidjan brûle.\nTu regardes où ?',
                      textAlign: TextAlign.center,
                      style: GTextStyle.bodyLarge.copyWith(
                        color: GColors.textSecondary,
                        height: 1.7,
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  ],
                ),

                const Spacer(flex: 3),

                // ── Actions ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: GSpacing.xl),
                  child: Column(
                    children: [
                      // Bouton principal
                      _PrimaryButton(
                        label: 'Rejoindre Gbairai',
                        onTap: () => context.go(RouteNames.authChoice),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 400.ms)
                          .slideY(
                            begin: 0.3,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: GSpacing.md),

                      // Lien secondaire
                      GestureDetector(
                        onTap: () => context.go(RouteNames.authEmail),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: GSpacing.sm),
                          child: Text(
                            'J\'ai déjà un compte',
                            style: GTextStyle.labelLarge.copyWith(
                              color: GColors.textSecondary,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

                      const SizedBox(height: GSpacing.xl),

                      // CGU
                      _LegalText().animate().fadeIn(delay: 1000.ms),

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

// ── Fond subtil avec deux orbes de lumière ───────────────────────────────────

class _SubtleBackground extends StatelessWidget {
  const _SubtleBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _BackgroundPainter(),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Orbe 1 — ambre chaud, haut droit
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE85D04).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.15),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.55,
      paint1,
    );

    // Orbe 2 — bleu nuit très subtil, bas gauche
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B4FFF).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.85),
          radius: size.width * 0.6,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      size.width * 0.6,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Lettermark "G" premium ───────────────────────────────────────────────────

class _GbairaiLettermark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GRadius.xl),
        border: Border.all(
          color: GColors.orange.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: GColors.orange.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF8C42),
              Color(0xFFE85D04),
            ],
          ).createShader(bounds),
          child: const Text(
            'G',
            style: TextStyle(
              fontFamily: GFont.sora,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
              letterSpacing: -1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bouton primaire custom ───────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _pressed
                ? const Color(0xFFD45500)
                : GColors.orange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: GColors.orange.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GTextStyle.buttonPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Texte légal ──────────────────────────────────────────────────────────────

class _LegalText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'En continuant, vous acceptez nos ',
        style: GTextStyle.bodySmall.copyWith(
          color: GColors.textTertiary,
          fontSize: 11,
        ),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://gbairai.ci/terms'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                'CGU',
                style: GTextStyle.bodySmall.copyWith(
                  fontSize: 11,
                  color: GColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: GColors.textSecondary,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' et la '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://gbairai.ci/privacy'),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                'Politique de confidentialité',
                style: GTextStyle.bodySmall.copyWith(
                  fontSize: 11,
                  color: GColors.textSecondary,
                  decoration: TextDecoration.underline,
                  decorationColor: GColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
