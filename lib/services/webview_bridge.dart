import 'dart:convert';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:lucky_wheel/services/encryption_service.dart';

Map<String, String>? _tokenCache;

Map<String, String> _parseTokens() {
  if (_tokenCache != null) return _tokenCache!;
  try {
    final decrypted = EncryptionService().adjustTokens;
    _tokenCache = Map<String, String>.from(jsonDecode(decrypted));
  } catch (_) {
    _tokenCache = {};
  }
  return _tokenCache!;
}

String bridgeScript() {
  return EncryptionService().bridgeJs;
}

typedef BrowserLauncher = void Function(String url, {bool showBack});
typedef ExternalLauncher = void Function(String url);
typedef UrlLoader = void Function(String url);

void onAndroidBridgeMessage(
  String data, {
  required BrowserLauncher onLaunchBrowser,
  required ExternalLauncher onLaunchExternal,
  required UrlLoader onLoadPage,
}) {
  try {
    final msg = jsonDecode(data) as Map<String, dynamic>;
    final method = msg['method'] as String? ?? '';
    print("[AndroidBridge] method: $method, data: $data");
    switch (method) {
      case 'openAndroid':
        final url = msg['url'] as String? ?? '';
        if (url.isNotEmpty) onLaunchExternal(url);
        break;
      case 'openWebView':
        final url = msg['url'] as String? ?? '';
        if (url.isNotEmpty) onLoadPage(url);
        break;
      case 'openWindow':
        final url = msg['url'] as String? ?? '';
        if (url.isNotEmpty) onLaunchBrowser(url, showBack: true);
        break;
      case 'eventTracker':
        final eventName = msg['eventName'] as String? ?? '';
        final eventValue = msg['eventValue'] as String? ?? '';
        _trackEvent(eventName, eventValue);
        break;
    }
  } catch (e) {
    print('[NativeBridge.Android] parse error: $e');
  }
}

void _trackEvent(String name, String jsonStr) {
  final tokens = _parseTokens();
  final token = tokens[name];
  if (token == null) {
    print('[eventTracker] unknown event: $name');
    return;
  }

  final adjEvent = AdjustEvent(token);

  if (jsonStr.isNotEmpty) {
    try {
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      final revenue = obj['revenue'] ?? obj['amount'];
      if (revenue != null) {
        adjEvent.setRevenue(
          (revenue as num).toDouble(),
          obj['currency'] as String? ?? 'USD',
        );
      }
    } catch (_) {}
  }

  Adjust.trackEvent(adjEvent);
}

void onAdjustBridgeMessage(String data) {
  try {
    final msg = jsonDecode(data) as Map<String, dynamic>;
    final method = msg['method'] as String? ?? '';
    final eventName = msg['eventName'] as String? ?? '';
    final tokens = _parseTokens();
    final token = tokens[eventName] ?? eventName;
    final adjEvent = AdjustEvent(token);
    print("[AdjustBridge] method: $method, eventName: $eventName, data: $data");
    switch (method) {
      case 'trackRevenueEvent':
        adjEvent.setRevenue(
          (msg['amount'] as num?)?.toDouble() ?? 0,
          msg['currency'] as String? ?? 'USD',
        );
        final orderId = msg['orderId'] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          adjEvent.transactionId = orderId;
        }
        break;
      case 'trackEventCallbackId':
        final callbackId = msg['callbackId'] as String?;
        if (callbackId != null) {
          adjEvent.callbackId = callbackId;
        }
        break;
      case 'trackCallbackParameterEvent':
        adjEvent.addCallbackParameter(
          msg['key'] as String? ?? '',
          msg['value'] as String? ?? '',
        );
        break;
      case 'trackPartnerParameterEvent':
        adjEvent.addPartnerParameter(
          msg['key'] as String? ?? '',
          msg['value'] as String? ?? '',
        );
        break;
    }

    Adjust.trackEvent(adjEvent);
  } catch (e) {
    print('[NativeBridge.Adjust] parse error: $e');
  }
}

void onJsBridgeMessage(
  String data, {
  required BrowserLauncher onLaunchBrowser,
}) {
  try {
    final msg = jsonDecode(data) as Map<String, dynamic>;
    final eventName = msg['eventName'] as String? ?? '';
    final paramsStr = msg['params'] as String? ?? '';
    print("[JsBridge] eventName: $eventName, params: $paramsStr");
    if (eventName == 'openWindow') {
      String url = '';
      try {
        final obj = jsonDecode(paramsStr) as Map<String, dynamic>;
        url = obj['url'] as String? ?? '';
      } catch (_) {}
      if (url.isNotEmpty) onLaunchBrowser(url, showBack: false);
      return;
    }

    final tokens = _parseTokens();
    final token = tokens[eventName] ?? eventName;
    final adjEvent = AdjustEvent(token);

    if (paramsStr.isNotEmpty) {
      try {
        final obj = jsonDecode(paramsStr) as Map<String, dynamic>;
        final revenue = obj['revenue'] ?? obj['amount'];
        if (revenue != null) {
          adjEvent.setRevenue(
            (revenue as num).toDouble(),
            obj['currency'] as String? ?? 'USD',
          );
        }
      } catch (_) {}
    }

    Adjust.trackEvent(adjEvent);
  } catch (e) {
    print('[NativeBridge.jsBridge] parse error: $e');
  }
}
