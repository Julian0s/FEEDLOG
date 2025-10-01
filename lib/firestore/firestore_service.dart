import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_data_schema.dart';

/// Main Firestore service class that provides access to all repositories
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Repository instances
  late final UserProfileRepository userProfiles;
  late final UserMealRepository userMeals;
  late final UserProgressRepository userProgress;
  late final UserGoalRepository userGoals;
  late final UserSettingsRepository userSettings;
  late final FoodItemRepository foodItems;

  /// Initialize all repositories
  void initialize() {
    userProfiles = UserProfileRepository(_firestore, _auth);
    userMeals = UserMealRepository(_firestore, _auth);
    userProgress = UserProgressRepository(_firestore, _auth);
    userGoals = UserGoalRepository(_firestore, _auth);
    userSettings = UserSettingsRepository(_firestore, _auth);
    foodItems = FoodItemRepository(_firestore, _auth);
  }

  /// Get current authenticated user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
}

/// Base repository class with common functionality
abstract class BaseRepository<T> {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final String collectionName;

  BaseRepository(this.firestore, this.auth, this.collectionName);

  /// Get current user ID or throw if not authenticated
  String get currentUserId {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  /// Get collection reference
  CollectionReference get collection => firestore.collection(collectionName);

  /// Create document with auto-generated ID
  Future<String> create(T item) async {
    final docRef = await collection.add(toJson(item));
    return docRef.id;
  }

  /// Update existing document
  Future<void> update(String id, T item) async {
    await collection.doc(id).update(toJson(item));
  }

  /// Delete document
  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  /// Get single document by ID
  Future<T?> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists) return null;
    return fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Convert model to JSON for Firestore
  Map<String, dynamic> toJson(T item);

  /// Convert Firestore JSON to model
  T fromJson(String id, Map<String, dynamic> json);
}

/// User Profile Repository
class UserProfileRepository extends BaseRepository<UserProfileFS> {
  UserProfileRepository(FirebaseFirestore firestore, FirebaseAuth auth)
      : super(firestore, auth, 'user_profiles');

