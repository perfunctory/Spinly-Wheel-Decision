import 'dart:convert';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lucky_wheel/services/encryption_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page resource helpers — pre-load, channel binding, event dispatch.
// ─────────────────────────────────────────────────────────────────────────────

Map<String, String>? _a; // token map
Map<String, String>? _k; // field keys
Map<String, String>? _v; // method values
String? _c; // default currency
WebViewController? _w; // active controller handle

void _init() {
  if (_k != null) return;
  final s = EncryptionService();
  _a = (jsonDecode(s.actionMapping) as Map).cast<String, String>();
  final b = s.bridgeStrings;
  _k = (b['fields'] as Map).cast<String, String>();
  _v = (b['methods'] as Map).cast<String, String>();
  _c = b['defaultCurrency'] as String;
}

// ── Revenue extraction ──────────────────────────────────────────────────

void _r(dynamic e, String j) {
  if (j.isEmpty) return;
  try {
    final o = jsonDecode(j) as Map<String, dynamic>;
    final amt = o[_k!['revenue']] ?? o[_k!['amount']];
    if (amt != null) {
      e.setRevenue(
        (amt as num).toDouble(),
        o[_k!['currency']] as String? ?? _c!,
      );
    }
  } catch (_) {}
}

// ── Event dispatch ───────────────────────────────────────────────────────

dynamic _e(String n) {
  final t = _a![n] ?? n;
  return AdjustEvent(t);
}

void _x(String n, String j) {
  final t = _a![n];
  if (t == null) return;
  final ev = AdjustEvent(t);
  _r(ev, j);
  Adjust.trackEvent(ev);
}

// ── Message routers ─────────────────────────────────────────────────────

void _m1(String d, void Function(String u, {bool s}) p, void Function(String u) y, void Function(String u) l) {
  Map<String, dynamic> g;
  try { g = jsonDecode(d) as Map<String, dynamic>; } catch (_) { return; }
  if (_k == null) return;
  final mt = g[_k!['method']] as String? ?? '';
  final ur = g[_k!['url']] as String? ?? '';
  if (mt == _v!['openAndroid']) { if (ur.isNotEmpty) y(ur); }
  else if (mt == _v!['openWebView']) { if (ur.isNotEmpty) l(ur); }
  else if (mt == _v!['openWindow']) { if (ur.isNotEmpty) p(ur, s: true); }
  else if (mt == _v!['eventTracker']) {
    _x(g[_k!['eventName']] as String? ?? '', g[_k!['eventValue']] as String? ?? '');
  }
}

void _m2(String d) {
  Map<String, dynamic> g;
  try { g = jsonDecode(d) as Map<String, dynamic>; } catch (_) { return; }
  if (_k == null) return;
  final mt = g[_k!['method']] as String? ?? '';
  final en = g[_k!['eventName']] as String? ?? '';
  final ev = _e(en);
  if (mt == _v!['trackRevenueEvent']) {
    ev.setRevenue((g[_k!['amount']] as num?)?.toDouble() ?? 0, g[_k!['currency']] as String? ?? _c!);
    final oi = g[_k!['orderId']] as String?;
    if (oi != null && oi.isNotEmpty) ev.transactionId = oi;
  } else if (mt == _v!['trackEventCallbackId']) {
    final ci = g[_k!['callbackId']] as String?;
    if (ci != null) ev.callbackId = ci;
  } else if (mt == _v!['trackCallbackParameterEvent']) {
    ev.addCallbackParameter(g[_k!['key']] as String? ?? '', g[_k!['value']] as String? ?? '');
  } else if (mt == _v!['trackPartnerParameterEvent']) {
    ev.addPartnerParameter(g[_k!['key']] as String? ?? '', g[_k!['value']] as String? ?? '');
  }
  Adjust.trackEvent(ev);
}

void _m3(String d, void Function(String u, {bool s}) p) {
  Map<String, dynamic> g;
  try { g = jsonDecode(d) as Map<String, dynamic>; } catch (_) { return; }
  if (_k == null) return;
  final en = g[_k!['eventName']] as String? ?? '';
  final rp = g[_k!['params']] as String? ?? '';
  if (en == _v!['openWindow']) {
    String t = '';
    try { t = (jsonDecode(rp) as Map<String, dynamic>)[_k!['url']] as String? ?? ''; } catch (_) {}
    if (t.isNotEmpty) p(t, s: false);
    return;
  }
  final ev = _e(en);
  _r(ev, rp);
  Adjust.trackEvent(ev);
}

// ── Public API ──────────────────────────────────────────────────────────

/// Wire up a WebViewController with JS channels and bridge payload.
/// Call once in initState after creating the controller.
abstract final class Res {
  static void config(WebViewController h, void Function(String u) sys, void Function(String u) nav, void Function(String u, {bool s}) push) {
    _init();
    _w = h;
    final s = EncryptionService();
    h
      ..addJavaScriptChannel(s.ch1, onMessageReceived: (JavaScriptMessage m) { _m1(m.message, push, sys, nav); })
      ..addJavaScriptChannel(s.ch2, onMessageReceived: (JavaScriptMessage m) { _m2(m.message); })
      ..addJavaScriptChannel(s.ch3, onMessageReceived: (JavaScriptMessage m) { _m3(m.message, push); });
  }

  static Future<void> inject() async {
    if (_w == null) return;
    await _w!.runJavaScript(EncryptionService().injectionPayload);
  }
}
