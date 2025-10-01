import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/firebase_profile_provider.dart';
import '../../core/models/profile_models.dart';

class OnboardingStep1Personal extends StatefulWidget {
  const OnboardingStep1Personal({super.key});

  @override
  State<OnboardingStep1Personal> createState() => _OnboardingStep1PersonalState();
}

class _OnboardingStep1PersonalState extends State<OnboardingStep1Personal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  Gender _gender = Gender.male;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<FirebaseProfileProvider>().profile;
    if (_nameCtrl.text.isEmpty && profile.name.isNotEmpty) {
      _nameCtrl.text = profile.name;
      _ageCtrl.text = profile.age > 0 ? profile.age.toString() : '';
      _heightCtrl.text = profile.heightCm > 0 ? profile.heightCm.toStringAsFixed(0) : '';
      _weightCtrl.text = profile.currentWeightKg > 0 ? profile.currentWeightKg.toStringAsFixed(1) : '';
      _gender = profile.gender;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Step 1 of 4: About You')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Let\'s personalize your targets', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Gender>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: Gender.male, child: Text('Male')),
                  DropdownMenuItem(value: Gender.female, child: Text('Female')),
                ],
                onChanged: (g) => setState(() => _gender = g ?? Gender.male),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageCtrl,
                decoration: const InputDecoration(labelText: 'Age (years)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 10 || n > 100) return 'Enter a valid age';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightCtrl,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 100 || n > 250) return 'Enter a valid height in cm';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightCtrl,
                decoration: const InputDecoration(labelText: 'Current weight (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 30 || n > 400) return 'Enter a valid weight in kg';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    context.read<FirebaseProfileProvider>().setBasicInfo(
                          name: _nameCtrl.text.trim(),
                          age: int.parse(_ageCtrl.text.trim()),
                          gender: _gender,
                          heightCm: double.parse(_heightCtrl.text.trim()),
                          currentWeightKg: double.parse(_weightCtrl.text.trim()),
                        );
                    context.push('/onboarding/step2');
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
