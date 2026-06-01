/// Service Cloudflare Stream
/// Construit les URLs HLS et thumbnail à partir d'un stream_id.
///
/// CLOUDFLARE_CUSTOMER_CODE est injecté via dart-define par Codemagic.
/// En local (sans dart-define) : retourne null → le player utilise mediaUrl.
class CloudflareService {
  static const _customerCode = String.fromEnvironment('CLOUDFLARE_CUSTOMER_CODE');

  static bool get isConfigured => _customerCode.isNotEmpty;

  /// URL HLS pour VideoPlayerController
  static String? hlsUrl(String? streamId) {
    if (streamId == null || streamId.isEmpty || !isConfigured) return null;
    return 'https://customer-$_customerCode.cloudflarestream.com/$streamId/manifest/video.m3u8';
  }

  /// URL thumbnail (frame à 0s)
  static String? thumbnailUrl(String? streamId) {
    if (streamId == null || streamId.isEmpty || !isConfigured) return null;
    return 'https://customer-$_customerCode.cloudflarestream.com/$streamId/thumbnails/thumbnail.jpg?time=0s&height=480';
  }

  /// Résout la meilleure URL vidéo à utiliser
  /// Priorité : HLS Cloudflare > mediaUrl
  static String? resolveVideoUrl({String? streamId, String? mediaUrl}) {
    return hlsUrl(streamId) ?? mediaUrl;
  }
}
