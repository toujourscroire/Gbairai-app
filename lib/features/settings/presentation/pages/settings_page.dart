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
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      // Demander authentification avant d'activer
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Confirme ton identité pour activer la biométrie',
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
    await FcmService.deleteToken();
    await SupabaseService.client.auth.signOut();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        backgroundColor: GColors.void_,
        title: const Text('Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GSpacing.md),
        children: [
          // ── Compte ──────────────────────────────────────────────────
          _Section(
            title: 'Compte',
            children: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: 'Modifier le profil',
                onTap: () {}, // TODO: edit profile page
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                title: 'Changer de mot de passe',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.phone_outlined,
                title: 'Numéro de téléphone',
                subtitle: SupabaseService.currentUser?.phone ?? '—',
                onTap: () {},
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: GSpacing.md),

          // ── Sécurité ─────────────────────────────────────────────────
          _Section(
            title: 'Sécurité',
            children: [
              if (_biometricsAvailable)
                _SettingsToggle(
                  icon: Icons.fingerprint,
                  title: 'Face ID / Touch ID',
                  subtitle: 'Connexion biométrique',
                  value: _biometricsEnabled,
                  onChanged: _toggleBiometrics,
                ),
              _SettingsItem(
                icon: Icons.security_outlined,
                title: 'Confidentialité',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.block_outlined,
                title: 'Comptes bloqués',
                onTap: () {},
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: GSpacing.md),

          // ── Notifications ─────────────────────────────────────────────
          _Section(
            title: 'Notifications',
            children: [
              _SettingsToggle(
                icon: Icons.notifications_outlined,
                title: 'Notifications push',
                subtitle: 'Réactions, commentaires, abonnés',
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              _SettingsItem(
                icon: Icons.tune_outlined,
                title: 'Préférences notifs',
                onTap: () => context.push('/settings/notifications'),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: GSpacing.md),

          // ── À propos ─────────────────────────────────────────────────
          _Section(
            title: 'À propos',
            children: [
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: _appVersion,
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.article_outlined,
                title: 'Conditions d\'utilisation',
                onTap: () => context.push('/legal'),
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Politique de confidentialité',
                onTap: () => context.push('/legal'),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: GSpacing.xl),

          // ── Déconnexion ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _loading ? null : _signOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GColors.error),
                foregroundColor: GColors.error,
                padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: GColors.error),
                    )
                  : const Text('Se déconnecter'),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: GSpacing.xl),

          // ── Supprimer le compte ───────────────────────────────────────
          Center(
            child: TextButton(
              onPressed: () => _confirmDeleteAccount(context),
              child: Text(
                'Supprimer mon compte',
                style: GTextStyle.bodySmall.copyWith(
                  color: GColors.textTertiary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GColors.surface,
        title: const Text('Supprimer le compte ?',
            style: TextStyle(color: GColors.textPrimary)),
        content: const Text(
          'Cette action est irréversible. Toutes tes données seront supprimées dans 30 jours.',
          style: TextStyle(color: GColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: GColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: GColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // TODO: implémenter la suppression de compte via Edge Function
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Demande de suppression enregistrée. Tu recevras un email de confirmation.'),
            backgroundColor: GColors.error,
          ),
        );
      }
    }
  }
}

// ── Widgets helpers ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: GSpacing.sm, bottom: GSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: GTextStyle.labelSmall.copyWith(
              color: GColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: GColors.surface,
            borderRadius: BorderRadius.circular(GRadius.lg),
            border: Border.all(color: GColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: GColors.textSecondary),
      title: Text(title,
          style: const TextStyle(color: GColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: GColors.textSecondary, fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios,
          color: GColors.textTertiary, size: 14),
      onTap: onTap,
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: GColors.textSecondary),
      title: Text(title,
          style: const TextStyle(color: GColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: GColors.textSecondary, fontSize: 12))
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: GColors.orange,
      ),
    );
  }
}
