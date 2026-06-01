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
        child: Column(
          children: [
            // ── Header avec progress ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GSpacing.xl, GSpacing.lg, GSpacing.xl, 0),
              child: _OnboardingHeader(step: 1, totalSteps: 3),
            ),

            // ── Contenu scrollable ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: GSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: GSpacing.xl),

                      Text(
                        'Ton identité',
                        style: GTextStyle.displaySmall,
                      ).animate().fadeIn().slideY(
                            begin: 0.15,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: GSpacing.sm),

                      Text(
                        'Comment la communauté va te connaître',
                        style: GTextStyle.bodyLarge.copyWith(
                          color: GColors.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: GSpacing.xxl),

                      // ── Sélecteur d'avatar ───────────────────────────────
                      Center(
                        child: _AvatarPicker(
                          avatarPath: _avatarPath,
                          onTap: _pickAvatar,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                      const SizedBox(height: GSpacing.xxl),

                      // ── Pseudo ─────────────────────────────────────────
                      _SectionLabel(label: 'Pseudo'),
                      const SizedBox(height: GSpacing.sm),
                      TextFormField(
                        controller: _usernameController,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        style: GTextStyle.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'votre_pseudo',
                          prefixText: '@',
                          prefixStyle: GTextStyle.bodyLarge.copyWith(
                            color: GColors.orange,
                          ),
                          suffixIcon: _buildUsernameStatus(),
                        ),
                        validator: InputValidator.validateUsername,
                        onChanged: (v) {
                          setState(() {});
                          if (v.length >= 3) _checkUsername(v);
                        },
                      ).animate().fadeIn(delay: 300.ms),

                      // Status pseudo
                      AnimatedSize(
                        duration: GDuration.fast,
                        child: _usernameController.text.length >= 3 &&
                                !_isUsernameAvailable &&
                                !_isCheckingUsername
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(top: GSpacing.sm),
                                child: Text(
                                  'Ce pseudo est déjà utilisé',
                                  style: GTextStyle.bodySmall.copyWith(
                                      color: GColors.error),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Suggestions
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: GSpacing.sm),
                        Wrap(
                          spacing: GSpacing.sm,
                          runSpacing: GSpacing.sm,
                          children: _suggestions.map((s) {
                            return _SuggestionChip(
                              label: s,
                              onTap: () {
                                _usernameController.text = s;
                                setState(() {});
                                _checkUsername(s);
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: GSpacing.lg),

                      // ── Nom d'affichage ──────────────────────────────────
                      _SectionLabel(label: 'Nom affiché'),
                      const SizedBox(height: GSpacing.sm),
                      TextFormField(
                        controller: _displayNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        style: GTextStyle.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'Ton nom ou surnom',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nom requis';
                          }
                          if (v.length > 50) {
                            return 'Maximum 50 caractères';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: GSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bouton Continuer ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GSpacing.xl, 0, GSpacing.xl, GSpacing.lg),
              child: _ContinueButton(
                enabled: !_isCheckingUsername && _isUsernameAvailable,
                onTap: _next,
                label: 'Continuer',
              ).animate().fadeIn(delay: 500.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildUsernameStatus() {
    if (_isCheckingUsername) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(GColors.textTertiary),
          ),
        ),
      );
    }
    if (_usernameController.text.length >= 3) {
      return Icon(
        _isUsernameAvailable
            ? Icons.check_circle_outline_rounded
            : Icons.cancel_outlined,
        color: _isUsernameAvailable ? GColors.success : GColors.error,
        size: 20,
      );
    }
    return null;
  }
}

// ── Widgets helpers ───────────────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  final int step;
  final int totalSteps;

  const _OnboardingHeader({required this.step, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        Row(
          children: [
            Text(
              'Étape $step',
              style: GTextStyle.labelMedium.copyWith(
                color: GColors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' sur $totalSteps',
              style: GTextStyle.labelMedium.copyWith(
                color: GColors.textTertiary,
              ),
            ),
          ],
        ),

        const SizedBox(height: GSpacing.sm),

        // Progress bar
        Row(
          children: List.generate(totalSteps, (i) {
            final isDone = i < step;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                child: AnimatedContainer(
                  duration: GDuration.normal,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDone ? GColors.orange : GColors.border,
                    borderRadius: BorderRadius.circular(GRadius.full),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final String? avatarPath;
  final VoidCallback onTap;

  const _AvatarPicker({this.avatarPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: GColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: avatarPath != null
                    ? GColors.orange.withValues(alpha: 0.4)
                    : GColors.border,
                width: avatarPath != null ? 2.0 : 1.0,
              ),
            ),
            child: avatarPath != null
                ? ClipOval(
                    child: Image.file(
                      File(avatarPath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: GColors.textTertiary,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Photo',
                        style: GTextStyle.bodySmall.copyWith(
                          color: GColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: GColors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: GColors.void_,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GTextStyle.labelMedium.copyWith(
        color: GColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GSpacing.md,
          vertical: GSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: GColors.surface,
          borderRadius: BorderRadius.circular(GRadius.full),
          border: Border.all(color: GColors.border),
        ),
        child: Text(
          '@$label',
          style: GTextStyle.labelSmall.copyWith(
            color: GColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  final String label;

  const _ContinueButton({
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.enabled ? GColors.orange : GColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: widget.enabled
                ? null
                : Border.all(color: GColors.border),
            boxShadow: widget.enabled && !_pressed
                ? [
                    BoxShadow(
                      color: GColors.orange.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GTextStyle.buttonPrimary.copyWith(
                color: widget.enabled
                    ? GColors.textPrimary
                    : GColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
