import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Embedded live stream widget (WebView).
///
/// Keep the URL in one place so it can be changed easily.
///
/// TODO(developer): Change only [kLiveStreamUrl] to point at your camera/ESP32.
const String kLiveStreamUrl = 'http://10.169.69.127:81/stream';

const Duration _kLoadTimeout = Duration(seconds: 20);

// MJPEG streams often keep the HTTP connection open forever, so the WebView
// may never report 100% progress. We treat the stream as "started" once the
// page reaches a reasonable progress threshold.
const int _kConsiderLoadedAtProgress = 35;

// Many ESP32/MJPEG servers may stop sending after some time (Wi‑Fi sleep,
// server watchdog, router NAT, etc.). Periodically reloading helps keep the
// stream alive.
const Duration _kAutoReloadInterval = Duration(minutes: 2);

// If the stream fails, automatically retry after a short delay.
const Duration _kAutoRetryDelay = Duration(seconds: 2);

class LiveStreamView extends StatefulWidget {
  const LiveStreamView({
    super.key,
    this.autoStart = false,
    this.height = 220,
  });

  /// If true, starts loading immediately.
  final bool autoStart;

  /// Height of the embedded player area.
  final double height;

  @override
  State<LiveStreamView> createState() => LiveStreamViewState();
}

class LiveStreamViewState extends State<LiveStreamView> {
  bool get isStreaming => _started;
  late final WebViewController _controller;

  bool _started = false;
  bool _isLoading = false;
  int _progress = 0;
  String? _errorMessage;

  Timer? _timeoutTimer;
  Timer? _autoReloadTimer;
  Timer? _autoRetryTimer;

  Uri get _uriToLoad {
    final raw = kLiveStreamUrl.trim();
    final withScheme = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'http://$raw';
    return Uri.parse(withScheme);
  }

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _startLoading(url: url);
          },
          onProgress: (progress) {
            if (!mounted) return;
            final p = progress.clamp(0, 100);
            setState(() {
              _progress = p;

              // For MJPEG/long-polling streams, progress often never reaches 100.
              // Stop showing the loader after a small threshold.
              if (p >= _kConsiderLoadedAtProgress) {
                _isLoading = false;
              }
            });
          },
          onPageFinished: (_) {
            // Some streams may never report "finished"; but if they do, treat it as loaded.
            _stopLoading();
          },
          onHttpError: (HttpResponseError error) {
            debugPrint(
              '[LiveStreamView] HTTP error: statusCode=${error.response?.statusCode} url=${error.request?.uri}',
            );
            _showError(
              'Server error (HTTP ${error.response?.statusCode ?? 'unknown'}).\n'
              'URL: ${_uriToLoad.toString()}',
            );
            _scheduleAutoRetry();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[LiveStreamView] Web error: code=${error.errorCode} type=${error.errorType} desc=${error.description} url=${error.url}',
            );
            _showError(
              'Could not load stream.\nReason: ${error.description}',
            );
            _scheduleAutoRetry();
          },
        ),
      );

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      platformController.setMediaPlaybackRequiresUserGesture(false);
    }

    if (widget.autoStart) {
      // delay to allow widget to mount and show UI first
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    }
  }

  /// Call this from outside (HomePage button) to begin streaming.
  Future<void> start() async {
    if (_started) {
      await reload();
      return;
    }
    _started = true;

    _startAutoReload();
    await _load();
  }

  void _startAutoReload() {
    _autoReloadTimer?.cancel();
    _autoReloadTimer = Timer.periodic(_kAutoReloadInterval, (_) async {
      if (!mounted) return;
      if (!_started) return;
      // If user is currently seeing an error, let auto-retry handle it.
      if (_errorMessage != null) return;

      debugPrint('[LiveStreamView] Auto reload');
      await reload();
    });
  }

  void _scheduleAutoRetry() {
    _autoRetryTimer?.cancel();
    _autoRetryTimer = Timer(_kAutoRetryDelay, () async {
      if (!mounted) return;
      if (!_started) return;
      debugPrint('[LiveStreamView] Auto retry');
      await _load();
    });
  }

  Future<void> reload() async {
    if (!_started) return;
    try {
      await _controller.reload();
    } catch (e) {
      // fallback
      await _load();
    }
  }

  /// Stops the stream and frees resources (best effort).
  ///
  /// This cancels auto-reload/auto-retry and loads a blank page.
  Future<void> stop() async {
    if (!_started) return;

    _timeoutTimer?.cancel();
    _autoReloadTimer?.cancel();
    _autoRetryTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _started = false;
      _isLoading = false;
      _progress = 0;
      _errorMessage = null;
    });

    // Best-effort: clear the WebView content.
    // (Some platforms may ignore about:blank, but usually it stops the stream.)
    try {
      await _controller.loadHtmlString('');
    } catch (_) {
      // ignore
    }
  }

  void _startLoading({String? url}) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_kLoadTimeout, () {
      if (!mounted) return;
      if (_errorMessage != null) return;
      if (!_isLoading) return;
      _showError('Loading timed out. Check network/URL: ${url ?? _uriToLoad}');
    });

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _progress = 0;
      _errorMessage = null;
    });
  }

  void _stopLoading() {
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _progress = 100;
    });
  }

  void _showError(String message) {
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  Future<void> _load() async {
    final uri = _uriToLoad;
    _startLoading(url: uri.toString());

    try {
      await _controller.loadRequest(uri);
    } catch (e, st) {
      debugPrint('[LiveStreamView] loadRequest exception: $e\n$st');
      _showError('Failed to load: $e');
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _autoReloadTimer?.cancel();
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black12,
            border: Border.all(color: Colors.black12),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: _started
                    ? WebViewWidget(controller: _controller)
                    : const Center(
                        child: Text('Press Live Stream to start'),
                      ),
              ),

              if (_started && _isLoading && _errorMessage == null)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x33FFFFFF),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text('Loading… $_progress%'),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_errorMessage != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: start,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (kDebugMode)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        _uriToLoad.host,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
