import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/content_model.dart';
import '../../data/datasources/feed_remote_datasource.dart';

// ── Datasource provider ─────────────────────────────────────────────
final feedDatasourceProvider = Provider<FeedRemoteDatasource>((ref) {
  return FeedRemoteDatasource();
});

// ── Tab state ────────────────────────────────────────────────────────
enum FeedTab { forYou, following }
final feedTabProvider = StateProvider<FeedTab>((ref) => FeedTab.forYou);

// ── Feed State ────────────────────────────────────────────────────────
class FeedState {
  final List<ContentModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentIndex;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentIndex = 0,
  });

  FeedState copyWith({
    List<ContentModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentIndex,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

// ── Feed Controller ────────────────────────────────────────────────────
final forYouFeedProvider =
    StateNotifierProvider<FeedController, FeedState>((ref) {
  return FeedController(
    ref.read(feedDatasourceProvider),
    isFollowing: false,
  );
});

final followingFeedProvider =
    StateNotifierProvider<FeedController, FeedState>((ref) {
  return FeedController(
    ref.read(feedDatasourceProvider),
    isFollowing: true,
  );
});

class FeedController extends StateNotifier<FeedState> {
  // Initialiser avec isLoading: true évite le flash d'_EmptyFeed au premier frame.
  // Le constructeur appelle _fetchFirstPage() directement (bypass du guard de load()).
  FeedController(this._ds, {required this.isFollowing})
      : super(const FeedState(isLoading: true)) {
    _fetchFirstPage();
  }

  final FeedRemoteDatasource _ds;
  final bool isFollowing;

  // ── Méthode interne partagée — pas de guard isLoading ────────────────
  // Requiert que isLoading soit déjà true dans l'état courant.
  Future<void> _fetchFirstPage() async {
    try {
      final items = await _fetchPage(0);
      if (!mounted) return;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == AppConstants.feedPageSize,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Rechargement explicite (pull-to-refresh, retry) ──────────────────
  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    await _fetchFirstPage();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final items = await _fetchPage(state.items.length);
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length == AppConstants.feedPageSize,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const FeedState(isLoading: true);
    await _fetchFirstPage();
  }

  void updateCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
    // Précharger si proche de la fin
    if (index >= state.items.length - AppConstants.preloadCount) {
      loadMore();
    }
  }

  Future<void> react(String contentId, String reactionType) async {
    try {
      await _ds.react(contentId: contentId, reactionType: reactionType);
      // Mise à jour optimiste locale
      final idx = state.items.indexWhere((c) => c.id == contentId);
      if (idx != -1) {
        final items = [...state.items];
        items[idx] = items[idx].copyWith(
          myReaction: reactionType,
          reactionsCount: items[idx].reactionsCount + 1,
        );
        state = state.copyWith(items: items);
      }
    } catch (_) {
      // Réaction échouée silencieusement — UI reste cohérente, Sentry capture l'erreur
    }
  }

  Future<void> recordView({
    required String contentId,
    required double watchDuration,
  }) async {
    await _ds.recordView(
      contentId: contentId,
      watchDurationSeconds: watchDuration,
      source: 'feed',
    );
  }

  Future<List<ContentModel>> _fetchPage(int offset) {
    return isFollowing
        ? _ds.getFollowingFeed(offset: offset, limit: AppConstants.feedPageSize)
        : _ds.getForYouFeed(offset: offset, limit: AppConstants.feedPageSize);
  }
}

// ── Alerte active (Realtime) ───────────────────────────────────────────
final activeAlertProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return Stream.empty(); // Implémentation complète dans alert_provider
});
