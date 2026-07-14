import 'package:flutter/material.dart';
import '../../feature/presentation/screens/auth/splash_screen.dart';
import '../../feature/presentation/screens/auth/login_screen.dart';
import '../../feature/presentation/screens/auth/register_screen.dart';
import '../../feature/presentation/screens/auth/verify_email_screen.dart';
import '../../feature/presentation/screens/profile/profile_screen.dart';
import '../../feature/presentation/screens/profile/change_password_screen.dart';
import '../../feature/presentation/taskflow/screens/taskflow_shell.dart';
import 'app_routes.dart';

/// Centralized route generator. The app now runs entirely on the redesigned
/// TaskFlow UI — navigation into projects/tasks/etc. happens inside
/// [TaskFlowShell] via in-tree `Navigator.push`, so only the top-level
/// destinations need named routes here.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Auth ────────────────────────────────────────────────────────────
      case AppRoutes.splash:
        return _build(const SplashScreen(), settings);

      case AppRoutes.login:
        return _build(const LoginScreen(), settings);

      case AppRoutes.register:
        return _build(const RegisterScreen(), settings);

      case AppRoutes.verifyEmail:
        final email = settings.arguments as String? ?? 'an.nguyen@acme.co';
        return _build(VerifyEmailScreen(email: email), settings);

      // ── Home shell (redesigned TaskFlow) ─────────────────────────────────
      case AppRoutes.home:
        return _build(const TaskFlowShell(), settings);

      // ── Profile & settings ───────────────────────────────────────────────
      case AppRoutes.profile:
        return _build(const ProfileScreen(), settings);

      case AppRoutes.changePassword:
        return _build(const ChangePasswordScreen(), settings);

      default:
        return _build(
          const _PlaceholderScreen(title: '404 – Not Found'),
          settings,
        );
    }
  }

  static MaterialPageRoute _build(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

/// Fallback screen for unknown routes.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
