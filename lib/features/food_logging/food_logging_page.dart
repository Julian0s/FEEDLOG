import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/firebase_meal_provider.dart';
import '../../core/models/meal_models.dart';
import 'widgets/quick_add_meal_sheet.dart';

class FoodLoggingPage extends StatefulWidget {
  const FoodLoggingPage({super.key});

  @override
  State<FoodLoggingPage> createState() => _FoodLoggingPageState();
}

class _FoodLoggingPageState extends State<FoodLoggingPage> {
  bool monthly = false;
  DateTime anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load meals for the initial date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseMealProvider>().loadMealsForDate(anchor);
    });
  }

  void _selectDate(DateTime d) {
    setState(() => anchor = d);
    // Load meals when switching date
    context.read<FirebaseMealProvider>().loadMealsForDate(d);
  }

  Future<void> _openQuickAdd() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => QuickAddMealSheet(date: anchor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<FirebaseMealProvider>();
    final days = monthly ? 30 : 7;
    final start = anchor.subtract(Duration(days: days - 1));
    final dates = List.generate(days, (i) => start.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log'),
        actions: [
          IconButton(
            icon: Icon(monthly ? Icons.calendar_view_week : Icons.calendar_month),
            onPressed: () => setState(() => monthly = !monthly),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (ctx, i) {
                final d = dates[i];
                final isSelected = _isSameDay(d, anchor);
                return ChoiceChip(
                  label: Text('${d.month}/${d.day}'),
                  selected: isSelected,
                  onSelected: (_) => _selectDate(d),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: dates.length,
            ),
          ),
          Expanded(
            child: _MealsByTypeList(date: anchor, mealProvider: mealProvider),
          )
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MealsByTypeList extends StatelessWidget {
  final DateTime date;
  final FirebaseMealProvider mealProvider;
  const _MealsByTypeList({required this.date, required this.mealProvider});

  @override
  Widget build(BuildContext context) {
    final meals = mealProvider.mealsFor(date);
    if (mealProvider.isLoading && meals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (meals.isEmpty) {
      return const Center(child: Text('No meals for this day'));
    }
    final byType = <MealType, List<MealEntry>>{};
    for (final m in meals) {
      byType.putIfAbsent(m.mealType, () => []).add(m);
    }
    final ordered = [MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: ordered.where((t) => byType[t]?.isNotEmpty == true).map((t) {
        final items = byType[t]!;
        final totals = items.fold<Macros>(const Macros(), (acc, e) => Macros(
              calories: acc.calories + e.totals.calories,
              proteinG: acc.proteinG + e.totals.proteinG,
              carbsG: acc.carbsG + e.totals.carbsG,
              fatG: acc.fatG + e.totals.fatG,
            ));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mealTypeLabel(t), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...items.map((m) => Dismissible(
                  key: ValueKey(m.id + m.date.toIso8601String()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (dir) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete meal?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    await context.read<FirebaseMealProvider>().removeMeal(m);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meal deleted')),
                    );
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(m.foods.length, (idx) {
                            final f = m.foods[idx];
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        f.quantity > 0
                                            ? '${f.name} • ${f.quantity.toStringAsFixed(f.quantity % 1 == 0 ? 0 : 1)}${f.unit.isNotEmpty ? f.unit : ''}'
                                            : f.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${f.estimates.calories.toStringAsFixed(0)} kcal', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                        Text(
                                          '${f.estimates.proteinG.toStringAsFixed(0)}P · ${f.estimates.carbsG.toStringAsFixed(0)}C · ${f.estimates.fatG.toStringAsFixed(0)}F',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (idx != m.foods.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Divider(height: 1, color: Theme.of(context).dividerColor),
                                  ),
                              ],
                            );
                          }),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Subtotal: ${m.totals.calories.toStringAsFixed(0)} kcal',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('Total: ${totals.calories.toStringAsFixed(0)} kcal'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}
