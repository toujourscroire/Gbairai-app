import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/glassmorphism.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../shared/models/content_model.dart';
import 'content_actions_column.dart';
import 'content_info_row.dart';

const _coverColors = {
  'orange': [GColors.orange, Color(0xFF9B2226)],
  'black':  [GColors.elevated, GColors.surface],
  'purple': [Color(0xFF7C3AED), Color(0xFF4C1D95)],
  'blue':   [Color(0xFF0891B2), Color(0xFF1E3A5F)],
  'green':  [Color(0xFF059669), Color(0xFF064E3B)],
  'gold':   [GColors.gold, Color(0xFF78350F)],
  'red':    [GColors.red, Color(0xFF7F1D1D)],
  'teal':   [Color(0xFF0D9488), Color(0xFF134E4A)],
};

class AudioContentCard extends StatefulWidget {
  final ContentModel content;
  final bool isActive;
  final ValueChanged<String> onReact;

  const AudioContentCard({
    super.key,
    required this.content,
    required this.isActive,
    required this.onReact,
  });

  @override
  State<AudioContentCard> createState() => _AudioContentCardState();
}

class _AudioContentCardState extends State<AudioContentCard>
    with SingleTickerProviderStateMixin {
  AudioPlayer? _player;
  late AnimationController _waveController;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isActive) _initPlayer();
  }

  @override
  void didUpdateWidget(AudioContentCard old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _initPlayer();
    if (!widget.isActive && old.isActive) _player?.pause();
  }

  Future<void> _initPlayer() async {
    if (widget.content.mediaUrl == null) return;
    _player = AudioPlayer();
    await _player!.setUrl(widget.content.mediaUrl!);
    _player!.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player!.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
    _player!.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if (state.playing) {
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
      }
    });
    await _player!.play();
  }

  @override
  void dispose() {
    _player?.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _coverColors[widget.content.voiceCoverBg] ??
        _coverColors['orange']!;

    return GestureDetector(
      onDoubleTap: () => widget.onReact('gbairai'),
      child: Stack(
        children: [
          // ── Fond cover ────────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
          ),

          // ── Visualiseur d'ondes ───────────────────────────────────────
          Center(
            child: _WaveformVisualizer(
              controller: _waveController,
              isPlaying: _isPlaying,
              color: GColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),

          // ── Titre du vocal ────────────────────────────────────────────
          if (widget.content.voiceTitle != null)
            Positioned(
              top: 80,
              left: GSpacing.xl,
              right: GSpacing.xl,
              child: Text(
                widget.content.voiceTitle!,
                textAlign: TextAlign.center,
                style: GTextStyle.headlineMedium.copyWith(
                  shadows: [const Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
            ),

          // ── Bouton Play/Pause central ─────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: () {
                if (_isPlaying) {
                  _player?.pause();
                } else {
                  _player?.play();
                }
              },
              child: GlassCard(
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(GRadius.full),
                padding: EdgeInsets.zero,
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                  color: GColors.textPrimary,
                  size: 36,
                ),
              ),
            ),
          ),

          // ── Barre de progression ──────────────────────────────────────
          Positioned(
            bottom: 100,
            left: GSpacing.xl,
            right: GSpacing.xl,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0,
                  backgroundColor: GColors.textPrimary.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(GColors.textPrimary),
                  minHeight: 2,
                ),
                const SizedBox(height: GSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _position.mediaDuration,
                      style: GTextStyle.bodySmall,
                    ),
                    Text(
                      _duration.mediaDuration,
                      style: GTextStyle.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Actions droite ─────────────────────────────────────────────
          Positioned(
            right: GSpacing.md,
            bottom: 120,
            child: ContentActionsColumn(
              content: widget.content,
              onReact: widget.onReact,
            ),
          ),

          // ── Info bas-gauche ────────────────────────────────────────────
          Positioned(
            left: GSpacing.md,
            right: 80,
            bottom: GSpacing.xxl,
            child: ContentInfoRow(content: widget.content),
          ),
        ],
      ),
    );
  }
}

class _WaveformVisualizer extends AnimatedWidget {
  final bool isPlaying;
  final Color color;

  const _WaveformVisualizer({
    required AnimationController controller,
    required this.isPlaying,
    required this.color,
  }) : super(listenable: controller);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (i) {
          final phase = (i / 20) * 3.14159;
          final height = isPlaying
              ? 8.0 + 40.0 * (0.5 + 0.5 * (1 + _animation.value * phase.abs()).clamp(0, 1))
              : 8.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(GRadius.full),
              ),
            ),
          );
        }),
      ),
    );
  }
}
