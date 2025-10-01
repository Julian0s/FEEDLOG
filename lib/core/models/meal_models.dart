import 'package:flutter/material.dart';

enum MealType { breakfast, lunch, dinner, snack }

MealType mealTypeFromString(String s) {
  switch (s.toLowerCase()) {
    case 'breakfast':
      return MealType.breakfast;
    case 'lunch':
      return MealType.lunch;
    case 'dinner':
      return MealType.dinner;
    default:
      return MealType.snack;
  }
}

String mealTypeLabel(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'Breakfast';
    case MealType.lunch:
      return 'Lunch';
    case MealType.dinner:
      return 'Dinner';
    case MealType.snack:
      return 'Snacks';
  }
}

@immutable
class Macros {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  // Micronutrients - Minerals (mg)
  final double calcium;
  final double iron;
  final double magnesium;
  final double zinc;
  final double potassium;
  final double sodium;

  // Micronutrients - Vitamins
  final double vitaminA; // IU or mcg
  final double vitaminC; // mg
  final double vitaminD; // IU or mcg
  final double vitaminE; // mg

  // Additional macros
  final double fiber; // g
  final double sugar; // g
  final double saturatedFat; // g
  final double cholesterol; // mg

  const Macros({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.calcium = 0,
    this.iron = 0,
    this.magnesium = 0,
    this.zinc = 0,
    this.potassium = 0,
    this.sodium = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.vitaminE = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.saturatedFat = 0,
    this.cholesterol = 0,
  });

  Macros copyWith({
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? calcium,
    double? iron,
    double? magnesium,
    double? zinc,
    double? potassium,
    double? sodium,
    double? vitaminA,
    double? vitaminC,
    double? vitaminD,
    double? vitaminE,
    double? fiber,
    double? sugar,
    double? saturatedFat,
    double? cholesterol,
  }) =>
      Macros(
        calories: calories ?? this.calories,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        calcium: calcium ?? this.calcium,
        iron: iron ?? this.iron,
        magnesium: magnesium ?? this.magnesium,
        zinc: zinc ?? this.zinc,
        potassium: potassium ?? this.potassium,
        sodium: sodium ?? this.sodium,
        vitaminA: vitaminA ?? this.vitaminA,
        vitaminC: vitaminC ?? this.vitaminC,
        vitaminD: vitaminD ?? this.vitaminD,
        vitaminE: vitaminE ?? this.vitaminE,
        fiber: fiber ?? this.fiber,
        sugar: sugar ?? this.sugar,
        saturatedFat: saturatedFat ?? this.saturatedFat,
        cholesterol: cholesterol ?? this.cholesterol,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'calcium': calcium,
        'iron': iron,
        'magnesium': magnesium,
        'zinc': zinc,
        'potassium': potassium,
        'sodium': sodium,
        'vitamin_a': vitaminA,
        'vitamin_c': vitaminC,
        'vitamin_d': vitaminD,
        'vitamin_e': vitaminE,
        'fiber': fiber,
        'sugar': sugar,
        'saturated_fat': saturatedFat,
        'cholesterol': cholesterol,
      };

  factory Macros.fromJson(Map<String, dynamic> json) => Macros(
        calories: (json['calories'] ?? 0).toDouble(),
        proteinG: (json['protein_g'] ?? 0).toDouble(),
        carbsG: (json['carbs_g'] ?? 0).toDouble(),
        fatG: (json['fat_g'] ?? 0).toDouble(),
        calcium: (json['calcium'] ?? 0).toDouble(),
        iron: (json['iron'] ?? 0).toDouble(),
        magnesium: (json['magnesium'] ?? 0).toDouble(),
        zinc: (json['zinc'] ?? 0).toDouble(),
        potassium: (json['potassium'] ?? 0).toDouble(),
        sodium: (json['sodium'] ?? 0).toDouble(),
        vitaminA: (json['vitamin_a'] ?? 0).toDouble(),
        vitaminC: (json['vitamin_c'] ?? 0).toDouble(),
        vitaminD: (json['vitamin_d'] ?? 0).toDouble(),
        vitaminE: (json['vitamin_e'] ?? 0).toDouble(),
        fiber: (json['fiber'] ?? 0).toDouble(),
        sugar: (json['sugar'] ?? 0).toDouble(),
        saturatedFat: (json['saturated_fat'] ?? 0).toDouble(),
        cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      );
}

@immutable
class FoodItem {
  final String name;
  final double quantity;
  final String unit;
  final Macros estimates;
  const FoodItem({required this.name, this.quantity = 0, this.unit = '', this.estimates = const Macros()});

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'estimates': estimates.toJson(),
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        name: (json['name'] ?? '').toString(),
        quantity: (json['quantity'] ?? 0).toDouble(),
        unit: (json['unit'] ?? '').toString(),
        estimates: json['estimates'] is Map<String, dynamic>
            ? Macros.fromJson(json['estimates'] as Map<String, dynamic>)
            : const Macros(),
      );
}

@immutable
class MealEntry {
  final String id;
  final DateTime date;
  final MealType mealType;
  final List<FoodItem> foods;
  final Macros totals;
  const MealEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.foods,
    this.totals = const Macros(),
  });

  MealEntry copyWith({
    String? id,
    DateTime? date,
    MealType? mealType,
    List<FoodItem>? foods,
    Macros? totals,
  }) {
    return MealEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foods: foods ?? this.foods,
      totals: totals ?? this.totals,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mealType': mealType.name,
        'foods': foods.map((e) => e.toJson()).toList(),
        'totals': totals.toJson(),
      };
}
