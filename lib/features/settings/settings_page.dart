import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/firebase_profile_provider.dart';
import '../../core/providers/firebase_meal_provider.dart';
import '../../firestore/auth_service.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    Future<void> _signOut() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sign out')),
          ],
        ),
      );
      if (confirm != true) return;

      try {
        await context.read<AuthProvider>().signOut();
        await context.read<FirebaseProfileProvider>().clear();
        // Meals clear automatically via auth listener; clear explicitly if needed
        context.read<FirebaseMealProvider>();

        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sign out: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeProvider.mode.name),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.mode,
              onChanged: (m) => themeProvider.setMode(m ?? ThemeMode.system),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(localeProvider.locale?.toLanguageTag() ?? 'System'),
            trailing: DropdownButton<Locale?>(
              value: localeProvider.locale,
              onChanged: (l) => localeProvider.setLocale(l),
              items: const [
                DropdownMenuItem(value: null, child: Text('System')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('es'), child: Text('Español')),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('TDEE & Macros'),
            subtitle: Text(profileProvider.isOnboarded
                ? '${profileProvider.dailyTargets.calories.toStringAsFixed(0)} kcal • P ${profileProvider.dailyTargets.proteinG.toStringAsFixed(0)}g • C ${profileProvider.dailyTargets.carbsG.toStringAsFixed(0)}g • F ${profileProvider.dailyTargets.fatG.toStringAsFixed(0)}g'
                : 'Not set'),
            trailing: FilledButton.tonal(
              onPressed: () => context.go('/onboarding/step1'),
              child: const Text('Re-run'),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Subscriptions'),
            subtitle: Text('Stripe integration pending setup.'),
          ),
          const Divider(),
          const ListTile(
            title: Text('Cloud Backends'),
            subtitle: Text('Connect Firebase & Supabase from the left sidebar in Dreamflow.'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out'),
            onTap: _signOut,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
