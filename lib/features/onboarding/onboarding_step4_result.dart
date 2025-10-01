import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/firebase_profile_provider.dart';

class OnboardingStep4Result extends StatelessWidget {
  const OnboardingStep4Result({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<FirebaseProfileProvider>().profile;
    final macros = profile.macroTargets;

    // Rough timeline estimation: 0.5 kg/week delta
    String timeline() {
      if (profile.targetWeightKg <= 0 || profile.currentWeightKg <= 0) return '—';
      final delta = (profile.targetWeightKg - profile.currentWeightKg).abs();
      final weeks = (delta / 0.5).ceil();
      return weeks > 0 ? '$weeks weeks (est.)' : '—';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Step 4 of 4: Your Targets')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Calorie Needs', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${macros.calories.toStringAsFixed(0)} kcal'),
              const SizedBox(height: 16),
              Text('Macro Distribution', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip(context, 'Protein', '${macros.proteinG.toStringAsFixed(0)} g'),
                  const SizedBox(width: 8),
                  _chip(context, 'Carbs', '${macros.carbsG.toStringAsFixed(0)} g'),
                  const SizedBox(width: 8),
                  _chip(context, 'Fat', '${macros.fatG.toStringAsFixed(0)} g'),
                ],
              ),
              const SizedBox(height: 16),
              Text('Estimated timeline: ${timeline()}'),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Finish'),
                    onPressed: () async {
                      await context.read<FirebaseProfileProvider>().finalizeOnboarding();
                      if (context.mounted) {
                        context.go('/home');
                      }
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}
