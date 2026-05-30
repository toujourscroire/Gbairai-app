import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/animations/haptic_service.dart';
import '../../../../core/services/security/input_validator.dart';
import '../../../../routing/route_names.dart';
import '../providers/auth_provider.dart';

class EmailAuthPage extends ConsumerStatefulWidget {
  const EmailAuthPage({super.key});

  @override
  ConsumerState<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends ConsumerState<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await GHaptics.medium();

    final success = await ref.read(authControllerProvider.notifier).signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        final state = ref.read(authControllerProvider);
        if (state is AuthAuthenticated) context.go(RouteNames.feed);
        if (state is AuthNeedsOnboarding) {
          context.go(RouteNames.onboardingIdentity, extra: state.authId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: GSpacing.xl),

                Text(
                  _isSignUp ? 'Crée ton compte' : 'Content de te revoir',
                  style: GTextStyle.displaySmall,
                ).animate().fadeIn(),

                const SizedBox(height: GSpacing.xxl),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline, color: GColors.textSecondary),
                  ),
                  validator: InputValidator.validateEmail,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: GSpacing.md),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline, color: GColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: GColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _isSignUp ? InputValidator.validatePassword : (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms),

                if (authState is AuthError) ...[
                  const SizedBox(height: GSpacing.md),
                  Text(
                    authState.failure.userMessage,
                    style: GTextStyle.bodySmall.copyWith(color: GColors.error),
                  ).animate().shake(),
                ],

                const SizedBox(height: GSpacing.xl),

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
                      : Text(_isSignUp ? 'Créer mon compte' : 'Connexion'),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: GSpacing.md),

                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'J\'ai déjà un compte'
                          : 'Créer un compte email',
                      style: GTextStyle.labelMedium.copyWith(
                        color: GColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
