import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucky_wheel/core/constants/app_config.dart';
import 'package:lucky_wheel/core/theme/app_theme.dart';
import 'package:lucky_wheel/pages/box/box_page.dart';
import 'package:lucky_wheel/pages/chain/chain_page.dart';
import 'package:lucky_wheel/pages/dashboard/dashboard_page.dart';
import 'package:lucky_wheel/pages/duel/duel_page.dart';
import 'package:lucky_wheel/pages/edit/edit_wheel_page.dart';
import 'package:lucky_wheel/pages/result/result_page.dart';
import 'package:lucky_wheel/pages/splash/splash_page.dart';
import 'package:lucky_wheel/pages/tutorial/about_page.dart';
import 'package:lucky_wheel/pages/tutorial/onboarding_page.dart';
import 'package:lucky_wheel/pages/wheel/wheel_mode_page.dart';
import 'package:lucky_wheel/providers/settings_provider.dart';

/// Root widget that configures routing and theme.
class LuckyWheelApp extends ConsumerWidget {
  const LuckyWheelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Spinly Wheel Decision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      initialRoute: '/splash',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments;

    switch (routeSettings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      case '/wheel':
        return MaterialPageRoute(
          builder: (_) => const WheelModePage(),
          settings: routeSettings, // forward args (WheelType)
        );

      case '/box':
        return MaterialPageRoute(builder: (_) => const BoxPage());

      case '/duel':
        return MaterialPageRoute(builder: (_) => const DuelPage());

      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case '/chain':
        return MaterialPageRoute(builder: (_) => const ChainPage());

      case '/edit':
        return MaterialPageRoute(
          builder: (_) => const EditWheelPage(),
          settings: routeSettings, // forward args (WheelType)
        );

      case '/result':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ResultPage(
              result: args['result'] as String? ?? '',
              mode: args['mode'] as String? ?? 'wheel',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const ResultPage(result: ''),
        );

      case '/about':
        return MaterialPageRoute(
          builder: (_) => const AboutPage(url: AppConfig.aboutUrl),
        );

      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
