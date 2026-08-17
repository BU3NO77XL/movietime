import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class EmbeddedPlayerScreen extends StatefulWidget {
  const EmbeddedPlayerScreen({super.key, required this.url});

  final Uri url;

  @override
  State<EmbeddedPlayerScreen> createState() => _EmbeddedPlayerScreenState();
}

class _EmbeddedPlayerScreenState extends State<EmbeddedPlayerScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;
  late final bool _isSupported;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _isSupported =
        !kIsWeb &&
        <TargetPlatform>{
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != false && mounted) {
              setState(() {
                _error = error.description;
                _progress = 100;
              });
            }
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      unawaited(
        androidController.setUserAgent(
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
        ),
      );
      unawaited(androidController.setMediaPlaybackRequiresUserGesture(false));
    }
    _controller.loadRequest(widget.url);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Assistindo'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _isSupported ? _controller.reload : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: !_isSupported
          ? _UnsupportedPlayer(url: widget.url)
          : _error != null
          ? _PlayerError(
              message: _error!,
              onRetry: () {
                setState(() {
                  _error = null;
                  _progress = 0;
                });
                _controller.reload();
              },
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_progress < 100)
                  LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 2,
                    color: const Color(0xFFE50914),
                    backgroundColor: Colors.transparent,
                  ),
              ],
            ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white70,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar o player.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedPlayer extends StatelessWidget {
  const _UnsupportedPlayer({required this.url});

  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => launchUrl(url, mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Abrir player'),
      ),
    );
  }
}
