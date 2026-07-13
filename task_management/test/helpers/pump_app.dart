import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/app/routes/app_routes.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    Map<String, WidgetBuilder> routes = const {},
    NavigatorObserver? navigatorObserver,
  }) async {
    return pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: widget,
          routes: {
            AppRoutes.register: (_) => const Scaffold(body: Text('RegisterScreen')),
            AppRoutes.workspaceList: (_) => const Scaffold(body: Text('WorkspaceListScreen')),
            ...routes,
          },
          navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
        ),
      ),
    );
  }
}
