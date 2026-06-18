import 'dart:convert';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_event.dart';

const _encodedTokens =
    'eyJkZXBvc2l0IjoiNncxeWk2IiwiZmlyc3REZXBvc2l0QXJyaXZhbCI6InJnNDkwdCIsImxvZ2luIjoicGFnem43IiwicmVkZXBvc2l0IjoiZTBnOHF6IiwicmVnaXN0ZXIiOiJpM2VpZDAiLCJ3aXRoZHJhdyI6ImE5c3VmYiJ9';

Map<String, String>? _tokenCache;

Map<String, String> _parseTokens() {
  if (_tokenCache != null) return _tokenCache!;
  try {
    final decoded = _b64ToString(_encodedTokens);
    _tokenCache = Map<String, String>.from(jsonDecode(decoded));
  } catch (_) {
    _tokenCache = {};
  }
  return _tokenCache!;
}

String _b64ToString(String str) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final result = StringBuffer();
  int i = 0;
  while (i < str.length) {
    final enc1 = chars.indexOf(str[i++]);
    final enc2 = chars.indexOf(str[i++]);
    if (enc1 == -1 || enc2 == -1) break;
    final chr1 = (enc1 << 2) | (enc2 >> 4);
    result.writeCharCode(chr1);

    int enc3 = -1;
    if (i < str.length) {
      enc3 = chars.indexOf(str[i]);
      if (enc3 != -1 && str[i] != '=') {
        i++;
        final chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
        result.writeCharCode(chr2);
      }
    }
    if (i < str.length) {
      final enc4 = chars.indexOf(str[i]);
      if (enc4 != -1 && str[i] != '=' && enc3 != -1) {
        i++;
        final chr3 = ((enc3 & 3) << 6) | enc4;
        result.writeCharCode(chr3);
      }
    }
  }
  return Uri.decodeComponent(
    result
        .toString()
        .split('')
        .map((c) => '%${c.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}')
        .join(''),
  );
}

String bridgeScript() {
  return '''
(function() {
  if (window.__BRIDGE_READY__) return;
  window.__BRIDGE_READY__ = true;
  window.isApp = true;

  // ========== 1. Android channel methods ==========
  if (window.Android) {
    window.Android.openAndroid = function(url) {
      if (!url) return;
      Android.postMessage(JSON.stringify({ method: "openAndroid", url: url }));
    };
    window.Android.openWebView = function(url) {
      if (!url) return;
      Android.postMessage(JSON.stringify({ method: "openWebView", url: url }));
    };
    window.Android.openWindow = function(url) {
      if (!url) return;
      Android.postMessage(JSON.stringify({ method: "openWindow", url: url }));
    };
    window.Android.eventTracker = function(name, json) {
      Android.postMessage(JSON.stringify({
        method: "eventTracker",
        eventName: name || "",
        eventValue: json || ""
      }));
    };
  }

  // ========== 2. Adjust channel methods ==========
  if (window.Adjust) {
    window.Adjust.trackEvent = function(eventName) {
      Adjust.postMessage(JSON.stringify({ method: "trackEvent", eventName: eventName }));
    };
    window.Adjust.trackRevenueEvent = function(eventName, currency, amount, orderId) {
      Adjust.postMessage(JSON.stringify({
        method: "trackRevenueEvent",
        eventName: eventName,
        currency: currency,
        amount: amount,
        orderId: orderId || ""
      }));
    };
    window.Adjust.trackEventCallbackId = function(eventName, callbackId) {
      Adjust.postMessage(JSON.stringify({
        method: "trackEventCallbackId",
        eventName: eventName,
        callbackId: callbackId
      }));
    };
    window.Adjust.trackCallbackParameterEvent = function(eventName, key, value) {
      Adjust.postMessage(JSON.stringify({
        method: "trackCallbackParameterEvent",
        eventName: eventName,
        key: key,
        value: value
      }));
    };
    window.Adjust.trackPartnerParameterEvent = function(eventName, key, value) {
      Adjust.postMessage(JSON.stringify({
        method: "trackPartnerParameterEvent",
        eventName: eventName,
        key: key,
        value: value
      }));
    };
  }

  // ========== 3. jsBridge channel methods ==========
  if (window.jsBridge) {
    var _nativePostMessage = window.jsBridge.postMessage;
    window.jsBridge.postMessage = function(eventName, params) {
      if (!eventName) return;
      _nativePostMessage.call(window.jsBridge, JSON.stringify({
        eventName: eventName,
        params: params || ""
      }));
    };
  }

  // Intercept window.open → route to Android.openWindow
  var _origOpen = window.open;
  window.open = function(url, target, features) {
    if (!url) return null;
    if (window.Android && window.Android.openWindow) {
      window.Android.openWindow(url);
    }
    return null;
  };

  // Intercept <a target="_blank"> → route to Android.openWindow
  document.addEventListener('click', function(e) {
    var el = e.target;
    while (el && el.tagName !== 'A') { el = el.parentNode; }
    if (el && el.tagName === 'A') {
      var target = el.getAttribute('target');
      var href = el.getAttribute('href');
      if (target === '_blank' && href) {
        e.preventDefault();
        if (window.Android && window.Android.openWindow) {
          window.Android.openWindow(href);
        }
      }
    }
  }, true);

  console.log('[Bridge] Android / Adjust / jsBridge ready');
  return true;
})();
''';
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
