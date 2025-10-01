import 'package:flutter/foundation.dart';
import 'meal_models.dart';

enum Gender { male, female }

enum ActivityLevel {
  sedentary(1.2, 'Sedentary'),
  light(1.375, 'Lightly active'),
  moderate(1.55, 'Moderately active'),
  active(1.725, 'Very active'),
  veryActive(1.9, 'Extremely active'),
  heavy(1.725, 'Very active'),
  athlete(1.9, 'Athlete');

  final double multiplier;
  final String label;
  const ActivityLevel(this.multiplier, this.label);
}

enum GoalType { loss, maintain, gain }

@immutable
class UserProfile {
  final String name;
  final int age;
  final Gender gender;
  final double heightCm;
  final double currentWeightKg;
  final ActivityLevel activityLevel;
  final GoalType goalType;
  final double targetWeightKg;
  final double tdee;
  final Macros macroTargets;
  final bool onboarded;

  const UserProfile({
    this.name = '',
    this.age = 0,
    this.gender = Gender.male,
    this.heightCm = 0,
    this.currentWeightKg = 0,
    this.activityLevel = ActivityLevel.sedentary,
    this.goalType = GoalType.maintain,
    this.targetWeightKg = 0,
    this.tdee = 0,
    this.macroTargets = const Macros(),
    this.onboarded = false,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    ActivityLevel? activityLevel,
    GoalType? goalType,
    double? targetWeightKg,
    double? tdee,
    Macros? macroTargets,
    bool? onboarded,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      tdee: tdee ?? this.tdee,
      macroTargets: macroTargets ?? this.macroTargets,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender.name,
      'height_cm': heightCm,
      'current_weight_kg': currentWeightKg,
      'activity_level': activityLevel.name,
      'goal_type': goalType.name,
      'target_weight_kg': targetWeightKg,
      'tdee': tdee,
      'macro_targets': macroTargets.toJson(),
      'onboarded': onboarded,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String g = (json['gender'] ?? 'male').toString();
    String al = (json['activity_level'] ?? 'sedentary').toString();
    String gt = (json['goal_type'] ?? 'maintain').toString();
    return UserProfile(
      name: (json['name'] ?? '').toString(),
      age: (json['age'] ?? 0) is int ? (json['age'] as int) : int.tryParse((json['age'] ?? '0').toString()) ?? 0,
      gender: g == 'female' ? Gender.female : Gender.male,
      heightCm: (json['height_cm'] ?? 0).toDouble(),
      currentWeightKg: (json['current_weight_kg'] ?? 0).toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == al,
        orElse: () => ActivityLevel.sedentary,
      ),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == gt,
        orElse: () => GoalType.maintain,
      ),
      targetWeightKg: (json['target_weight_kg'] ?? 0).toDouble(),
      tdee: (json['tdee'] ?? 0).toDouble(),
      macroTargets: json['macro_targets'] is Map<String, dynamic>
          ? Macros.fromJson(json['macro_targets'] as Map<String, dynamic>)
          : const Macros(),
      onboarded: (json['onboarded'] ?? false) == true,
    );
  }
}