  /// Get current user's profile
  Future<UserProfileFS?> getCurrentUserProfile() async {
    final uid = currentUserId;
    final query = await collection.where('owner_id', isEqualTo: uid).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Listen to current user's profile changes
  Stream<UserProfileFS?> getCurrentUserProfileStream() {
    final uid = currentUserId;
    return collection
        .where('owner_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return fromJson(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  /// Create or update user profile
  Future<void> saveProfile(UserProfileFS profile) async {
    final existing = await getCurrentUserProfile();
    if (existing != null) {
      await update(existing.id, profile);
    } else {
      await create(profile);
    }
  }

  @override
  Map<String, dynamic> toJson(UserProfileFS item) => item.toJson();

  @override
  UserProfileFS fromJson(String id, Map<String, dynamic> json) =>
      UserProfileFS.fromJson(id, json);
}

/// User Meal Repository
class UserMealRepository extends BaseRepository<UserMealFS> {
  UserMealRepository(FirebaseFirestore firestore, FirebaseAuth auth)
      : super(firestore, auth, 'user_meals');

  /// Get meals for a specific date range
  Future<List<UserMealFS>> getMealsForDateRange(DateTime startDate, DateTime endDate) async {
    final uid = currentUserId;
    final query = await collection
        .where('owner_id', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .get();

    return query.docs
        .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get meals for a specific date
  Future<List<UserMealFS>> getMealsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return getMealsForDateRange(startOfDay, endOfDay);
  }

  /// Get meals by type for a specific date
  Future<List<UserMealFS>> getMealsByType(DateTime date, String mealType) async {
    final uid = currentUserId;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final query = await collection
        .where('owner_id', isEqualTo: uid)
        .where('meal_type', isEqualTo: mealType)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .get();

    return query.docs
        .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Listen to meals for a date range
  Stream<List<UserMealFS>> getMealsForDateRangeStream(DateTime startDate, DateTime endDate) {
    final uid = currentUserId;
    return collection
        .where('owner_id', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Map<String, dynamic> toJson(UserMealFS item) => item.toJson();

  @override
  UserMealFS fromJson(String id, Map<String, dynamic> json) =>
      UserMealFS.fromJson(id, json);
}

/// User Progress Repository
class UserProgressRepository extends BaseRepository<UserProgressFS> {
  UserProgressRepository(FirebaseFirestore firestore, FirebaseAuth auth)
      : super(firestore, auth, 'user_progress');

  /// Get progress entries for a date range
  Future<List<UserProgressFS>> getProgressForDateRange(
      DateTime startDate, DateTime endDate, {String? metricType}) async {
    final uid = currentUserId;
    Query query = collection
        .where('owner_id', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

    if (metricType != null) {
      query = query.where('metric_type', isEqualTo: metricType);
    }

    final result = await query.orderBy('date', descending: true).get();
    return result.docs
        .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get latest progress entry for a metric type
  Future<UserProgressFS?> getLatestProgress(String metricType) async {
    final uid = currentUserId;
    final query = await collection
        .where('owner_id', isEqualTo: uid)
        .where('metric_type', isEqualTo: metricType)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Listen to progress for a metric type
  Stream<List<UserProgressFS>> getProgressStream(String metricType, {int limit = 30}) {
    final uid = currentUserId;
    return collection
        .where('owner_id', isEqualTo: uid)
        .where('metric_type', isEqualTo: metricType)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Map<String, dynamic> toJson(UserProgressFS item) => item.toJson();

  @override
  UserProgressFS fromJson(String id, Map<String, dynamic> json) =>
      UserProgressFS.fromJson(id, json);
}

/// User Goals Repository
class UserGoalRepository extends BaseRepository<UserGoalFS> {
  UserGoalRepository(FirebaseFirestore firestore, FirebaseAuth auth)
      : super(firestore, auth, 'user_goals');

  /// Get active goals for current user
  Future<List<UserGoalFS>> getActiveGoals() async {
    final uid = currentUserId;
    final query = await collection
        .where('owner_id', isEqualTo: uid)
        .where('is_active', isEqualTo: true)
        .get();

    return query.docs
        .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get goal by type
  Future<UserGoalFS?> getGoalByType(String goalType) async {
    final uid = currentUserId;
    final query = await collection
        .where('owner_id', isEqualTo: uid)
        .where('goal_type', isEqualTo: goalType)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Listen to active goals
  Stream<List<UserGoalFS>> getActiveGoalsStream() {
    final uid = currentUserId;
    return collection
        .where('owner_id', isEqualTo: uid)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Map<String, dynamic> toJson(UserGoalFS item) => item.toJson();

  @override
  UserGoalFS fromJson(String id, Map<String, dynamic> json) =>
      UserGoalFS.fromJson(id, json);
}

/// User Settings Repository
class UserSettingsRepository extends BaseRepository<UserSettingsFS> {
  UserSettingsRepository(FirebaseFirestore firestore, FirebaseAuth auth)
      : super(firestore, auth, 'user_settings');

  /// Get current user's settings
  Future<UserSettingsFS?> getCurrentUserSettings() async {
    final uid = currentUserId;
    final query = await collection.where('owner_id', isEqualTo: uid).limit(1).get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Listen to current user's settings
  Stream<UserSettingsFS?> getCurrentUserSettingsStream() {
    final uid = currentUserId;
    return collection
        .where('owner_id', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return fromJson(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  /// Save user settings
  Future<void> saveSettings(UserSettingsFS settings) async {
    final existing = await getCurrentUserSettings();
    if (existing != null) {
      await update(existing.id, settings);
    } else {
      await create(settings);
    }
  }

  @override
  Map<String, dynamic> toJson(UserSettingsFS item) => item.toJson();

  @override
  UserSettingsFS fromJson(String id, Map<String, dynamic> json) =>
      UserSettingsFS.fromJson(id, json);
}

/// Food Items Repository (public data)
class FoodItemRepository extends BaseRepository<FoodItemFS> {
  FoodItemRepository(FirebaseFirestore firestore, FirebaseAuth auth)
      : super(firestore, auth, 'food_items');

  /// Search food items by name
  Future<List<FoodItemFS>> searchByName(String searchTerm, {int limit = 20}) async {
    final query = await collection
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThan: searchTerm + 'z')
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get food item by barcode
  Future<FoodItemFS?> getByBarcode(String barcode) async {
    final query = await collection
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Get food items by category
  Future<List<FoodItemFS>> getByCategory(String category, {int limit = 50}) async {
    final query = await collection
        .where('category', isEqualTo: category)
        .orderBy('name')
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Map<String, dynamic> toJson(FoodItemFS item) => item.toJson();

  @override
  FoodItemFS fromJson(String id, Map<String, dynamic> json) =>
      FoodItemFS.fromJson(id, json);
}