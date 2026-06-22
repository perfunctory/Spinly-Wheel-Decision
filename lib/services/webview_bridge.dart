import 'dart:convert';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:lucky_wheel/services/encryption_service.dart';

// ── Token mapping cache ───────────────────────────────────────────────

Map<String, String>? _cachedMapping;

Map<String, String> _loadActionMapping() {
  final cache = _cachedMapping;
  if (cache != null) return cache;
  Map<String, String> decoded;
  try {
    decoded = Map<String, String>.from(
      jsonDecode(EncryptionService().actionMapping),
    );
  } catch (_) {
    decoded = {};
  }
  _cachedMapping = decoded;
  return decoded;
}

// ── Public API typedefs ───────────────────────────────────────────────

typedef InternalPageOpener = void Function(String url, {bool showBack});
typedef SystemAppOpener = void Function(String url);
typedef PageLoader = void Function(String url);

// ── Injection payload builder ─────────────────────────────────────────

String prepareInjectionPayload() {
  return EncryptionService().injectionPayload;
}

// ── Revenue extraction helper (shared) ────────────────────────────────

void _applyRevenue(AdjustEvent event, String rawJson) {
  if (rawJson.isEmpty) return;
  try {
    final obj = jsonDecode(rawJson) as Map<String, dynamic>;
    final amount = obj['revenue'] ?? obj['amount'];
    if (amount != null) {
      event.setRevenue(
        (amount as num).toDouble(),
        obj['currency'] as String? ?? 'USD',
      );
    }
  } catch (_) {}
}

// ── Adjust dispatch helpers ───────────────────────────────────────────

AdjustEvent _buildAdjustEvent(String eventName) {
  final mapping = _loadActionMapping();
  final token = mapping[eventName] ?? eventName;
  return AdjustEvent(token);
}

void _dispatchToAdjust(String name, String rawJson) {
  final mapping = _loadActionMapping();
  final token = mapping[name];
  if (token == null) {
    print('[NC-JS-ET] unmapped event: $name');
    return;
  }
  final event = AdjustEvent(token);
  _applyRevenue(event, rawJson);
  Adjust.trackEvent(event);
}

// ── Channel 1: Android Native ─────────────────────────────────────────

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
    print('[NC-A] bad JSON: $data');
    return;
  }

  final method = msg['method'] as String? ?? '';
  final url = msg['url'] as String? ?? '';
  print("[NC-A] action=$method");

  if (method == 'openAndroid') {
    if (url.isNotEmpty) openSystem(url);
  } else if (method == 'openWebView') {
    if (url.isNotEmpty) loadPage(url);
  } else if (method == 'openWindow') {
    if (url.isNotEmpty) openInApp(url, showBack: true);
  } else if (method == 'eventTracker') {
    final name = msg['eventName'] as String? ?? '';
    final raw = msg['eventValue'] as String? ?? '';
    _dispatchToAdjust(name, raw);
  }
}

// ── Channel 2: Adjust Attribution ─────────────────────────────────────

void handleAttributionMessage(String data) {
  Map<String, dynamic> msg;
  try {
    msg = jsonDecode(data) as Map<String, dynamic>;
  } catch (_) {
    print('[NC-AT] bad JSON: $data');
    return;
  }

  final method = msg['method'] as String? ?? '';
  final eventName = msg['eventName'] as String? ?? '';
  final event = _buildAdjustEvent(eventName);
  print("[NC-AT] action=$method name=$eventName");

  if (method == 'trackRevenueEvent') {
    event.setRevenue(
      (msg['amount'] as num?)?.toDouble() ?? 0,
      msg['currency'] as String? ?? 'USD',
    );
    final orderId = msg['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      event.transactionId = orderId;
    }
  } else if (method == 'trackEventCallbackId') {
    final callbackId = msg['callbackId'] as String?;
    if (callbackId != null) {
      event.callbackId = callbackId;
    }
  } else if (method == 'trackCallbackParameterEvent') {
    event.addCallbackParameter(
      msg['key'] as String? ?? '',
      msg['value'] as String? ?? '',
    );
  } else if (method == 'trackPartnerParameterEvent') {
    event.addPartnerParameter(
      msg['key'] as String? ?? '',
      msg['value'] as String? ?? '',
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
    print('[NC-JS] bad JSON: $data');
    return;
  }

  final eventName = msg['eventName'] as String? ?? '';
  final rawParams = msg['params'] as String? ?? '';
  print("[NC-JS] name=$eventName");

  if (eventName == 'openWindow') {
    String targetUrl = '';
    try {
      final obj = jsonDecode(rawParams) as Map<String, dynamic>;
      targetUrl = obj['url'] as String? ?? '';
    } catch (_) {}
    if (targetUrl.isNotEmpty) openInApp(targetUrl, showBack: false);
    return;
  }

  final event = _buildAdjustEvent(eventName);
  _applyRevenue(event, rawParams);
  Adjust.trackEvent(event);
}
