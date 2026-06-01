import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../core/services/security/input_validator.dart';
import '../../../../routing/route_names.dart';
import '../providers/auth_provider.dart';

class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+225 ');
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Normaliser le numéro
    final phone = _phoneController.text
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    setState(() => _isLoading = true);
    await GHaptics.medium();

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPhoneOtp(phone);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.push(RouteNames.authOtp, extra: phone);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: GSpacing.md),
                // Back button
                _BackButton(onTap: () => context.pop()),
                const SizedBox(height: GSpacing.xl),

                Text(
                  'Ton numéro',
                  style: GTextStyle.displaySmall,
                ).animate().fadeIn().slideY(
                      begin: 0.15,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: GSpacing.sm),

                Text(
                  'On t\'envoie un code SMS pour confirmer',
                  style: GTextStyle.bodyLarge.copyWith(
                    color: GColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: GSpacing.xxl),

                // ── Champ téléphone ──────────────────────────────────
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s]')),
                    LengthLimitingTextInputFormatter(17),
                  ],
                  autofocus: true,
                  style: GTextStyle.headlineMedium.copyWith(
                    letterSpacing: 3,
                    color: GColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '+225 07 00 00 00 00',
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: GSpacing.md),
                      child: Icon(
                        Icons.phone_outlined,
                        color: GColors.orange,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 52),
                  ),
                  validator: InputValidator.validateCiPhone,
                  onChanged: (_) => GHaptics.digit(),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: GSpacing.sm),

                Text(
                  'Format : +225 07 00 00 00 00',
                  style: GTextStyle.bodySmall.copyWith(
                    color: GColors.textTertiary,
                    fontSize: 12,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const Spacer(),

                _SubmitButton(
                  isLoading: _isLoading,
                  onTap: _isLoading ? null : _submit,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: GSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _SubmitButton({required this.isLoading, this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFFD45500) : GColors.orange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: GColors.orange.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(GColors.textPrimary),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Envoyer le code',
                    style: GTextStyle.buttonPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
