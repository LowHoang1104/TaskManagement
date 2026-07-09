import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/routes/app.dart';
import 'core/di/injection_container.dart' as di;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feature/presentation/providers/theme_provider.dart';

import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Remove the '#' from the URL in Flutter Web
  usePathUrlStrategy();

  // Initialize intl date formatting
  await initializeDateFormatting('en_US', null);

  // Initialize all dependencies (storage, network, etc.)
  await di.init();

  // Initialize SharedPreferences for theme
  final prefs = await SharedPreferences.getInstance();

  await SentryFlutter.init(
    (options) {
      // TODO: Replace with actual Sentry DSN when ready
      options.dsn = 'https://example@sentry.io/add-your-dsn-here';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      // ProviderScope is required by Riverpod
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const App(),
      ),
    ),
  );
}
