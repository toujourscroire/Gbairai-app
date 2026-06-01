import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/trends_datasource.dart';
import '../../../../shared/models/content_model.dart';

final trendsDatasourceProvider = Provider<TrendsDatasource>(
  (_) => TrendsDatasource(),
);

// Période sélectionnée (state partagé entre les widgets)
final trendsPeriodProvider =
    StateProvider<String>((ref) => 'day');

// Top trending content
final topContentProvider =
    FutureProvider.family<List<ContentModel>, String>((ref, period) {
  return ref.watch(trendsDatasourceProvider).fetchTopContent(period: period);
});

// Trending hashtags
final trendingHashtagsProvider =
    FutureProvider<List<TrendHashtag>>((ref) {
  return ref.watch(trendsDatasourceProvider).fetchTrendingHashtags();
});

// Active users count
final activeUsersProvider = FutureProvider<int>((ref) {
  return ref.watch(trendsDatasourceProvider).fetchActiveUsersCount();
});
