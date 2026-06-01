import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../routing/route_names.dart';
import '../providers/auth_provider.dart';
import '../widgets/otp_input_field.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String phone;
  const OtpVerificationPage({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _retrySeconds = 30;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _retrySeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_retrySeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _retrySeconds--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;

    setState(() => _isLoading = true);
    await GHaptics.medium();

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyPhoneOtp(phone: widget.phone, token: _otp);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      await GHaptics.success();
      final state = ref.read(authControllerProvider);
      if (!mounted) return;
      if (state is AuthAuthenticated) {
        context.go(RouteNames.feed);
      } else if (state is AuthNeedsOnboarding) {
        context.go(RouteNames.onboardingIdentity, extra: state.authId);
      }
    } else {
      await GHaptics.error();
      for (final c in _controllers) {
        c.clear();
      }
      if (mounted) _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final hasError = authState is AuthError;

    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ──────────────────────────────────────────
              const SizedBox(height: GSpacing.md),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GColors.surface,
                    borderRadius: BorderRadius.circular(GRadius.md),
                    border: Border.all(color: GColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: GColors.textPrimary,
                    size: 16,
                  ),
                ),
              ),

              const SizedBox(height: GSpacing.xxl),

              // ── Titre ─────────────────────────────────────────────────
              Text(
                'Vérifie ton\ntéléphone',
                style: GTextStyle.displaySmall,
              ).animate().fadeIn().slideY(
                    begin: 0.15,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: GSpacing.sm),

              RichText(
                text: TextSpan(
                  style: GTextStyle.bodyLarge.copyWith(
                    color: GColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Code envoyé au '),
                    TextSpan(
                      text: widget.phone,
                      style: GTextStyle.bodyLarge.copyWith(
                        color: GColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: GSpacing.xxl),

              // ── Champs OTP ────────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: OtpInputField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        hasError: hasError,
                        onChanged: (value) {
                          GHaptics.digit();
                          if (value.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (value.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          if (_otp.length == 6) _verify();
                        },
                      ),
                    );
                  }),
                ),
              ).animate().fadeIn(delay: 200.ms),

              // Message d'erreur
              AnimatedSize(
                duration: GDuration.fast,
                child: authState is AuthError
                    ? Padding(
                        padding: const EdgeInsets.only(top: GSpacing.md),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GSpacing.md,
                              vertical: GSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: GColors.error.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(GRadius.md),
                              border: Border.all(
                                color: GColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: GColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: GSpacing.sm),
                                Text(
                                  'Code incorrect — réessaie',
                                  style: GTextStyle.bodySmall.copyWith(
                                    color: GColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: GSpacing.xxl),

              // ── Renvoyer le code ──────────────────────────────────────
              Center(
                child: _retrySeconds > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Renvoyer dans ',
                            style: GTextStyle.bodyMedium.copyWith(
                              color: GColors.textTertiary,
                            ),
                          ),
                          Text(
                            '${_retrySeconds}s',
                            style: GTextStyle.bodyMedium.copyWith(
                              color: GColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .sendPhoneOtp(widget.phone);
                          _startTimer();
                        },
                        child: Text(
                          'Renvoyer le code',
                          style: GTextStyle.labelLarge.copyWith(
                            color: GColors.orange,
                          ),
                        ),
                      ),
              ).animate().fadeIn(delay: 400.ms),

              const Spacer(),

              // ── Loading ───────────────────────────────────────────────
              if (_isLoading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(GSpacing.md),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(GColors.orange),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: GSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
