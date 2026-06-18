import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:lucky_wheel/app.dart';
import 'package:lucky_wheel/providers/wheel_provider.dart';
import 'package:lucky_wheel/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Adjust SDK ─────────────────────────────────────────────────────
  final adjustConfig = AdjustConfig(
    'dv96r6tlwc8w',
    AdjustEnvironment.production,
  );
  adjustConfig.logLevel = AdjustLogLevel.verbose;
  Adjust.start(adjustConfig);

  // ── Portrait lock ──────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ── Local storage ──────────────────────────────────────────────────
  final storage = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const LuckyWheelApp(),
    ),
  );
}
