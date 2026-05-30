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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: GSpacing.xl),

                Text(
                  'Ton numéro CI',
                  style: GTextStyle.displaySmall,
                ).animate().fadeIn().slideX(begin: -0.1),

                const SizedBox(height: GSpacing.sm),

                Text(
                  'On t\'envoie un code SMS pour confirmer',
                  style: GTextStyle.bodyMedium.copyWith(
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
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: '+225 07 00 00 00 00',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('🇨🇮', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  validator: InputValidator.validateCiPhone,
                  onChanged: (_) => GHaptics.digit(),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: GSpacing.sm),

                Text(
                  'Exemple : +225 07 00 00 00 00',
                  style: GTextStyle.bodySmall,
                ).animate().fadeIn(delay: 300.ms),

                const Spacer(),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(GColors.textPrimary),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Envoyer le code'),
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
