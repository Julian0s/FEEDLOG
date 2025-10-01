import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data schema for FEEDLOG app
/// This file defines the structure and models for Firebase Firestore collections

// User Profile Data Schema
class UserProfileFS {
  final String id;
  final String ownerId;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int age;
  final String gender; // 'male', 'female', 'other'
  final double height; // in cm
  final double currentWeight; // in kg
  final double? goalWeight; // in kg
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final String primaryGoal; // 'lose_weight', 'gain_weight', 'maintain_weight', 'build_muscle'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileFS({
    required this.id,
    required this.ownerId,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.age,
    required this.gender,
    required this.height,
    required this.currentWeight,
    this.goalWeight,
    required this.activityLevel,
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    required this.primaryGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'display_name': displayName,
    'email': email,
    'photo_url': photoUrl,
    'age': age,
    'gender': gender,
    'height': height,
    'current_weight': currentWeight,
    'goal_weight': goalWeight,
    'activity_level': activityLevel,
    'dietary_restrictions': dietaryRestrictions,
    'allergies': allergies,
    'primary_goal': primaryGoal,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  factory UserProfileFS.fromJson(String id, Map<String, dynamic> json) => UserProfileFS(
    id: id,
    ownerId: json['owner_id'],
    displayName: json['display_name'],
    email: json['email'],
    photoUrl: json['photo_url'],
    age: json['age'],
    gender: json['gender'],
    height: json['height'].toDouble(),
    currentWeight: json['current_weight'].toDouble(),
    goalWeight: json['goal_weight']?.toDouble(),
    activityLevel: json['activity_level'],
    dietaryRestrictions: List<String>.from(json['dietary_restrictions'] ?? []),
    allergies: List<String>.from(json['allergies'] ?? []),
    primaryGoal: json['primary_goal'],
    createdAt: (json['created_at'] as Timestamp).toDate(),
    updatedAt: (json['updated_at'] as Timestamp).toDate(),
  );
}

