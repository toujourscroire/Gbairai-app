extension DateTimeExtensions on DateTime {
  // Format relatif en français ivoirien
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year.toString().substring(2)}';
  }

  // Format court pour les timestamps
  String get shortTime {
    return '${hour.toString().padLeft(2, '0')}h${minute.toString().padLeft(2, '0')}';
  }
}

extension DurationExtensions on Duration {
  // Format mm:ss pour les médias
  String get mediaDuration {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
