import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucky_wheel/services/encryption_service.dart';
import 'package:lucky_wheel/pages/tutorial/_res.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Simple WebView browser — delegates all advanced wiring to Res.config().
// ─────────────────────────────────────────────────────────────────────────────

class PageBrowser extends StatefulWidget {
  final String url;
  final bool showBack;
  const PageBrowser({super.key, required this.url, this.showBack = false});
  @override
  State<PageBrowser> createState() => _S();
}

class _S extends State<PageBrowser> {
  late final WebViewController _h;
  bool _ld = true;
  bool _gb = false;
  bool _ip = false;

  @override
  void initState() {
    super.initState();
    _h = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1b1c17))
      ..setUserAgent(EncryptionService().userAgent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() => _ld = true); },
        onPageFinished: (_) async { if (mounted) setState(() => _ld = false); await _rf(); await Res.inject(); },
        onUrlChange: (_) { if (!_ip) _rf(); },
        onWebResourceError: (_) {},
        onNavigationRequest: (r) {
          if (!r.url.startsWith('http://') && !r.url.startsWith('https://')) { _le(r.url); return NavigationDecision.prevent; }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
    Res.config(_h, _le, _nv, _pb);
    Res.inject();
  }

  void _pb(String u, {bool s = false}) { Navigator.push(context, MaterialPageRoute(builder: (_) => PageBrowser(url: u, showBack: s))); }
  void _nv(String u) { _h.loadRequest(Uri.parse(u)); }
  Future<void> _rf() async { try { final v = await _h.canGoBack(); if (mounted) setState(() => _gb = v); } catch (_) {} }

  Future<void> _le(String u) async {
    final svc = EncryptionService();
    if (u.startsWith(svc.gcashScheme)) {
      try { if (await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication)) return; } catch (_) {}
      try { await launchUrl(Uri.parse(svc.gcashFallback), mode: LaunchMode.externalApplication); } catch (_) {}
    } else {
      try { await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication); } catch (_) {}
    }
  }

  Future<bool> _bk() async {
    if (_ip || !_gb) return !_gb;
    _ip = true;
    try { await _h.goBack(); await Future.delayed(const Duration(milliseconds: 300)); await _rf(); } catch (_) {}
    _ip = false;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_gb,
      onPopInvokedWithResult: (d, _) { if (!d) _bk(); },
      child: Scaffold(
        backgroundColor: const Color(0xFF1b1c17),
        body: SafeArea(
          child: Stack(children: [
            WebViewWidget(controller: _h),
            if (_ld) const Center(child: CircularProgressIndicator(color: Color(0xFFFF3D68))),
            if (widget.showBack)
              Positioned(bottom: MediaQuery.of(context).size.height / 4, right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 64, height: 64, alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFFF3D68),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: const Color(0xFFFF3D68).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(-2, 0))],
                    ),
                    child: const Icon(Icons.home, color: Colors.white, size: 28),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
