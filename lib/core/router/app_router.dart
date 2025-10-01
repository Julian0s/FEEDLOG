import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/welcome/welcome_page.dart';
import '../../features/home/home_dashboard_page.dart';
import '../../features/food_logging/food_logging_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/onboarding/onboarding_step1_personal.dart';
import '../../features/onboarding/onboarding_step2_activity.dart';
import '../../features/onboarding/onboarding_step3_goals.dart';
import '../../features/onboarding/onboarding_step4_result.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/signup_page.dart';
import '../../features/auth/auth_wrapper.dart';
import '../widgets/global_chat_fab.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../firestore/auth_service.dart';

class AppRouterConfig {
  static GoRouter build() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthWrapper(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: '/onboarding/step1',
          builder: (context, state) => const OnboardingStep1Personal(),
        ),
        GoRoute(
          path: '/onboarding/step2',
          builder: (context, state) => const OnboardingStep2Activity(),
        ),
        GoRoute(
          path: '/onboarding/step3',
          builder: (context, state) => const OnboardingStep3Goals(),
        ),
        GoRoute(
          path: '/onboarding/step4',
          builder: (context, state) => const OnboardingStep4Result(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            // Auth guard for all shell routes
            return Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return StreamBuilder<Object?>(
                  stream: auth.authStateChanges,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _ShellSplash();
                    }
                    if (!snapshot.hasData) {
                      // Not authenticated → send to Login
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final loc = GoRouter.of(context).state.matchedLocation;
                        if (loc != '/login') context.go('/login');
                      });
                      return const _ShellSplash();
                    }

                    final showFab = state.matchedLocation != '/settings';
                    return Scaffold(
                      body: SafeArea(child: child),
                      bottomNavigationBar: _NavBar(current: state.matchedLocation),
                      floatingActionButton: showFab ? const GlobalChatFAB() : null,
                    );
                  },
                );
              },
            );
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeDashboardPage(),
            ),
            GoRoute(
              path: '/log',
              builder: (context, state) => const FoodLoggingPage(),
            ),
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressPage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShellSplash extends StatelessWidget {
  const _ShellSplash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final String current;
  const _NavBar({required this.current});
  @override
  Widget build(BuildContext context) {
    int index = 0;
    if (current.startsWith('/home')) index = 0;
    if (current.startsWith('/log')) index = 1;
    if (current.startsWith('/progress')) index = 2;
    if (current.startsWith('/settings')) index = 3;

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/log');
            break;
          case 2:
            context.go('/progress');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Log'),
        NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progress'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
