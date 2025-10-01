import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/firebase_profile_provider.dart';
import '../../core/models/profile_models.dart';

class OnboardingStep2Activity extends StatelessWidget {
  const OnboardingStep2Activity({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<FirebaseProfileProvider>().profile;
    final selected = profile.activityLevel;

    Widget card(ActivityLevel level, IconData icon, String desc) {
      final isSel = selected == level;
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isSel ? 1 : 0,
        color: isSel ? Theme.of(context).colorScheme.primaryContainer : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.read<FirebaseProfileProvider>().setActivityLevel(level);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: isSel ? Theme.of(context).colorScheme.primary : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(level.label, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(desc, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (isSel) const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Step 2 of 4: Activity')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose your typical daily activity level', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    card(ActivityLevel.sedentary, Icons.chair_alt, 'Desk job, little exercise (x1.2)'),
                    card(ActivityLevel.light, Icons.directions_walk, 'Light exercise 1-3 days/week (x1.375)'),
                    card(ActivityLevel.moderate, Icons.directions_run, 'Moderate exercise 3-5 days/week (x1.55)'),
                    card(ActivityLevel.heavy, Icons.fitness_center, 'Hard exercise 6-7 days/week (x1.725)'),
                    card(ActivityLevel.athlete, Icons.sports_martial_arts, 'Very hard exercise/physical job (x1.9)'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.push('/onboarding/step3'),
                    child: const Text('Continue'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
