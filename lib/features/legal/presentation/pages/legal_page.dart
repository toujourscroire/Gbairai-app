import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design/design_tokens.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static const _privacyUrl = 'https://gbairai.ci/privacy';
  static const _termsUrl = 'https://gbairai.ci/terms';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Légal')),
      body: ListView(
        padding: const EdgeInsets.all(GSpacing.lg),
        children: [
          _LegalTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            subtitle: 'Comment nous utilisons vos données',
            onTap: () => _launch(_privacyUrl),
          ),
          const SizedBox(height: GSpacing.md),
          _LegalTile(
            icon: Icons.gavel_outlined,
            title: "Conditions générales d'utilisation",
            subtitle: 'Règles et engagements de la plateforme',
            onTap: () => _launch(_termsUrl),
          ),
          const SizedBox(height: GSpacing.xl),
          Text(
            'Gbairai — Le Radar Social Ivoirien\n'
            'Données hébergées en Europe (Supabase EU)\n'
            'Conformité RGPD & législation ivoirienne',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: GColors.textTertiary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: GColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GRadius.md)),
      leading: Icon(icon, color: GColors.orange),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: GColors.textSecondary)),
      trailing: const Icon(Icons.open_in_new, size: 16, color: GColors.textTertiary),
      onTap: onTap,
    );
  }
}
