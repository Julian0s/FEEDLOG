import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/firebase_meal_provider.dart';
import '../../core/providers/firebase_profile_provider.dart';
import 'widgets/pixel_grid_macro_card.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Preload today's meals from Firestore (for totals only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseMealProvider>().loadMealsForDate(DateTime.now());
      context.read<FirebaseProfileProvider>().loadFromFirestore();
    });
  }

  String _greetingForNow(BuildContext context) {
    final hour = DateTime.now().hour;
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    String morning = 'Good morning!';
    String afternoon = 'Good afternoon!';
    String evening = 'Good evening!';
    if (lang == 'pt') {
      morning = 'Bom dia!';
      afternoon = 'Boa tarde!';
      evening = 'Boa noite!';
    } else if (lang == 'es') {
      morning = '¡Buenos días!';
      afternoon = '¡Buenas tardes!';
      evening = '¡Buenas noches!';
    }
    if (hour < 12) return morning;
    if (hour < 18) return afternoon;
    return evening;
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<FirebaseMealProvider>();
    final profileProvider = context.watch<FirebaseProfileProvider>();
    final profile = profileProvider.profile;
    final totals = mealProvider.dailyTotals(DateTime.now());
    final goals = profile.macroTargets;

    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dateStr = DateFormat('EEE, d MMM', localeName).format(DateTime.now());

    Widget macroTile({
      required String title,
      required String unitSuffix,
      required double value,
      required double target,
      required Color color,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Text('/ ${target.toStringAsFixed(0)} $unitSuffix', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      );
    }

    Widget micronutrientList() {
      // Daily recommended values (RDA) - can be customized per user profile later
      final rdaMap = {
        'Calcium': 1000.0, // mg
        'Iron': 18.0, // mg
        'Magnesium': 400.0, // mg
        'Zinc': 11.0, // mg
        'Potassium': 3500.0, // mg
        'Sodium': 2300.0, // mg (max)
      };

      final items = [
        ('Calcium', totals.calcium, rdaMap['Calcium']!, 'mg'),
        ('Iron', totals.iron, rdaMap['Iron']!, 'mg'),
        ('Magnesium', totals.magnesium, rdaMap['Magnesium']!, 'mg'),
        ('Zinc', totals.zinc, rdaMap['Zinc']!, 'mg'),
        ('Potassium', totals.potassium, rdaMap['Potassium']!, 'mg'),
        ('Sodium', totals.sodium, rdaMap['Sodium']!, 'mg'),
      ];

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              ListTile(
                title: Text(items[i].$1),
                trailing: Text(
                  '${items[i].$2.toStringAsFixed(0)} / ${items[i].$3.toStringAsFixed(0)} ${items[i].$4}',
                  style: TextStyle(
                    color: items[i].$2 >= items[i].$3
                        ? Colors.green
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                dense: true,
              ),
              if (i < items.length - 1)
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
            ]
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_greetingForNow(context), style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(width: 6),
                            const Icon(Icons.wb_sunny_outlined, color: Colors.amber),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(profile.name.isNotEmpty ? profile.name : 'User',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text("Today's Nutrition", style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Chip(
                        avatar: const Icon(Icons.event, size: 16),
                        label: Text(dateStr),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Macros 2x2 grid with pixel grid cards
            GridView(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PixelGridMacroCard(
                  title: 'Calories',
                  current: totals.calories,
                  target: goals.calories,
                  unit: 'kcal',
                  color: const Color(0xFFFF3366), // Neon hot pink/red - Energy
                ),
                PixelGridMacroCard(
                  title: 'Proteins',
                  current: totals.proteinG,
                  target: goals.proteinG,
                  unit: 'g',
                  color: const Color(0xFF00FFAA), // Neon cyan/green - Growth
                ),
                PixelGridMacroCard(
                  title: 'Carbohydrates',
                  current: totals.carbsG,
                  target: goals.carbsG,
                  unit: 'g',
                  color: const Color(0xFFFFDD00), // Neon yellow - Energy
                ),
                PixelGridMacroCard(
                  title: 'Fats',
                  current: totals.fatG,
                  target: goals.fatG,
                  unit: 'g',
                  color: const Color(0xFFBB00FF), // Neon purple - Lipids
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Micronutrients list
            micronutrientList(),
          ],
        ),
      ),
    );
  }
}
