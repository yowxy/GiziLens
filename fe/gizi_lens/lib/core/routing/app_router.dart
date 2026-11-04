import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/splash/views/splash_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (context, state) => const MaterialPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.splash01,
        name: 'splash01',
        pageBuilder: (context, state) => const MaterialPage(
          child: SplashScreen(
            autoStart: false,
            staticProgress: 0.05,
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.splash02,
        name: 'splash02',
        pageBuilder: (context, state) => const MaterialPage(
          child: SplashScreen(
            autoStart: false,
            staticProgress: 1.0,
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.splash03,
        name: 'splash03',
        pageBuilder: (context, state) => const MaterialPage(
          child: OnboardingScreen(initialPage: 0),
        ),
      ),
      GoRoute(
        path: RouteNames.splash04,
        name: 'splash04',
        pageBuilder: (context, state) => const MaterialPage(
          child: OnboardingScreen(initialPage: 1),
        ),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
    ],
  );
}
