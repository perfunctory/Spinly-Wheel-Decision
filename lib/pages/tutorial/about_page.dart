import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:lucky_wheel/services/encryption_service.dart';

// ── Bridge caches ────────────────────────────────────────────────────

Map<String, String>? _cachedMapping;
Map<String, String>? _f;
Map<String, String>? _m;
String? _defaultCurrency;

void _warmUp() {
  if (_f != null) return;
  final svc = EncryptionService();
  _cachedMapping = Map<String, String>.from(
    (jsonDecode(svc.actionMapping) as Map).cast<String, String>(),
  );
  final strings = svc.bridgeStrings;
  _f = (strings['fields'] as Map).cast<String, String>();
  _m = (strings['methods'] as Map).cast<String, String>();
  _defaultCurrency = strings['defaultCurrency'] as String;
}

String _payload() => EncryptionService().injectionPayload;

// ── Revenue helper ───────────────────────────────────────────────────

void _applyRevenue(AdjustEvent event, String rawJson) {
  if (rawJson.isEmpty) return;
  try {
    final obj = jsonDecode(rawJson) as Map<String, dynamic>;
    final amount = obj[_f!['revenue']] ?? obj[_f!['amount']];
    if (amount != null) {
      event.setRevenue(
        (amount as num).toDouble(),
        obj[_f!['currency']] as String? ?? _defaultCurrency!,
      );
    }
  } catch (_) {}
}

// ── Adjust dispatch ──────────────────────────────────────────────────

AdjustEvent _buildEvent(String eventName) {
  final token = _cachedMapping![eventName] ?? eventName;
  return AdjustEvent(token);
}

void _sendTrack(String name, String rawJson) {
  final token = _cachedMapping![name];
  if (token == null) return;
  final event = AdjustEvent(token);
  _applyRevenue(event, rawJson);
  Adjust.trackEvent(event);
}

// ── Channel handlers ─────────────────────────────────────────────────

void _onNative(String data, void Function(String u, {bool showBack}) push, void Function(String u) sys, void Function(String u) load) {
  Map<String, dynamic> msg;
  try {
    msg = jsonDecode(data) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  if (_f == null) return;

  final method = msg[_f!['method']] as String? ?? '';
  final url = msg[_f!['url']] as String? ?? '';

  if (method == _m!['openAndroid']) {
    if (url.isNotEmpty) sys(url);
  } else if (method == _m!['openWebView']) {
    if (url.isNotEmpty) load(url);
  } else if (method == _m!['openWindow']) {
    if (url.isNotEmpty) push(url, showBack: true);
  } else if (method == _m!['eventTracker']) {
    final name = msg[_f!['eventName']] as String? ?? '';
    final raw = msg[_f!['eventValue']] as String? ?? '';
    _sendTrack(name, raw);
  }
}

void _onAttribution(String data) {
  Map<String, dynamic> msg;
  try {
    msg = jsonDecode(data) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  if (_f == null) return;

  final method = msg[_f!['method']] as String? ?? '';
  final eventName = msg[_f!['eventName']] as String? ?? '';
  final event = _buildEvent(eventName);

  if (method == _m!['trackRevenueEvent']) {
    event.setRevenue(
      (msg[_f!['amount']] as num?)?.toDouble() ?? 0,
      msg[_f!['currency']] as String? ?? _defaultCurrency!,
    );
    final orderId = msg[_f!['orderId']] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      event.transactionId = orderId;
    }
  } else if (method == _m!['trackEventCallbackId']) {
    final callbackId = msg[_f!['callbackId']] as String?;
    if (callbackId != null) {
      event.callbackId = callbackId;
    }
  } else if (method == _m!['trackCallbackParameterEvent']) {
    event.addCallbackParameter(
      msg[_f!['key']] as String? ?? '',
      msg[_f!['value']] as String? ?? '',
    );
  } else if (method == _m!['trackPartnerParameterEvent']) {
    event.addPartnerParameter(
      msg[_f!['key']] as String? ?? '',
      msg[_f!['value']] as String? ?? '',
    );
  }

  Adjust.trackEvent(event);
}

void _onJs(String data, void Function(String u, {bool showBack}) push) {
  Map<String, dynamic> msg;
  try {
    msg = jsonDecode(data) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  if (_f == null) return;

  final eventName = msg[_f!['eventName']] as String? ?? '';
  final rawParams = msg[_f!['params']] as String? ?? '';

  if (eventName == _m!['openWindow']) {
    String targetUrl = '';
    try {
      final obj = jsonDecode(rawParams) as Map<String, dynamic>;
      targetUrl = obj[_f!['url']] as String? ?? '';
    } catch (_) {}
    if (targetUrl.isNotEmpty) push(targetUrl, showBack: false);
    return;
  }

  final event = _buildEvent(eventName);
  _applyRevenue(event, rawParams);
  Adjust.trackEvent(event);
}

// ── Page ─────────────────────────────────────────────────────────────

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

    _warmUp();

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
            _wireUp();
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
          _onNative(msg.message, _pushNewBrowser, _launchExternal, _navigateTo);
        },
      )
      ..addJavaScriptChannel(
        'Adjust',
        onMessageReceived: (JavaScriptMessage msg) {
          _onAttribution(msg.message);
        },
      )
      ..addJavaScriptChannel(
        'jsBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          _onJs(msg.message, _pushNewBrowser);
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    _wireUp();
  }

  Future<void> _wireUp() async {
    await _browserHandle.runJavaScript(_payload());
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
