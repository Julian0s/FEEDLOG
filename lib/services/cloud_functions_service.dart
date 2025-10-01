import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/models/meal_models.dart';

/// Service for calling Firebase Cloud Functions
/// Replaces direct FatSecret and OpenAI API calls with secure backend proxy
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Parse meal from natural language text using OpenAI (via Cloud Function)
  ///
  /// This replaces direct OpenAI API calls in openai_config.dart
  Future<Map<String, dynamic>> parseMealFromText({
    required String userText,
  }) async {
    try {
      final callable = _functions.httpsCallable('parseMeal');
      final result = await callable.call<Map<String, dynamic>>({
        'userText': userText,
      });

      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Parse meal failed: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('Parse meal error: $e');
    }
  }

  /// Enrich a single food item with FatSecret nutrition data (via Cloud Function)
  ///
  /// This replaces direct FatSecret API calls in fatsecret_helper.dart
  Future<FoodItem> enrichFoodItem(FoodItem item) async {
    try {
      final callable = _functions.httpsCallable('enrichFood');
      final result = await callable.call<Map<String, dynamic>>({
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'estimates': item.estimates.toJson(),
      });

      final data = result.data;

      return FoodItem(
        name: data['name'] as String,
        quantity: (data['quantity'] as num).toDouble(),
        unit: data['unit'] as String,
        estimates: Macros.fromJson(data['estimates'] as Map<String, dynamic>),
      );
    } on FirebaseFunctionsException catch (e) {
      // ignore: avoid_print
      print('❌ Enrich food failed for "${item.name}": ${e.message}');
      return item; // Return original on error
    } catch (e) {
      // ignore: avoid_print
      print('❌ Enrich food error for "${item.name}": $e');
      return item;
    }
  }

  /// Parse meal AND enrich all foods in one call (better performance)
  ///
  /// This is the recommended method - combines OpenAI parsing + FatSecret enrichment
  Future<List<MealEntry>> parseMealWithEnrichment({
    required String userText,
  }) async {
    try {
      // ignore: avoid_print
      print('\n🚀 Calling Cloud Function: parseMealWithEnrichment');

      final callable = _functions.httpsCallable('parseMealWithEnrichment');
      final result = await callable.call<Map<String, dynamic>>({
        'userText': userText,
      });

      final data = result.data;
      final mealsJson = data['meals'] as List;

      // ignore: avoid_print
      print('   ✅ Received ${mealsJson.length} enriched meal(s) from backend');

      return mealsJson.map((mealData) {
        final mealMap = mealData as Map<String, dynamic>;
        final typeStr = (mealMap['mealType'] ?? 'snack').toString().toLowerCase();
        final foodsJson = mealMap['foods'] as List;
        final totalsJson = mealMap['totals'] as Map<String, dynamic>?;

        final foods = foodsJson.map((foodData) {
          final foodMap = foodData as Map<String, dynamic>;
          return FoodItem(
            name: foodMap['name'] as String,
            quantity: (foodMap['quantity'] as num).toDouble(),
            unit: foodMap['unit'] as String,
            estimates: Macros.fromJson(foodMap['estimates'] as Map<String, dynamic>),
          );
        }).toList();

        return MealEntry(
          id: '',
          date: DateTime.now(),
          mealType: mealTypeFromString(typeStr),
          foods: foods,
          totals: totalsJson != null ? Macros.fromJson(totalsJson) : const Macros(),
        );
      }).toList();
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Parse + enrich failed: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('Parse + enrich error: $e');
    }
  }

  /// Analyze nutrition label from image (via Cloud Function)
  Future<Map<String, dynamic>> analyzeNutritionLabel({
    required Uint8List imageBytes,
  }) async {
    try {
      // Convert image bytes to base64
      final base64Image = base64Encode(imageBytes);

      final callable = _functions.httpsCallable('analyzeNutritionLabel');
      final result = await callable.call<Map<String, dynamic>>({
        'imageBase64': base64Image,
      });

      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Analyze label failed: ${e.message} (${e.code})');
    } catch (e) {
      throw Exception('Analyze label error: $e');
    }
  }
}
