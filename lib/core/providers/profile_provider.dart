import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_models.dart';
import '../models/meal_models.dart';

class ProfileProvider with ChangeNotifier {
  static const _prefsKey = 'user_profile_v1';
  UserProfile _profile = const UserProfile();

  UserProfile get profile => _profile;
  bool get isOnboarded => _profile.onboarded;
  Macros get dailyTargets => _profile.macroTargets;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _profile = UserProfile.fromJson(map);
      } catch (_) {
        // ignore malformed
      }
    }
    notifyListeners();
  }

  Future<void> clear() async {
    _profile = const UserProfile();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void setBasicInfo({
    required String name,
    required int age,
    required Gender gender,
    required double heightCm,
    required double currentWeightKg,
  }) {
    _profile = _profile.copyWith(
      name: name,
      age: age,
      gender: gender,
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
    );
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel level) {
    _profile = _profile.copyWith(activityLevel: level);
    notifyListeners();
  }

  void setGoals({required GoalType goal, required double targetWeightKg}) {
    _profile = _profile.copyWith(goalType: goal, targetWeightKg: targetWeightKg);
    notifyListeners();
  }

  // Harris-Benedict BMR + TDEE, then macros 25/45/30
  void computeTargets() {
    final p = _profile;
    final bmr = p.gender == Gender.male
        ? (88.362 + 13.397 * p.currentWeightKg + 4.799 * p.heightCm - 5.677 * p.age)
        : (447.593 + 9.247 * p.currentWeightKg + 3.098 * p.heightCm - 4.330 * p.age);

    double tdee = bmr * p.activityLevel.multiplier;

    // Optionally nudge based on goal (~10% deficit/surplus)
    switch (p.goalType) {
      case GoalType.loss:
        tdee = tdee * 0.9;
        break;
      case GoalType.maintain:
        break;
      case GoalType.gain:
        tdee = tdee * 1.1;
        break;
    }

    final proteinCal = tdee * 0.25;
    final carbsCal = tdee * 0.45;
    final fatCal = tdee * 0.30;

    final macros = Macros(
      calories: tdee,
      proteinG: proteinCal / 4.0,
      carbsG: carbsCal / 4.0,
      fatG: fatCal / 9.0,
    );

    _profile = _profile.copyWith(tdee: tdee, macroTargets: macros);
    notifyListeners();
  }

  Future<void> finalizeOnboarding() async {
    _profile = _profile.copyWith(onboarded: true);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_profile.toJson()));
  }
}
