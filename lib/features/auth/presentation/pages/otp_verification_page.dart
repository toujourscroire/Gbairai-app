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
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
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
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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

  String get _otp =>
      _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;

    setState(() => _isLoading = true);
    await GHaptics.medium();

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyPhoneOtp(phone: widget.phone, token: _otp);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await GHaptics.success();
        final state = ref.read(authControllerProvider);
        if (state is AuthAuthenticated) {
          context.go(RouteNames.feed);
        } else if (state is AuthNeedsOnboarding) {
          context.go(RouteNames.onboardingIdentity, extra: state.authId);
        }
      } else {
        await GHaptics.error();
        // Vider les champs en cas d'erreur
        for (final c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final hasError = authState is AuthError;

    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: GSpacing.xl),

              Text(
                'Code reçu ?',
                style: GTextStyle.displaySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(),

              const SizedBox(height: GSpacing.sm),

              Text(
                'Entre le code envoyé au\n${widget.phone}',
                textAlign: TextAlign.center,
                style: GTextStyle.bodyMedium.copyWith(
                  color: GColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: GSpacing.xxl),

              // ── 6 cases OTP ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
              ).animate().fadeIn(delay: 200.ms),

              if (hasError) ...[
                const SizedBox(height: GSpacing.md),
                Text(
                  (authState as AuthError).failure.userMessage,
                  style: GTextStyle.bodySmall.copyWith(color: GColors.error),
                ).animate().shake(),
              ],

              const SizedBox(height: GSpacing.xxl),

              // Renvoyer le code
              if (_retrySeconds > 0)
                Text(
                  'Renvoyer dans ${_retrySeconds}s',
                  style: GTextStyle.bodyMedium.copyWith(
                    color: GColors.textSecondary,
                  ),
                )
              else
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .sendPhoneOtp(widget.phone);
                    _startTimer();
                  },
                  child: const Text('Renvoyer le code'),
                ),

              const Spacer(),

              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(GColors.orange),
                ),

              const SizedBox(height: GSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
