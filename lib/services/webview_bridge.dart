import 'dart:convert';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:lucky_wheel/services/encryption_service.dart';

// ── Caches ───────────────────────────────────────────────────────────────

Map<String, String>? _cachedMapping;
Map<String, String>? _f; // field names
Map<String, String>? _m; // method names
String? _defaultCurrency;

/// Decrypt bridge strings and tokens once — call this before any
/// WebView page loads so everything is ready when JS messages arrive.
void warmUpBridgeCaches() {
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

// ── Public API typedefs ───────────────────────────────────────────────

typedef InternalPageOpener = void Function(String url, {bool showBack});
typedef SystemAppOpener = void Function(String url);
typedef PageLoader = void Function(String url);

// ── Injection payload builder ─────────────────────────────────────────

String prepareInjectionPayload() {
  return EncryptionService().injectionPayload;
}

// ── Revenue extraction helper ─────────────────────────────────────────

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

// ── Adjust dispatch helpers ───────────────────────────────────────────

AdjustEvent _buildAdjustEvent(String eventName) {
  final token = _cachedMapping![eventName] ?? eventName;
  return AdjustEvent(token);
}

void _dispatchToAdjust(String name, String rawJson) {
  final token = _cachedMapping![name];
  if (token == null) return;
  final event = AdjustEvent(token);
  _applyRevenue(event, rawJson);
  Adjust.trackEvent(event);
}

// ── Channel 1: Native ─────────────────────────────────────────────────

void handleNativeChannelMessage(
  String data, {
  required InternalPageOpener openInApp,
  required SystemAppOpener openSystem,
  required PageLoader loadPage,
}) {
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
    if (url.isNotEmpty) openSystem(url);
  } else if (method == _m!['openWebView']) {
    if (url.isNotEmpty) loadPage(url);
  } else if (method == _m!['openWindow']) {
    if (url.isNotEmpty) openInApp(url, showBack: true);
  } else if (method == _m!['eventTracker']) {
    final name = msg[_f!['eventName']] as String? ?? '';
    final raw = msg[_f!['eventValue']] as String? ?? '';
    _dispatchToAdjust(name, raw);
  }
}

// ── Channel 2: Attribution ────────────────────────────────────────────

void handleAttributionMessage(String data) {
  Map<String, dynamic> msg;
  try {
    msg = jsonDecode(data) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  if (_f == null) return;

  final method = msg[_f!['method']] as String? ?? '';
  final eventName = msg[_f!['eventName']] as String? ?? '';
  final event = _buildAdjustEvent(eventName);

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

// ── Channel 3: JavaScript Bridge ──────────────────────────────────────

void handleJsChannelMessage(
  String data, {
  required InternalPageOpener openInApp,
}) {
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
    if (targetUrl.isNotEmpty) openInApp(targetUrl, showBack: false);
    return;
  }

  final event = _buildAdjustEvent(eventName);
  _applyRevenue(event, rawParams);
  Adjust.trackEvent(event);
}
