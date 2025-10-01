import '../core/models/meal_models.dart';
import 'fatsecret_config.dart';

/// Helper to enrich AI-parsed meals with FatSecret nutritional data
class FatSecretHelper {
  final FatSecretClient _client;

  FatSecretHelper({FatSecretClient? client})
      : _client = client ?? FatSecretClient();

  /// Enrich a FoodItem with detailed nutrition from FatSecret
  /// 1. Search for the food by name
  /// 2. Get detailed nutrition for best match
  /// 3. Scale nutrition to match the quantity
  Future<FoodItem> enrichFoodItem(FoodItem item) async {
    if (!_client.isConfigured) {
      // ignore: avoid_print
      print('⚠️ FatSecret NOT CONFIGURED - Skipping enrichment for "${item.name}"');
      print('   Current macros: cal=${item.estimates.calories.toStringAsFixed(1)}, calcium=${item.estimates.calcium.toStringAsFixed(1)}mg');
      // Fallback: return item as-is if FatSecret not configured
      return item;
    }

    try {
      // ignore: avoid_print
      print('🔍 FatSecret: Searching for "${item.name}" (${item.quantity}${item.unit})');

      // Search for food
      final results = await _client.searchFoods(
        query: item.name,
        maxResults: 3,
      );

      if (results.isEmpty) {
        // ignore: avoid_print
        print('   ❌ No results found for "${item.name}"');
        // No match found, return original
        return item;
      }

      // Pick best match (first result)
      final bestMatch = results.first;
      final foodId = bestMatch['food_id'].toString();
      final foodName = bestMatch['food_name'] ?? 'Unknown';

      // ignore: avoid_print
      print('   ✅ Found match: "$foodName" (ID: $foodId)');

      // Get detailed nutrition
      final details = await _client.getFoodDetails(foodId: foodId);

      // Extract nutrition from first serving
      final servings = details['servings'];
      if (servings == null || servings is! Map) {
        // ignore: avoid_print
        print('   ❌ No serving data available');
        return item;
      }

      final serving = servings['serving'];
      Map<String, dynamic> servingData;

      if (serving is List && serving.isNotEmpty) {
        servingData = serving.first as Map<String, dynamic>;
      } else if (serving is Map) {
        servingData = serving.cast<String, dynamic>();
      } else {
        // ignore: avoid_print
        print('   ❌ Invalid serving format');
        return item;
      }

      // Parse nutrition data
      final macros = _parseMacrosFromServing(servingData, item.quantity, item.unit);

      // ignore: avoid_print
      print('   📊 Enriched nutrition: cal=${macros.calories.toStringAsFixed(1)}, p=${macros.proteinG.toStringAsFixed(1)}g, calcium=${macros.calcium.toStringAsFixed(1)}mg, iron=${macros.iron.toStringAsFixed(1)}mg');

      return FoodItem(
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        estimates: macros,
      );
    } catch (e) {
      // ignore: avoid_print
      print('❌ FatSecret enrichment FAILED for "${item.name}": $e');
      // Return original item on error
      return item;
    }
  }

  /// Parse Macros from FatSecret serving data and scale by quantity
  Macros _parseMacrosFromServing(
    Map<String, dynamic> serving,
    double userQuantity,
    String userUnit,
  ) {
    // FatSecret serving info
    final metricAmount = _toDouble(serving['metric_serving_amount'] ?? 100);
    final metricUnit = (serving['metric_serving_unit'] ?? 'g').toString().toLowerCase();

    // Calculate scaling factor
    double factor = 1.0;
    if (userUnit.toLowerCase() == metricUnit ||
        (userUnit.toLowerCase() == 'g' && metricUnit == 'g') ||
        (userUnit.toLowerCase() == 'ml' && metricUnit == 'ml')) {
      factor = userQuantity / metricAmount;
    } else {
      // Default: assume user quantity is in grams/ml
      factor = userQuantity / 100.0;
    }

    // Parse all nutritional values (per serving)
    final calories = _toDouble(serving['calories']);
    final protein = _toDouble(serving['protein']);
    final carbs = _toDouble(serving['carbohydrate']);
    final fat = _toDouble(serving['fat']);
    final fiber = _toDouble(serving['fiber']);
    final sugar = _toDouble(serving['sugar']);
    final saturatedFat = _toDouble(serving['saturated_fat']);
    final cholesterol = _toDouble(serving['cholesterol']);

    // Minerals (mg)
    final calcium = _toDouble(serving['calcium']);
    final iron = _toDouble(serving['iron']);
    final magnesium = _toDouble(serving['magnesium']);
    final zinc = _toDouble(serving['zinc']);
    final potassium = _toDouble(serving['potassium']);
    final sodium = _toDouble(serving['sodium']);

    // Vitamins
    final vitaminA = _toDouble(serving['vitamin_a']);
    final vitaminC = _toDouble(serving['vitamin_c']);
    final vitaminD = _toDouble(serving['vitamin_d']);
    final vitaminE = _toDouble(serving['vitamin_e']);

    // Scale by factor
    return Macros(
      calories: calories * factor,
      proteinG: protein * factor,
      carbsG: carbs * factor,
      fatG: fat * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
      saturatedFat: saturatedFat * factor,
      cholesterol: cholesterol * factor,
      calcium: calcium * factor,
      iron: iron * factor,
      magnesium: magnesium * factor,
      zinc: zinc * factor,
      potassium: potassium * factor,
      sodium: sodium * factor,
      vitaminA: vitaminA * factor,
      vitaminC: vitaminC * factor,
      vitaminD: vitaminD * factor,
      vitaminE: vitaminE * factor,
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}