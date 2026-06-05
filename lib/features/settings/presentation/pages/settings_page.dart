import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../routing/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _biometricsEnabled = false;
  bool _notificationsEnabled = true;
  bool _loading = false;
  String _appVersion = '';
  bool _biometricsAvailable = false;

  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkBiometrics();
    _loadVersion();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _localAuth.isDeviceSupported();
      final enrolled = await _localAuth.canCheckBiometrics;
      if (mounted) {
        setState(() => _biometricsAvailable = available && enrolled);
      }
    } catch (_) {}
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason:
              'Confirme ton identité pour activer la biométrie',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!authenticated) return;
      } catch (_) {
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', value);
    setState(() => _biometricsEnabled = value);
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
    if (!value) {
      await FcmService.deleteToken();
    }
  }

  Future<void> _signOut() async {
    setState(() => _loading = true);
    // Passe par AuthController : nettoie GoogleSignIn, SecureStorage,
    // RateLimiter et met à jour l'état Riverpod correctement
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  GSpacing.xl, GSpacing.md, GSpacing.xl, 0),
              child: Row(
                children: [
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
                  const SizedBox(width: GSpacing.md),
                  Text('Paramètres', style: GTextStyle.headlineMedium),
                ],
              ),
            ),

            // ── Contenu ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(GSpacing.xl),
                children: [
                  // ── Compte ─────────────────────────────────────────────
                  _SectionHeader(label: 'Compte'),
                  const SizedBox(height: GSpacing.sm),
                  _SettingsGroup(
                    children: [
                      _SettingsRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Modifier le profil',
                        onTap: () => context.push(RouteNames.editProfile),
                      ),
                      _Separator(),
                      _SettingsRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Mot de passe',
                        onTap: () {},
                      ),
                      _Separator(),
                      _SettingsRow(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: SupabaseService.currentUser?.phone ?? '—',
                        onTap: () {},
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: GSpacing.xl),

                  // ── Sécurité ────────────────────────────────────────────
                  _SectionHeader(label: 'Sécurité'),
                  const SizedBox(height: GSpacing.sm),
                  _SettingsGroup(
                    children: [
                      if (_biometricsAvailable) ...[
                        _SettingsToggleRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'Face ID / Touch ID',
                          value: _biometricsEnabled,
                          onChanged: _toggleBiometrics,
                        ),
                        _Separator(),
                      ],
                      _SettingsRow(
                        icon: Icons.shield_outlined,
                        label: 'Confidentialité',
                        onTap: () {},
                      ),
                      _Separator(),
                      _SettingsRow(
                        icon: Icons.block_outlined,
                        label: 'Comptes bloqués',
                        onTap: () {},
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: GSpacing.xl),

                  // ── Notifications ────────────────────────────────────────
                  _SectionHeader(label: 'Notifications'),
                  const SizedBox(height: GSpacing.sm),
                  _SettingsGroup(
                    children: [
                      _SettingsToggleRow(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications push',
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                      ),
                      _Separator(),
                      _SettingsRow(
                        icon: Icons.tune_outlined,
                        label: 'Préférences',
                        onTap: () => context.push('/settings/notifications'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: GSpacing.xl),

                  // ── À propos ─────────────────────────────────────────────
                  _SectionHeader(label: 'À propos'),
                  const SizedBox(height: GSpacing.sm),
                  _SettingsGroup(
                    children: [
                      _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        label: 'Version',
                        value: _appVersion,
                        onTap: () {},
                        showArrow: false,
                      ),
                      _Separator(),
                      _SettingsRow(
                        icon: Icons.article_outlined,
                        label: 'Conditions d\'utilisation',
                        onTap: () => context.push('/legal'),
                      ),
                      _Separator(),
                      _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Politique de confidentialité',
                        onTap: () => context.push('/legal'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: GSpacing.xxl),

                  // ── Déconnexion ──────────────────────────────────────────
                  _DestructiveButton(
                    label: 'Se déconnecter',
                    isLoading: _loading,
                    onTap: _loading ? null : _signOut,
                    color: GColors.error,
                    outlined: true,
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: GSpacing.lg),

                  // ── Supprimer le compte ──────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => _confirmDeleteAccount(context),
                      child: Padding(
                        padding: const EdgeInsets.all(GSpacing.md),
                        child: Text(
                          'Supprimer mon compte',
                          style: GTextStyle.bodySmall.copyWith(
                            color: GColors.textTertiary,
                            decoration: TextDecoration.underline,
                            decorationColor: GColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GRadius.xl),
        ),
        title: const Text('Supprimer le compte ?'),
        content: const Text(
          'Cette action est irréversible. Toutes tes données seront supprimées dans 30 jours.',
          style: TextStyle(color: GColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: GTextStyle.labelLarge.copyWith(color: GColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: GColors.error,
          ),
        );
      }
    }
  }
}

// ── Composants ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GTextStyle.labelSmall.copyWith(
        color: GColors.textTertiary,
        letterSpacing: 1.0,
        fontSize: 11,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GRadius.lg),
        border: Border.all(color: GColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingsRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool showArrow;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
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
      child: AnimatedContainer(
        duration: GDuration.ultraFast,
        color: _pressed ? GColors.elevated : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md,
            vertical: GSpacing.md,
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: GColors.textSecondary, size: 20),
              const SizedBox(width: GSpacing.md),
              Expanded(
                child: Text(widget.label, style: GTextStyle.bodyLarge),
              ),
              if (widget.value != null) ...[
                Text(
                  widget.value!,
                  style: GTextStyle.bodySmall.copyWith(
                    color: GColors.textTertiary,
                  ),
                ),
                const SizedBox(width: GSpacing.sm),
              ],
              if (widget.showArrow)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: GColors.textTertiary,
                  size: 13,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GSpacing.md,
        vertical: GSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: GColors.textSecondary, size: 20),
          const SizedBox(width: GSpacing.md),
          Expanded(
            child: Text(label, style: GTextStyle.bodyLarge),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: GColors.orange,
            activeTrackColor: GColors.orange.withValues(alpha: 0.5),
            trackOutlineColor: WidgetStatePropertyAll(GColors.border),
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 52),
      color: GColors.border,
    );
  }
}

class _DestructiveButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color color;
  final bool outlined;

  const _DestructiveButton({
    required this.label,
    this.isLoading = false,
    this.onTap,
    required this.color,
    this.outlined = false,
  });

  @override
  State<_DestructiveButton> createState() => _DestructiveButtonState();
}

class _DestructiveButtonState extends State<_DestructiveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
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
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: widget.outlined
                ? Colors.transparent
                : widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(widget.color),
                    ),
                  )
                : Text(
                    widget.label,
                    style: GTextStyle.labelLarge.copyWith(
                      color: widget.color,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
