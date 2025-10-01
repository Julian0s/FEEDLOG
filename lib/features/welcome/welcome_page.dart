import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/profile_provider.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.t('welcome_title'), style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Log meals by chatting naturally or snapping nutrition labels. Track macros, progress, and reach your goals.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final isDone = context.read<ProfileProvider?>()?.isOnboarded ?? false;
                  if (isDone) {
                    context.go('/home');
                  } else {
                    context.go('/onboarding/step1');
                  }
                },
                child: Text(t.t('get_started')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
