import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/views/complete_profile_screen.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_verification_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/register_success_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/history/views/history_screen.dart';
import '../../features/inspection/views/menu_inspection_screen.dart';
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
      // Auth 1 (Login - 1auth.png)
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0.0),
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
          transitionDuration: const Duration(milliseconds: 320),
        ),
      ),
      // Auth 1 Alias (Quick inspection)
      GoRoute(
        path: RouteNames.auth1,
        name: 'auth1',
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),
      // Register Screen (02 registrasi.png)
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0.0),
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
          transitionDuration: const Duration(milliseconds: 320),
        ),
      ),
      // Forgot Password Screen (Input email before OTP)
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0.0),
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
          transitionDuration: const Duration(milliseconds: 320),
        ),
      ),
      // OTP Verification Screen (otp.png)
      GoRoute(
        path: RouteNames.otpVerification,
        name: 'otpVerification',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: OtpVerificationScreen(
              initialEmail: extra?['email'] as String?,
              initialPhone: extra?['phone'] as String?,
              fullName: extra?['fullName'] as String?,
              isForgotPassword: extra?['isForgotPassword'] as bool? ?? false,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0.0),
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
            transitionDuration: const Duration(milliseconds: 320),
          );
        },
      ),
      // Registration Success Screen (02 registrasi berhasil.png)
      GoRoute(
        path: RouteNames.registerSuccess,
        name: 'registerSuccess',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: RegisterSuccessScreen(
              email: extra?['email'] as String?,
              fullName: extra?['fullName'] as String?,
              role: extra?['role'] as String?,
              unit: extra?['unit'] as String?,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0.0),
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
            transitionDuration: const Duration(milliseconds: 320),
          );
        },
      ),
      // Direct Reference Inspection Routes
      GoRoute(
        path: RouteNames.refRegister,
        name: 'refRegister',
        pageBuilder: (context, state) => const MaterialPage(
          child: RegisterScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.refOtp,
        name: 'refOtp',
        pageBuilder: (context, state) => const MaterialPage(
          child: OtpVerificationScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.refRegisterSuccess,
        name: 'refRegisterSuccess',
        pageBuilder: (context, state) => const MaterialPage(
          child: RegisterSuccessScreen(autoRedirect: false),
        ),
      ),
      // Auth 2 (Complete Profile - 2auth.png)
      GoRoute(
        path: RouteNames.completeProfile,
        name: 'completeProfile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CompleteProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0.0),
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
          transitionDuration: const Duration(milliseconds: 320),
        ),
      ),
      // Auth 2 Alias (Quick inspection)
      GoRoute(
        path: RouteNames.auth2,
        name: 'auth2',
        pageBuilder: (context, state) => const MaterialPage(
          child: CompleteProfileScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => const MaterialPage(
          child: DashboardScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.history,
        name: 'history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      ),
      // Menu Inspection Step 1: Data Batch (05 - Input Data Batch & Periksa Menu.png)
      GoRoute(
        path: RouteNames.menuInspection,
        name: 'menuInspection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MenuInspectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0.0),
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
          transitionDuration: const Duration(milliseconds: 320),
        ),
      ),
      GoRoute(
        path: RouteNames.refMenuInspection,
        name: 'refMenuInspection',
        pageBuilder: (context, state) => const MaterialPage(
          child: MenuInspectionScreen(),
        ),
      ),
    ],
  );
}
