import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../firestore/auth_service.dart';
import '../../core/providers/firebase_profile_provider.dart';
import 'login_page.dart';

/// Wrapper that observes auth + profile and redirects accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, FirebaseProfileProvider>(
      builder: (context, authProvider, profileProvider, child) {
        return StreamBuilder<Object?>(
          stream: authProvider.authStateChanges,
          builder: (context, snapshot) {
            // While we don't know auth state yet
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SplashLoading();
            }

            // Not signed in → show Login
            if (!snapshot.hasData) {
              return const LoginPage();
            }

            // Signed in: wait for profile to load from Firestore/local
            if (profileProvider.isLoading) {
              return const _SplashLoading();
            }

            // Decide destination by onboarding flag and current location
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final onboarded = profileProvider.isOnboarded;
              final current = GoRouter.of(context).state.matchedLocation;
              final inOnboarding = current.startsWith('/onboarding');

              if (!onboarded) {
                // If not onboarded, keep user inside onboarding flow.
                if (!inOnboarding) {
                  context.go('/onboarding/step1');
                }
              } else {
                // If onboarded, avoid onboarding routes.
                if (inOnboarding || current == '/' || current == '/welcome' || current == '/login' || current == '/signup') {
                  context.go('/home');
                }
              }
            });

            // Intermediate shell while redirecting
            return const _SplashLoading();
          },
        );
      },
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
