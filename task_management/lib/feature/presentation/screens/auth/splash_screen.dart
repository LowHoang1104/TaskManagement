import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkAuth());
  }

  Future<void> _checkAuth() async {
    // Check auth status concurrently with splash delay
    final timer = Future.delayed(const Duration(milliseconds: 2000));
    final authSuccess = await ref.read(authNotifierProvider.notifier).checkAuthStatus();
    
    await timer;
    
    if (mounted) {
      if (authSuccess) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo (using an Icon for now)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            )
                .animate()
                .scale(
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // Animated App Name
            const Text(
              'TaskFlow',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            )
                .animate(delay: 400.ms)
                .slideY(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            // Animated Slogan
            const Text(
              'Manage your work easily.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            )
                .animate(delay: 600.ms)
                .slideY(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
