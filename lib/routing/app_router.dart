import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/auth_choice_page.dart';
import '../features/auth/presentation/pages/phone_input_page.dart';
import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/auth/presentation/pages/email_auth_page.dart';
import '../features/auth/presentation/pages/onboarding/identity_page.dart';
import '../features/auth/presentation/pages/onboarding/interests_page.dart';
import '../features/auth/presentation/pages/onboarding/notifications_permission_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/feed/presentation/pages/feed_page.dart';
import '../features/alert/presentation/pages/alert_screen_page.dart';
import '../features/trends/presentation/pages/trends_page.dart';
import '../features/creation/presentation/pages/creation_hub_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../shared/widgets/main_shell.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: RouteNames.welcome,
    redirect: (context, state) {
      final isAuth = authController is AuthAuthenticated;
      final isLoading = authController is AuthInitial;
      final needsOnboarding = authController is AuthNeedsOnboarding;

      final isAuthRoute = state.fullPath?.startsWith('/auth') ?? false;
      final isOnboardingRoute = state.fullPath?.startsWith('/onboarding') ?? false;
      final isRootRoute = state.fullPath == RouteNames.welcome;

      if (isLoading) return null;

      // Si connecté et sur page auth/welcome → feed
      if (isAuth && (isAuthRoute || isRootRoute)) {
        return RouteNames.feed;
      }

      // Si onboarding requis
      if (needsOnboarding && !isOnboardingRoute) {
        return '${RouteNames.onboardingIdentity}?authId=${(authController as AuthNeedsOnboarding).authId}';
      }

      // Si non connecté et sur page protégée → welcome
      if (!isAuth && !isAuthRoute && !isOnboardingRoute && !isRootRoute) {
        return RouteNames.welcome;
      }

      return null;
    },
    routes: [
      // ── Welcome ──────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.welcome,
        builder: (_, __) => const WelcomePage(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.authChoice,
        builder: (_, __) => const AuthChoicePage(),
      ),
      GoRoute(
        path: RouteNames.authPhone,
        builder: (_, __) => const PhoneInputPage(),
      ),
      GoRoute(
        path: RouteNames.authOtp,
        builder: (_, state) => OtpVerificationPage(
          phone: state.extra as String,
        ),
      ),
      GoRoute(
        path: RouteNames.authEmail,
        builder: (_, __) => const EmailAuthPage(),
      ),

      // ── Onboarding ───────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.onboardingIdentity,
        builder: (_, state) {
          final authId = state.uri.queryParameters['authId'] ??
              (state.extra as String? ?? '');
          return IdentityPage(authId: authId);
        },
      ),
      GoRoute(
        path: RouteNames.onboardingInterests,
        builder: (_, state) => InterestsPage(
          userData: state.extra as Map<String, dynamic>,
        ),
      ),
      GoRoute(
        path: RouteNames.onboardingNotifications,
        builder: (_, state) => NotificationsPermissionPage(
          userData: state.extra as Map<String, dynamic>,
        ),
      ),

      // ── Alert (plein écran, pas dans le shell) ────────────────────────
      GoRoute(
        path: '/alert/:alertId',
        pageBuilder: (_, state) => CustomTransitionPage(
          child: AlertScreenPage(
            alertId: state.pathParameters['alertId'] ?? '',
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      ),

      // ── Shell principal (bottom nav) ──────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.feed,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: FeedPage()),
          ),
          GoRoute(
            path: RouteNames.trends,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: TrendsPage()),
          ),
          GoRoute(
            path: RouteNames.create,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CreationHubPage()),
          ),
          GoRoute(
            path: RouteNames.notifications,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: NotificationsPage()),
          ),
          GoRoute(
            path: RouteNames.myProfile,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProfilePage()),
          ),

          // Profile d'un autre utilisateur
          GoRoute(
            path: '/profile/:userId',
            builder: (_, state) => ProfilePage(
              userId: state.pathParameters['userId'],
            ),
          ),

          // Contenu individuel
          GoRoute(
            path: '/content/:id',
            builder: (_, state) => const FeedPage(),
          ),
        ],
      ),
    ],
  );
});
