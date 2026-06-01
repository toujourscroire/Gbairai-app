import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_tokens.dart';
import '../providers/creation_provider.dart';

// Fonds disponibles pour les statuts texte
const _textBackgrounds = [
  ('gradient_1', [Color(0xFFE85D04), Color(0xFF9B2226)]),
  ('gradient_2', [Color(0xFF7C3AED), Color(0xFFDB2777)]),
  ('gradient_3', [Color(0xFF0891B2), Color(0xFF059669)]),
  ('gradient_4', [Color(0xFF1D4ED8), Color(0xFF7C3AED)]),
  ('gradient_5', [Color(0xFF064E3B), Color(0xFF065F46)]),
  ('noir', [Color(0xFF0D0D0D), Color(0xFF1A1A2E)]),
];

const _cities = [
  'Abidjan', 'Yamoussoukro', 'Bouaké', 'Daloa',
  'Korhogo', 'San-Pédro', 'Man', 'Gagnoa',
];

class CreateTextPage extends ConsumerStatefulWidget {
  const CreateTextPage({super.key});

  @override
  ConsumerState<CreateTextPage> createState() => _CreateTextPageState();
}

class _CreateTextPageState extends ConsumerState<CreateTextPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String _selectedBg = 'gradient_1';
  String _selectedCity = 'Abidjan';
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Color> get _bgColors {
    return _textBackgrounds
        .firstWhere((b) => b.$1 == _selectedBg,
            orElse: () => _textBackgrounds.first)
        .$2;
  }

  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#\w+');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  Future<void> _publish() async {
    final caption = _controller.text.trim();
    if (caption.isEmpty) return;

    final hashtags = _extractHashtags(caption);

    await ref.read(creationProvider.notifier).publishText(
          caption: caption,
          textFont: 'inter',
          textSize: 'normal',
          textBackground: _selectedBg,
          isAnonymous: _isAnonymous,
          city: _selectedCity,
          hashtags: hashtags,
        );

    final state = ref.read(creationProvider);
    if (!mounted) return;

    if (state is PublicationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔥 Ton Gbairai est en cours de validation !'),
          backgroundColor: GColors.orange,
        ),
      );
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creationProvider);
    final isLoading = state is PublicationLoading;
    final charCount = _controller.text.length;

    ref.listen<PublicationState>(creationProvider, (_, next) {
      if (next is PublicationError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: GColors.error,
          ),
        );
        ref.read(creationProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: GColors.void_,
      appBar: AppBar(
        backgroundColor: GColors.void_,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isLoading ? null : () => context.pop(),
        ),
        title: const Text('Statut'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: GSpacing.md),
            child: TextButton(
              onPressed: isLoading || _controller.text.trim().isEmpty
                  ? null
                  : _publish,
              style: TextButton.styleFrom(
                backgroundColor: GColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: GSpacing.lg, vertical: GSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GRadius.full),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publier'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Prévisualisation fond coloré ─────────────────────────────
          Expanded(
            child: AnimatedContainer(
              duration: 300.ms,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _bgColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(GSpacing.xl),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (_) => setState(() {}),
                    maxLength: 280,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'Écris ton Gbairai…',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Barre d'outils ───────────────────────────────────────────
          Container(
            color: GColors.surface,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compteur caractères
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: GSpacing.md, vertical: GSpacing.sm),
                    child: Row(
                      children: [
                        Text(
                          '$charCount/280',
                          style: GTextStyle.bodySmall.copyWith(
                            color: charCount > 250
                                ? GColors.error
                                : GColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        // Anonyme switch
                        Row(
                          children: [
                            Text('Anonyme',
                                style: GTextStyle.bodySmall
                                    .copyWith(color: GColors.textSecondary)),
                            const SizedBox(width: GSpacing.sm),
                            Switch.adaptive(
                              value: _isAnonymous,
                              onChanged: (v) =>
                                  setState(() => _isAnonymous = v),
                              activeColor: GColors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sélecteur de fond
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: GSpacing.md),
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: GSpacing.sm),
                      itemCount: _textBackgrounds.length,
                      itemBuilder: (_, i) {
                        final bg = _textBackgrounds[i];
                        final isSelected = bg.$1 == _selectedBg;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedBg = bg.$1),
                          child: AnimatedContainer(
                            duration: 150.ms,
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: bg.$2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Ville
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: GSpacing.md, vertical: GSpacing.sm),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      dropdownColor: GColors.elevated,
                      style: GTextStyle.bodySmall
                          .copyWith(color: GColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: GColors.textSecondary, size: 18),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(GRadius.md),
                          borderSide:
                              const BorderSide(color: GColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(GRadius.md),
                          borderSide:
                              const BorderSide(color: GColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: GSpacing.sm),
                        isDense: true,
                      ),
                      items: _cities
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCity = v ?? _selectedCity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
