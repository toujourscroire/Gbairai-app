import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/design/design_tokens.dart';
import '../../../../core/design/glassmorphism.dart';
import '../../../../core/services/cloudflare_service.dart';
import '../../../../shared/models/content_model.dart';
import 'comment_sheet.dart';
import 'content_actions_column.dart';
import 'content_info_row.dart';
import 'voice_reaction_sheet.dart';

class VideoContentCard extends StatefulWidget {
  final ContentModel content;
  final bool isActive;
  final ValueChanged<String> onReact;

  const VideoContentCard({
    super.key,
    required this.content,
    required this.isActive,
    required this.onReact,
  });

  @override
  State<VideoContentCard> createState() => _VideoContentCardState();
}

class _VideoContentCardState extends State<VideoContentCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initPlayer();
  }

  @override
  void didUpdateWidget(VideoContentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initPlayer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _initPlayer() async {
    final url = CloudflareService.resolveVideoUrl(
      streamId: widget.content.streamId,
      mediaUrl: widget.content.mediaUrl,
    );
    if (url == null) return;

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: const {
        'User-Agent': 'Gbairai/1.0 Flutter',
      },
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() => _initialized = true);
      unawaited(_controller!.setLooping(true));
      unawaited(_controller!.play());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _showVoiceReactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceReactionSheet(contentId: widget.content.id),
    );
  }

  void _togglePlay() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      onDoubleTap: () => widget.onReact('gbairai'),
      child: Stack(
        children: [
          // ── Vidéo plein écran ────────────────────────────────────────
          Positioned.fill(
            child: _initialized && _controller != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : Container(
                    color: GColors.black,
                    child: widget.content.thumbnailUrl != null
                        ? Image.network(
                            widget.content.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _VideoPlaceholder(),
                          )
                        : const _VideoPlaceholder(),
                  ),
          ),

          // ── Gradient overlay ─────────────────────────────────────────
          const Positioned.fill(child: VideoGradientOverlay()),

          // ── Barre de progression ─────────────────────────────────────
          if (_initialized && _controller != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: GColors.orange,
                  bufferedColor: GColors.orange.withValues(alpha: 0.3),
                  backgroundColor: GColors.border,
                ),
                padding: EdgeInsets.zero,
              ),
            ),

          // ── Pause indicator ──────────────────────────────────────────
          if (_initialized &&
              _controller != null &&
              !_controller!.value.isPlaying)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: GColors.glassBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: GColors.textPrimary,
                  size: 36,
                ),
              ),
            ),

          // ── Actions droite ────────────────────────────────────────────
          Positioned(
            right: GSpacing.md,
            bottom: 120,
            child: ContentActionsColumn(
              content: widget.content,
              onReact: widget.onReact,
              onComment: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CommentSheet(contentId: widget.content.id),
              ),
              onVoiceReact: () => _showVoiceReactionSheet(context),
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

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GColors.surface,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: GColors.textTertiary, size: 60),
      ),
    );
  }
}
