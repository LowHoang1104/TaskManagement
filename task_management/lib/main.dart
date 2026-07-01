import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/routes/app.dart';
import 'core/di/injection_container.dart' as di;
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Remove the '#' from the URL in Flutter Web
  usePathUrlStrategy();

  // Initialize intl date formatting
  await initializeDateFormatting('en_US', null);

  // Initialize all dependencies (storage, network, etc.)
  await di.init();

  runApp(
    // ProviderScope is required by Riverpod
    const ProviderScope(
      child: App(),
    ),
  );
}
