import 'package:flutter/foundation.dart';
import '../models/meal_models.dart';
import '../../firestore/firestore_service.dart';
import '../../firestore/firestore_data_schema.dart';
import '../../firestore/auth_service.dart';

/// Meal provider that integrates with Firebase Firestore
class FirebaseMealProvider with ChangeNotifier {
  final Map<String, List<MealEntry>> _mealsByDate = {};
  bool _isLoading = false;
  String? _error;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool get isLoading => _isLoading;
  String? get error => _error;

  FirebaseMealProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(dynamic user) {
    if (user == null) {
      // User signed out, clear meals
      _mealsByDate.clear();
      notifyListeners();
    }
  }

  /// Get meals for a specific date
  List<MealEntry> mealsFor(DateTime date) {
    final key = _dateKey(date);
    return _mealsByDate[key] ?? const <MealEntry>[];
  }

  /// Load meals for a specific date from Firestore
  Future<List<MealEntry>> loadMealsForDate(DateTime date) async {
    if (!_authService.isAuthenticated) return [];

    _setLoading(true);
    _clearError();

    try {
      final firestoreMeals = await _firestoreService.userMeals.getMealsForDate(date);
      
      // Convert Firestore meals to local meal models
      final meals = firestoreMeals.map((fm) => _convertFromFirestore(fm)).toList();
      
      // Cache locally
      final key = _dateKey(date);
      _mealsByDate[key] = meals;
      
      notifyListeners();
      return meals;
    } catch (e) {
      _setError('Failed to load meals: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Load meals for a date range from Firestore
  Future<void> loadMealsForDateRange(DateTime startDate, DateTime endDate) async {
    if (!_authService.isAuthenticated) return;

    _setLoading(true);
    _clearError();

    try {
      final firestoreMeals = await _firestoreService.userMeals.getMealsForDateRange(startDate, endDate);
      
      // Group meals by date and convert to local models
      final mealsByDate = <String, List<MealEntry>>{};
      
      for (final fm in firestoreMeals) {
        final meal = _convertFromFirestore(fm);
        final key = _dateKey(meal.date);
        
        mealsByDate[key] ??= <MealEntry>[];
        mealsByDate[key]!.add(meal);
      }
      
      // Update cache
      _mealsByDate.addAll(mealsByDate);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load meals: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add meal to Firestore and local cache
  Future<void> addMeal(MealEntry meal) async {
    if (!_authService.isAuthenticated) return;

    _setLoading(true);
    _clearError();

    try {
      // Convert to Firestore format
      final firestoreMeal = _convertToFirestore(meal);
      
      // Save to Firestore
      final mealId = await _firestoreService.userMeals.create(firestoreMeal);
      
      // Update local cache with the new ID
      final updatedMeal = meal.copyWith(id: mealId);
      final key = _dateKey(meal.date);
      _mealsByDate[key] ??= <MealEntry>[];
      _mealsByDate[key]!.add(updatedMeal);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add meal: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update meal in Firestore and local cache
  Future<void> updateMeal(MealEntry meal) async {
    if (!_authService.isAuthenticated || meal.id.isEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      // Convert to Firestore format
      final firestoreMeal = _convertToFirestore(meal);
      
      // Update in Firestore
      await _firestoreService.userMeals.update(meal.id, firestoreMeal);
      
      // Update local cache
      final key = _dateKey(meal.date);
      final meals = _mealsByDate[key] ?? <MealEntry>[];
      final index = meals.indexWhere((m) => m.id == meal.id);
      
      if (index >= 0) {
        meals[index] = meal;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update meal: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove meal from Firestore and local cache
  Future<void> removeMeal(MealEntry meal) async {
    if (!_authService.isAuthenticated || meal.id.isEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      // Delete from Firestore
      await _firestoreService.userMeals.delete(meal.id);
      
      // Remove from local cache
      final key = _dateKey(meal.date);
      final meals = _mealsByDate[key] ?? <MealEntry>[];
      meals.removeWhere((m) => m.id == meal.id);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove meal: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Calculate daily totals for a specific date
  Macros dailyTotals(DateTime date) {
    final meals = mealsFor(date);
    return meals.fold(
      const Macros(),
      (total, meal) => Macros(
        calories: total.calories + meal.totals.calories,
        proteinG: total.proteinG + meal.totals.proteinG,
        carbsG: total.carbsG + meal.totals.carbsG,
        fatG: total.fatG + meal.totals.fatG,
      ),
    );
  }

  /// Get meals by type for a specific date
  Future<List<MealEntry>> getMealsByType(DateTime date, MealType type) async {
    final meals = await loadMealsForDate(date);
    return meals.where((meal) => meal.mealType == type).toList();
  }

  /// Listen to meals for a date range (real-time updates)
  Stream<List<MealEntry>> getMealsForDateRangeStream(DateTime startDate, DateTime endDate) {
    if (!_authService.isAuthenticated) {
      return Stream.value([]);
    }

    return _firestoreService.userMeals
        .getMealsForDateRangeStream(startDate, endDate)
        .map((firestoreMeals) {
      // Update local cache
      final mealsByDate = <String, List<MealEntry>>{};
      
      for (final fm in firestoreMeals) {
        final meal = _convertFromFirestore(fm);
        final key = _dateKey(meal.date);
        
        mealsByDate[key] ??= <MealEntry>[];
        mealsByDate[key]!.add(meal);
      }
      
      // Update cache and notify
      _mealsByDate.clear();
      _mealsByDate.addAll(mealsByDate);
      
      // Return flattened list
      return firestoreMeals.map((fm) => _convertFromFirestore(fm)).toList();
    });
  }

  /// Convert local MealEntry to Firestore format
  UserMealFS _convertToFirestore(MealEntry meal) {
    final uid = _authService.currentUserId!;
    final now = DateTime.now();
    
    return UserMealFS(
      id: meal.id,
      ownerId: uid,
      mealType: meal.mealType.name,
      name: 'Meal',
      description: null,
      photoUrls: null,
      calories: meal.totals.calories,
      protein: meal.totals.proteinG,
      carbs: meal.totals.carbsG,
      fat: meal.totals.fatG,
      fiber: null,
      sugar: null,
      sodium: null,
      aiAnalysis: null,
      foodItems: meal.foods
          .map(
            (f) => FoodItemFS(
              id: '',
              name: f.name,
              servingSize: f.quantity,
              servingUnit: f.unit,
              caloriesPerServing: f.estimates.calories,
              proteinPerServing: f.estimates.proteinG,
              carbsPerServing: f.estimates.carbsG,
              fatPerServing: f.estimates.fatG,
              quantity: 1.0,
              createdAt: now,
            ),
          )
          .toList(),
      date: meal.date,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert Firestore format to local MealEntry
  MealEntry _convertFromFirestore(UserMealFS firestoreMeal) {
    // Build foods list from Firestore food items (if present)
    final foods = firestoreMeal.foodItems.map((fi) {
      final estimates = Macros(
        calories: (fi.caloriesPerServing ?? 0) * (fi.quantity),
        proteinG: (fi.proteinPerServing ?? 0) * (fi.quantity),
        carbsG: (fi.carbsPerServing ?? 0) * (fi.quantity),
        fatG: (fi.fatPerServing ?? 0) * (fi.quantity),
      );
      return FoodItem(
        name: fi.name,
        quantity: fi.servingSize ?? fi.quantity,
        unit: fi.servingUnit ?? '',
        estimates: estimates,
      );
    }).toList();

    final totals = Macros(
      calories: firestoreMeal.calories ?? 0.0,
      proteinG: firestoreMeal.protein ?? 0.0,
      carbsG: firestoreMeal.carbs ?? 0.0,
      fatG: firestoreMeal.fat ?? 0.0,
    );

    return MealEntry(
      id: firestoreMeal.id,
      date: firestoreMeal.date,
      mealType: _parseMealType(firestoreMeal.mealType),
      foods: foods,
      totals: totals,
    );
  }

  /// Parse meal type from Firestore string
  MealType _parseMealType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      default:
        return MealType.breakfast;
    }
  }

  /// Generate date key for caching
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
}
