enum NetworkKind { wifi, cellular, offline, unknown }

abstract class NetworkKindSource {
  Future<NetworkKind> current();
}

class FixedNetworkKind implements NetworkKindSource {
  FixedNetworkKind(this.kind);

  final NetworkKind kind;

  @override
  Future<NetworkKind> current() async => kind;
}

abstract class VideoFileStore {
  Future<String?> existingPath(String id);
  Future<String> write(String id, List<int> bytes);
}

class MemoryVideoFileStore implements VideoFileStore {
  final Map<String, String> _paths = {};

  @override
  Future<String?> existingPath(String id) async => _paths[id];

  @override
  Future<String> write(String id, List<int> bytes) async {
    final path = 'memory://$id';
    _paths[id] = path;
    return path;
  }
}

typedef VideoFetcher = Future<List<int>> Function(Uri url);

class VideoCacheResult {
  const VideoCacheResult({
    required this.saved,
    required this.needsWifi,
    this.path,
    this.rejectedBecauseTooLong = false,
  });

  final bool saved;
  final bool needsWifi;
  final String? path;
  final bool rejectedBecauseTooLong;
}

/// Downloads an optional tutorial video only on Wi-Fi, then keeps the file.
class TutorialVideoCache {
  TutorialVideoCache({
    required this.network,
    required this.store,
    required this.fetch,
  });

  static const maxSeconds = 90;

  final NetworkKindSource network;
  final VideoFileStore store;
  final VideoFetcher fetch;

  Future<VideoCacheResult> prepare({
    required String id,
    required Uri? url,
    required int seconds,
  }) async {
    if (seconds <= 0 || seconds > maxSeconds) {
      return const VideoCacheResult(
        saved: false,
        needsWifi: false,
        rejectedBecauseTooLong: true,
      );
    }
    final existing = await store.existingPath(id);
    if (existing != null) {
      return VideoCacheResult(saved: true, needsWifi: false, path: existing);
    }
    if (url == null) {
      return const VideoCacheResult(saved: false, needsWifi: false);
    }
    final kind = await network.current();
    if (kind != NetworkKind.wifi) {
      return const VideoCacheResult(saved: false, needsWifi: true);
    }
    final bytes = await fetch(url);
    final path = await store.write(id, bytes);
    return VideoCacheResult(saved: true, needsWifi: false, path: path);
  }
}
