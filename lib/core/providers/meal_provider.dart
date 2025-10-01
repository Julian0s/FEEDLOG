import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/meal_models.dart';

class MealProvider with ChangeNotifier {
  // Map by date (yyyy-mm-dd) -> meals
  final Map<String, List<MealEntry>> _byDate = {};
  final DateTime _today = DateTime.now();

  DateTime get today => _today;

  String _keyOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<MealEntry> mealsFor(DateTime date) {
    return List.unmodifiable(_byDate[_keyOf(date)] ?? const <MealEntry>[]);
  }

  void addMeals(DateTime date, List<MealEntry> meals) {
    final key = _keyOf(date);
    final list = [...(_byDate[key] ?? const <MealEntry>[])];
    list.addAll(meals);
    _byDate[key] = list;
    notifyListeners();
  }

  void removeMeal(DateTime date, String id) {
    final key = _keyOf(date);
    final list = [...(_byDate[key] ?? const <MealEntry>[])];
    list.removeWhere((e) => e.id == id);
    _byDate[key] = list;
    notifyListeners();
  }

  Macros dailyTotals(DateTime date) {
    final list = _byDate[_keyOf(date)] ?? const <MealEntry>[];
    double c = 0, p = 0, cb = 0, f = 0;
    for (final m in list) {
      c += m.totals.calories;
      p += m.totals.proteinG;
      cb += m.totals.carbsG;
      f += m.totals.fatG;
    }
    return Macros(calories: c, proteinG: p, carbsG: cb, fatG: f);
  }

  // Helper to generate ID locally
  String newId() => Random().nextInt(1 << 32).toString();
}
