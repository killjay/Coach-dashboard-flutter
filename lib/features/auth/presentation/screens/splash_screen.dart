import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait a bit for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Skip authentication if disabled in config
    if (AppConfig.skipAuthentication) {
      // Navigate directly to default dashboard
      if (AppConfig.defaultRole == 'coach') {
        context.go(AppRoutes.coachDashboard);
      } else {
        context.go(AppRoutes.clientDashboard);
      }
      return;
    }

    // Normal authentication flow
    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user != null) {
      // User is authenticated, navigate to appropriate dashboard
      if (user.role == 'coach') {
        context.go(AppRoutes.coachDashboard);
      } else {
        context.go(AppRoutes.clientDashboard);
      }
    } else {
      // User is not authenticated, navigate to login
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Coach-Client App',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your fitness journey starts here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}


