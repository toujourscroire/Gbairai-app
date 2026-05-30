import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/design/design_tokens.dart';
import '../../../../../core/design/animations/haptic_service.dart';
import '../../../../../core/services/security/input_validator.dart';
import '../../../../../core/utils/nouchi_generator.dart';
import '../../../../../routing/route_names.dart';
import '../../providers/auth_provider.dart';

class IdentityPage extends ConsumerStatefulWidget {
  final String authId;
  const IdentityPage({super.key, required this.authId});

  @override
  ConsumerState<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends ConsumerState<IdentityPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  String? _avatarPath;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _suggestions = NouchiGenerator.generateSuggestions('Gbairai');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String value) async {
    if (value.length < 3) return;
    setState(() => _isCheckingUsername = true);
    final ds = ref.read(authDatasourceProvider);
    final available = await ds.isUsernameAvailable(value);
    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = available;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (image != null) setState(() => _avatarPath = image.path);
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isUsernameAvailable) return;
    GHaptics.medium();
    context.push(
      RouteNames.onboardingInterests,
      extra: {
        'authId': widget.authId,
        'username': _usernameController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'avatarPath': _avatarPath,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: GSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: GSpacing.xl),

                // Progress
                _OnboardingProgress(step: 1),

                const SizedBox(height: GSpacing.xl),

                Text(
                  'C\'est qui toi ?',
                  style: GTextStyle.displaySmall,
                ).animate().fadeIn().slideX(begin: -0.1),

                const SizedBox(height: GSpacing.sm),

                Text(
                  'Crée ton identité Gbairai',
                  style: GTextStyle.bodyMedium.copyWith(
                    color: GColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: GSpacing.xxl),

                // ── Avatar ─────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: GColors.surface,
                          backgroundImage: _avatarPath != null
                              ? FileImage(File(_avatarPath!))
                              : null,
                          child: _avatarPath == null
                              ? const Text('📸', style: TextStyle(fontSize: 36))
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: GColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: GColors.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),

                const SizedBox(height: GSpacing.xl),

                // ── Pseudo ─────────────────────────────────────────────
                TextFormField(
                  controller: _usernameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Pseudo (@)',
                    prefixText: '@',
                    prefixStyle: GTextStyle.bodyLarge.copyWith(
                      color: GColors.orange,
                    ),
                    suffixIcon: _isCheckingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameController.text.length >= 3
                            ? Icon(
                                _isUsernameAvailable
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _isUsernameAvailable
                                    ? GColors.success
                                    : GColors.error,
                              )
                            : null,
                  ),
                  validator: InputValidator.validateUsername,
                  onChanged: (v) {
                    setState(() {});
                    if (v.length >= 3) _checkUsername(v);
                  },
                ).animate().fadeIn(delay: 300.ms),

                if (!_isUsernameAvailable) ...[
                  const SizedBox(height: GSpacing.sm),
                  Text(
                    'Pseudo déjà pris — essaie un autre',
                    style: GTextStyle.bodySmall.copyWith(color: GColors.error),
                  ),
                ],

                // Suggestions
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: GSpacing.sm),
                  Wrap(
                    spacing: GSpacing.sm,
                    children: _suggestions.map((s) {
                      return GestureDetector(
                        onTap: () {
                          _usernameController.text = s;
                          _checkUsername(s);
                        },
                        child: Chip(
                          label: Text(s, style: GTextStyle.labelSmall),
                          backgroundColor: GColors.surface,
                          side: const BorderSide(color: GColors.border),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: GSpacing.md),

                // ── Nom d'affichage ────────────────────────────────────
                TextFormField(
                  controller: _displayNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'affichage',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nom requis';
                    if (v.length > 50) return 'Maximum 50 caractères';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: GSpacing.xxl),

                ElevatedButton(
                  onPressed: _isCheckingUsername ? null : _next,
                  child: const Text('Continuer'),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: GSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  final int step;
  const _OnboardingProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i < step;
        final isCurrent = i == step - 1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: GDuration.normal,
              height: 4,
              decoration: BoxDecoration(
                color: isActive || isCurrent
                    ? GColors.orange
                    : GColors.border,
                borderRadius: BorderRadius.circular(GRadius.full),
                boxShadow: isCurrent ? GShadow.orangeGlow : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
