import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/meal_models.dart';
import '../../../core/providers/firebase_meal_provider.dart';

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _NumberField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  final MealType selected;
  final ValueChanged<MealType> onChanged;
  const _MealTypeSelector({required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MealType>(
      segments: const [
        ButtonSegment(value: MealType.breakfast, icon: Icon(Icons.free_breakfast), label: Text('Breakfast')),
        ButtonSegment(value: MealType.lunch, icon: Icon(Icons.lunch_dining), label: Text('Lunch')),
        ButtonSegment(value: MealType.dinner, icon: Icon(Icons.dinner_dining), label: Text('Dinner')),
        ButtonSegment(value: MealType.snack, icon: Icon(Icons.cookie), label: Text('Snack')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class QuickAddMealSheet extends StatefulWidget {
  final DateTime date;
  const QuickAddMealSheet({required this.date});
  @override
  State<QuickAddMealSheet> createState() => _QuickAddMealSheetState();
}

class _QuickAddMealSheetState extends State<QuickAddMealSheet> {
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  MealType _type = MealType.lunch;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final calories = double.tryParse(_calCtrl.text.trim()) ?? 0;
      final protein = double.tryParse(_proCtrl.text.trim()) ?? 0;
      final carbs = double.tryParse(_carbCtrl.text.trim()) ?? 0;
      final fat = double.tryParse(_fatCtrl.text.trim()) ?? 0;
      final name = _nameCtrl.text.trim().isEmpty ? 'Meal' : _nameCtrl.text.trim();

      final item = FoodItem(
        name: name,
        quantity: 1,
        unit: 'portion',
        estimates: Macros(calories: calories, proteinG: protein, carbsG: carbs, fatG: fat),
      );
      final entry = MealEntry(
        id: '',
        date: DateTime(widget.date.year, widget.date.month, widget.date.day),
        mealType: _type,
        foods: [item],
        totals: item.estimates,
      );
      final fbMeals = context.read<FirebaseMealProvider>();
      await fbMeals.addMeal(entry);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal added')));
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu),
                  const SizedBox(width: 8),
                  Text('Quick Add Meal', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _MealTypeSelector(selected: _type, onChanged: (t) => setState(() => _type = t)),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g., Chicken bowl',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _NumberField(controller: _calCtrl, label: 'Calories')),
                  const SizedBox(width: 8),
                  Expanded(child: _NumberField(controller: _proCtrl, label: 'Protein (g)')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _NumberField(controller: _carbCtrl, label: 'Carbs (g)')),
                  const SizedBox(width: 8),
                  Expanded(child: _NumberField(controller: _fatCtrl, label: 'Fat (g)')),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                label: const Text('Save Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
