import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_models.dart';
import '../models/meal_models.dart';
import '../../firestore/firestore_service.dart';
import '../../firestore/firestore_data_schema.dart';
import '../../firestore/auth_service.dart';

/// Profile provider that integrates with Firebase Firestore
class FirebaseProfileProvider with ChangeNotifier {
  static const _prefsKey = 'user_profile_v1';
  UserProfile _profile = const UserProfile();
  bool _isLoading = false;
  String? _error;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserProfile get profile => _profile;
  bool get isOnboarded => _profile.onboarded;
  Macros get dailyTargets => _profile.macroTargets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FirebaseProfileProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(dynamic user) {
    if (user != null) {
      // User signed in, load profile from Firestore
      loadFromFirestore();
    } else {
      // User signed out, clear profile
      _profile = const UserProfile();
      notifyListeners();
    }
  }

  /// Load profile from local storage (fallback)
  Future<void> loadLocal() async {
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

  /// Load profile from Firestore
  Future<void> loadFromFirestore() async {
    if (!_authService.isAuthenticated) {
      await loadLocal();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final firestoreProfile = await _firestoreService.userProfiles.getCurrentUserProfile();
      
      if (firestoreProfile != null) {
        // Convert Firestore profile to local profile model
        _profile = UserProfile(
          name: firestoreProfile.displayName ?? '',
          age: firestoreProfile.age,
          gender: _parseGender(firestoreProfile.gender),
          heightCm: firestoreProfile.height,
          currentWeightKg: firestoreProfile.currentWeight,
          targetWeightKg: firestoreProfile.goalWeight ?? firestoreProfile.currentWeight,
          activityLevel: _parseActivityLevel(firestoreProfile.activityLevel),
          goalType: _parseGoalType(firestoreProfile.primaryGoal),
          tdee: 0.0, // Will be computed
          macroTargets: const Macros(), // Will be computed
          onboarded: true,
        );
        
        // Compute targets based on loaded data
        computeTargets();
        
        // Cache locally
        await _persistLocal();
      } else {
        // No profile in Firestore, load from local storage
        await loadLocal();
        // Seed with Firebase Auth displayName if available and name is empty
        final displayName = _authService.currentUser?.displayName;
        if ((_profile.name.isEmpty) && displayName != null && displayName.trim().isNotEmpty) {
          _profile = _profile.copyWith(name: displayName.trim());
          await _persistLocal();
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to load profile: $e');
      // Fallback to local storage
      await loadLocal();
      // Seed with Firebase Auth displayName if available and name is empty
      final displayName = _authService.currentUser?.displayName;
      if ((_profile.name.isEmpty) && displayName != null && displayName.trim().isNotEmpty) {
        _profile = _profile.copyWith(name: displayName.trim());
        await _persistLocal();
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Save profile to Firestore
  Future<void> saveToFirestore() async {
    if (!_authService.isAuthenticated) {
      await _persistLocal();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final uid = _authService.currentUserId!;
      final now = DateTime.now();
      
      final firestoreProfile = UserProfileFS(
        id: '', // Will be set by Firestore
        ownerId: uid,
        displayName: _profile.name,
        email: _authService.currentUser?.email,
        photoUrl: _authService.currentUser?.photoURL,
        age: _profile.age,
        gender: _profile.gender.name,
        height: _profile.heightCm,
        currentWeight: _profile.currentWeightKg,
        goalWeight: _profile.targetWeightKg,
        activityLevel: _profile.activityLevel.name,
        dietaryRestrictions: const [], // Could be extended
        allergies: const [], // Could be extended
        primaryGoal: _profile.goalType.name,
        createdAt: now,
        updatedAt: now,
      );
      
      await _firestoreService.userProfiles.saveProfile(firestoreProfile);
      
      // Also cache locally
      await _persistLocal();
      
    } catch (e) {
      _setError('Failed to save profile: $e');
      // Still persist locally as fallback
      await _persistLocal();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clear() async {
    _profile = const UserProfile();
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    
    // Note: We don't delete from Firestore here to preserve user data
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
    
    // Save to Firestore and local storage
    await saveToFirestore();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_profile.toJson()));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Utility methods to convert between local enums and Firestore strings
  Gender _parseGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.male;
    }
  }

  ActivityLevel _parseActivityLevel(String level) {
    switch (level.toLowerCase()) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'light':
        return ActivityLevel.light;
      case 'moderate':
        return ActivityLevel.moderate;
      case 'active':
        return ActivityLevel.active;
      case 'very_active':
        return ActivityLevel.veryActive;
      default:
        return ActivityLevel.moderate;
    }
  }

  GoalType _parseGoalType(String goal) {
    switch (goal.toLowerCase()) {
      case 'lose_weight':
      case 'loss':
        return GoalType.loss;
      case 'maintain_weight':
      case 'maintain':
        return GoalType.maintain;
      case 'gain_weight':
      case 'build_muscle':
      case 'gain':
        return GoalType.gain;
      default:
        return GoalType.maintain;
    }
  }
}