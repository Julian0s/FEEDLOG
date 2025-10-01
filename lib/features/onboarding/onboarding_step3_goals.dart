import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/firebase_profile_provider.dart';
import '../../core/models/profile_models.dart';

class OnboardingStep3Goals extends StatefulWidget {
  const OnboardingStep3Goals({super.key});

  @override
  State<OnboardingStep3Goals> createState() => _OnboardingStep3GoalsState();
}

class _OnboardingStep3GoalsState extends State<OnboardingStep3Goals> {
  GoalType _selected = GoalType.maintain;
  final _targetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize once from provider without listening.
    final p = context.read<FirebaseProfileProvider>().profile;
    _selected = p.goalType;
    if (p.targetWeightKg > 0) {
      _targetCtrl.text = p.targetWeightKg.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch only to rebuild dependent UI if needed, but do not overwrite local selection.
    context.watch<FirebaseProfileProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Step 3 of 4: Goals')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pick your goal and target weight', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<GoalType>(
                segments: const [
                  ButtonSegment(value: GoalType.loss, icon: Icon(Icons.trending_down), label: Text('Lose')),
                  ButtonSegment(value: GoalType.maintain, icon: Icon(Icons.horizontal_rule), label: Text('Maintain')),
                  ButtonSegment(value: GoalType.gain, icon: Icon(Icons.trending_up), label: Text('Gain')),
                ],
                selected: {_selected},
                onSelectionChanged: (s) => setState(() => _selected = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target weight (kg)',
                  helperText: 'Estimate timeline will be shown in next step',
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final target = double.tryParse(_targetCtrl.text.trim()) ?? 0;
                      context.read<FirebaseProfileProvider>().setGoals(goal: _selected, targetWeightKg: target);
                      context.read<FirebaseProfileProvider>().computeTargets();
                      context.push('/onboarding/step4');
                    },
                    child: const Text('See Results'),
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
