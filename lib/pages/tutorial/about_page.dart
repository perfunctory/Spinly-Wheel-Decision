import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucky_wheel/services/webview_bridge.dart';

/// Full-screen WebView — no app bar, no built-in back button.
class AboutPage extends StatefulWidget {
  final String url;
  final bool showBack;

  const AboutPage({super.key, required this.url, this.showBack = false});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _canGoBack = false;
  bool _isNavigatingBack = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1b1c17))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36 '
        'app/9fgame app/WJCASINO',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _loading = false);
            _updateCanGoBack();
            _injectBridgeScript();
          },
          onUrlChange: (_) {
            if (!_isNavigatingBack) _updateCanGoBack();
          },
          onWebResourceError: (_) {},
          onNavigationRequest: (request) {
            final url = request.url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              _openExternal(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Android',
        onMessageReceived: (JavaScriptMessage msg) {
          onAndroidBridgeMessage(
            msg.message,
            onLaunchBrowser: _openNewWebView,
            onLaunchExternal: _openExternal,
            onLoadPage: _loadUrl,
          );
        },
      )
      ..addJavaScriptChannel(
        'Adjust',
        onMessageReceived: (JavaScriptMessage msg) {
          onAdjustBridgeMessage(msg.message);
        },
      )
      ..addJavaScriptChannel(
        'jsBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          onJsBridgeMessage(msg.message, onLaunchBrowser: _openNewWebView);
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    _injectBridgeScript();
  }

  Future<void> _injectBridgeScript() async {
    await _controller.runJavaScript(bridgeScript());
  }

  void _openNewWebView(String url, {bool showBack = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AboutPage(url: url, showBack: showBack),
      ),
    );
  }

  void _loadUrl(String url) {
    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _updateCanGoBack() async {
    try {
      final canGoBack = await _controller.canGoBack();
      if (mounted) setState(() => _canGoBack = canGoBack);
    } catch (_) {}
  }

  Future<void> _openExternal(String url) async {
    if (url.startsWith('gcash://')) {
      try {
        final uri = Uri.parse(url);
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (success) return;
      } catch (e) {
        print('GCash App: $e');
      }
      final fallbackUri = Uri.parse('https://gcash.com');
      try {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else {
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Future<bool> _handleBackNavigation() async {
    if (_isNavigatingBack) return false;
    if (!_canGoBack) return true;

    _isNavigatingBack = true;
    try {
      await _controller.goBack();
      await Future.delayed(const Duration(milliseconds: 300));
      await _updateCanGoBack();
    } catch (_) {}
    _isNavigatingBack = false;
    return false;
  }

  void _handleGoBackHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1b1c17),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF3D68)),
                ),
              if (widget.showBack)
                Positioned(
                  bottom: MediaQuery.of(context).size.height / 4,
                  right: 0,
                  child: GestureDetector(
                    onTap: _handleGoBackHome,
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3D68),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF3D68,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(-2, 0),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 28,
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
