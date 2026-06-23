import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucky_wheel/services/encryption_service.dart';
import 'package:lucky_wheel/services/webview_bridge.dart';

/// Embedded browser page — renders remote content with native channels.
class PageBrowser extends StatefulWidget {
  final String url;
  final bool showBack;

  const PageBrowser({super.key, required this.url, this.showBack = false});

  @override
  State<PageBrowser> createState() => _PageBrowserState();
}

class _PageBrowserState extends State<PageBrowser> {
  late final WebViewController _browserHandle;
  bool _isLoading = true;
  bool _canGoPrevious = false;
  bool _isGoingPrevious = false;

  @override
  void initState() {
    super.initState();

    warmUpBridgeCaches();

    _browserHandle = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1b1c17))
      ..setUserAgent(EncryptionService().userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _isLoading = false);
            _refreshNavigationState();
            _wireUpChannelBridge();
          },
          onUrlChange: (_) {
            if (!_isGoingPrevious) _refreshNavigationState();
          },
          onWebResourceError: (_) {},
          onNavigationRequest: (request) {
            final url = request.url;
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              _launchExternal(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Android',
        onMessageReceived: (JavaScriptMessage msg) {
          handleNativeChannelMessage(
            msg.message,
            openInApp: _pushNewBrowser,
            openSystem: _launchExternal,
            loadPage: _navigateTo,
          );
        },
      )
      ..addJavaScriptChannel(
        'Adjust',
        onMessageReceived: (JavaScriptMessage msg) {
          handleAttributionMessage(msg.message);
        },
      )
      ..addJavaScriptChannel(
        'jsBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          handleJsChannelMessage(msg.message, openInApp: _pushNewBrowser);
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    _wireUpChannelBridge();
  }

  Future<void> _wireUpChannelBridge() async {
    await _browserHandle.runJavaScript(prepareInjectionPayload());
  }

  void _pushNewBrowser(String url, {bool showBack = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PageBrowser(url: url, showBack: showBack),
      ),
    );
  }

  void _navigateTo(String url) {
    _browserHandle.loadRequest(Uri.parse(url));
  }

  Future<void> _refreshNavigationState() async {
    try {
      final canGoBack = await _browserHandle.canGoBack();
      if (mounted) setState(() => _canGoPrevious = canGoBack);
    } catch (_) {}
  }

  Future<void> _launchExternal(String url) async {
    final svc = EncryptionService();
    if (url.startsWith(svc.gcashScheme)) {
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
      final fallbackUri = Uri.parse(svc.gcashFallback);
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

  Future<bool> _onPreviousPage() async {
    if (_isGoingPrevious) return false;
    if (!_canGoPrevious) return true;

    _isGoingPrevious = true;
    try {
      await _browserHandle.goBack();
      await Future.delayed(const Duration(milliseconds: 300));
      await _refreshNavigationState();
    } catch (_) {}
    _isGoingPrevious = false;
    return false;
  }

  void _onReturnHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_canGoPrevious,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onPreviousPage();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1b1c17),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _browserHandle),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF3D68)),
                ),
              if (widget.showBack)
                Positioned(
                  bottom: MediaQuery.of(context).size.height / 4,
                  right: 0,
                  child: GestureDetector(
                    onTap: _onReturnHome,
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