// User Meal Entry Data Schema
class UserMealFS {
  final String id;
  final String ownerId;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String name;
  final String? description;
  final List<String>? photoUrls;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String? aiAnalysis;
  final List<FoodItemFS> foodItems;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserMealFS({
    required this.id,
    required this.ownerId,
    required this.mealType,
    required this.name,
    this.description,
    this.photoUrls,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.aiAnalysis,
    this.foodItems = const [],
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'meal_type': mealType,
    'name': name,
    'description': description,
    'photo_urls': photoUrls,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'sodium': sodium,
    'ai_analysis': aiAnalysis,
    'food_items': foodItems.map((item) => item.toJson()).toList(),
    'date': Timestamp.fromDate(date),
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  factory UserMealFS.fromJson(String id, Map<String, dynamic> json) => UserMealFS(
    id: id,
    ownerId: json['owner_id'],
    mealType: json['meal_type'],
    name: json['name'],
    description: json['description'],
    photoUrls: json['photo_urls'] != null ? List<String>.from(json['photo_urls']) : null,
    calories: json['calories']?.toDouble(),
    protein: json['protein']?.toDouble(),
    carbs: json['carbs']?.toDouble(),
    fat: json['fat']?.toDouble(),
    fiber: json['fiber']?.toDouble(),
    sugar: json['sugar']?.toDouble(),
    sodium: json['sodium']?.toDouble(),
    aiAnalysis: json['ai_analysis'],
    foodItems: json['food_items'] != null 
        ? (json['food_items'] as List).map((item) => FoodItemFS.fromJson('', item)).toList()
        : [],
    date: (json['date'] as Timestamp).toDate(),
    createdAt: (json['created_at'] as Timestamp).toDate(),
    updatedAt: (json['updated_at'] as Timestamp).toDate(),
  );
}

// Food Item Data Schema
class FoodItemFS {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final String? barcode;
  final double? servingSize;
  final String? servingUnit;
  final double? caloriesPerServing;
  final double? proteinPerServing;
  final double? carbsPerServing;
  final double? fatPerServing;
  final double? fiberPerServing;
  final double? sugarPerServing;
  final double? sodiumPerServing;
  final double quantity;
  final DateTime createdAt;

  FoodItemFS({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.barcode,
    this.servingSize,
    this.servingUnit,
    this.caloriesPerServing,
    this.proteinPerServing,
    this.carbsPerServing,
    this.fatPerServing,
    this.fiberPerServing,
    this.sugarPerServing,
    this.sodiumPerServing,
    this.quantity = 1.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'brand': brand,
    'category': category,
    'barcode': barcode,
    'serving_size': servingSize,
    'serving_unit': servingUnit,
    'calories_per_serving': caloriesPerServing,
    'protein_per_serving': proteinPerServing,
    'carbs_per_serving': carbsPerServing,
    'fat_per_serving': fatPerServing,
    'fiber_per_serving': fiberPerServing,
    'sugar_per_serving': sugarPerServing,
    'sodium_per_serving': sodiumPerServing,
    'quantity': quantity,
    'created_at': Timestamp.fromDate(createdAt),
  };

  factory FoodItemFS.fromJson(String id, Map<String, dynamic> json) => FoodItemFS(
    id: id,
    name: json['name'],
    brand: json['brand'],
    category: json['category'],
    barcode: json['barcode'],
    servingSize: json['serving_size']?.toDouble(),
    servingUnit: json['serving_unit'],
    caloriesPerServing: json['calories_per_serving']?.toDouble(),
    proteinPerServing: json['protein_per_serving']?.toDouble(),
    carbsPerServing: json['carbs_per_serving']?.toDouble(),
    fatPerServing: json['fat_per_serving']?.toDouble(),
    fiberPerServing: json['fiber_per_serving']?.toDouble(),
    sugarPerServing: json['sugar_per_serving']?.toDouble(),
    sodiumPerServing: json['sodium_per_serving']?.toDouble(),
    quantity: json['quantity']?.toDouble() ?? 1.0,
    createdAt: (json['created_at'] as Timestamp).toDate(),
  );
}

// User Progress Tracking Data Schema
class UserProgressFS {
  final String id;
  final String ownerId;
  final String metricType; // 'weight', 'calories', 'water', 'exercise'
  final double value;
  final String? unit;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  UserProgressFS({
    required this.id,
    required this.ownerId,
    required this.metricType,
    required this.value,
    this.unit,
    this.notes,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'metric_type': metricType,
    'value': value,
    'unit': unit,
    'notes': notes,
    'date': Timestamp.fromDate(date),
    'created_at': Timestamp.fromDate(createdAt),
  };

  factory UserProgressFS.fromJson(String id, Map<String, dynamic> json) => UserProgressFS(
    id: id,
    ownerId: json['owner_id'],
    metricType: json['metric_type'],
    value: json['value'].toDouble(),
    unit: json['unit'],
    notes: json['notes'],
    date: (json['date'] as Timestamp).toDate(),
    createdAt: (json['created_at'] as Timestamp).toDate(),
  );
}

// User Goals Data Schema
class UserGoalFS {
  final String id;
  final String ownerId;
  final String goalType; // 'daily_calories', 'daily_protein', 'weekly_exercise', 'target_weight'
  final double targetValue;
  final String unit;
  final DateTime? targetDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserGoalFS({
    required this.id,
    required this.ownerId,
    required this.goalType,
    required this.targetValue,
    required this.unit,
    this.targetDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'goal_type': goalType,
    'target_value': targetValue,
    'unit': unit,
    'target_date': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
    'is_active': isActive,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  factory UserGoalFS.fromJson(String id, Map<String, dynamic> json) => UserGoalFS(
    id: id,
    ownerId: json['owner_id'],
    goalType: json['goal_type'],
    targetValue: json['target_value'].toDouble(),
    unit: json['unit'],
    targetDate: json['target_date'] != null ? (json['target_date'] as Timestamp).toDate() : null,
    isActive: json['is_active'] ?? true,
    createdAt: (json['created_at'] as Timestamp).toDate(),
    updatedAt: (json['updated_at'] as Timestamp).toDate(),
  );
}

// User Settings Data Schema
class UserSettingsFS {
  final String id;
  final String ownerId;
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'en', 'es', 'fr', etc.
  final String units; // 'metric', 'imperial'
  final bool notificationsEnabled;
  final bool mealReminders;
  final bool progressReminders;
  final Map<String, bool> notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettingsFS({
    required this.id,
    required this.ownerId,
    this.theme = 'system',
    this.language = 'en',
    this.units = 'metric',
    this.notificationsEnabled = true,
    this.mealReminders = true,
    this.progressReminders = true,
    this.notificationSettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'theme': theme,
    'language': language,
    'units': units,
    'notifications_enabled': notificationsEnabled,
    'meal_reminders': mealReminders,
    'progress_reminders': progressReminders,
    'notification_settings': notificationSettings,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  factory UserSettingsFS.fromJson(String id, Map<String, dynamic> json) => UserSettingsFS(
    id: id,
    ownerId: json['owner_id'],
    theme: json['theme'] ?? 'system',
    language: json['language'] ?? 'en',
    units: json['units'] ?? 'metric',
    notificationsEnabled: json['notifications_enabled'] ?? true,
    mealReminders: json['meal_reminders'] ?? true,
    progressReminders: json['progress_reminders'] ?? true,
    notificationSettings: Map<String, bool>.from(json['notification_settings'] ?? {}),
    createdAt: (json['created_at'] as Timestamp).toDate(),
    updatedAt: (json['updated_at'] as Timestamp).toDate(),
  );
}