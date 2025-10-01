import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../openai/openai_config.dart';
import '../providers/meal_provider.dart';
import '../models/meal_models.dart';
import '../../firestore/auth_service.dart';
import '../providers/firebase_meal_provider.dart';
import '../../fatsecret/fatsecret_helper.dart';

class GlobalChatFAB extends StatelessWidget {
  const GlobalChatFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openChat(context),
      child: const Icon(Icons.chat),
    );
  }

  void _openChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _ChatSheet(),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet();
  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  const SizedBox(width: 8),
                  Text('AI Food Logger', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _placeholderForLocale(context),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _onUploadImage,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Label Photo'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _loading ? null : _onSend,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                )
            ],
          ),
        ),
      ),
    );
  }

  String _placeholderForLocale(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    switch (lang) {
      case 'pt':
        return 'Descreva sua refeição (ex.: 40g de torrada com manteiga, 1 xícara de café, 200g de arroz...)';
      case 'es':
        return 'Describe tu comida (ej.: 40g de tostada con mantequilla, 1 taza de café, 200g de arroz...)';
      case 'fr':
        return 'Décrivez votre repas (ex.: 40g de toast au beurre, 1 tasse de café, 200g de riz...)';
      case 'it':
        return 'Descrivi il tuo pasto (es.: 40g di toast con burro, 1 tazza di caffè, 200g di riso...)';
      default:
        return 'Describe your meal (e.g., 40g toast with butter, 1 cup of coffee, 200g rice...)';
    }
  }

  String _friendlyErrorMessage(Object e, BuildContext context) {
    final msg = e.toString();
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final isJson = msg.contains('Malformed JSON');
    final notConfigured = msg.contains('AI is not configured') || msg.contains('OpenAI error: 401') || msg.contains('Unauthorized');
    final noMeals = msg.contains('No meals parsed');
    final aiReturnedError = msg.contains('AI error:');

    if (notConfigured) {
      switch (lang) {
        case 'pt':
          return 'AI não está configurada neste ambiente.';
        case 'es':
          return 'La IA no está configurada en este entorno.';
        case 'fr':
          return "L'IA n'est pas configurée dans cet environnement.";
        case 'it':
          return "L'IA non è configurata in questo ambiente.";
        default:
          return 'AI is not configured in this environment.';
      }
    }
    if (isJson) {
      switch (lang) {
        case 'pt':
          return 'Não consegui entender. Tente simplificar a descrição (ex.: quantidades e unidades).';
        case 'es':
          return 'No pude entender. Intenta simplificar la descripción (cantidades y unidades).';
        case 'fr':
          return 'Je n’ai pas compris. Essayez de simplifier la description (quantités et unités).';
        case 'it':
          return 'Non ho capito. Prova a semplificare la descrizione (quantità e unità).';
        default:
          return "I couldn't understand. Try simplifying the description (quantities and units).";
      }
    }
    if (noMeals) {
      switch (lang) {
        case 'pt':
          return 'Não consegui identificar alimentos nessa mensagem. Inclua quantidades e unidades (ex.: 40g, 1 xícara, 150ml).';
        case 'es':
          return 'No pude identificar alimentos en el mensaje. Incluye cantidades y unidades (ej.: 40g, 1 taza, 150ml).';
        case 'fr':
          return "Je n'ai pas pu identifier d'aliments. Ajoutez des quantités et des unités (ex.: 40g, 1 tasse, 150ml).";
        case 'it':
          return 'Non sono riuscito a identificare alimenti. Includi quantità e unità (es.: 40g, 1 tazza, 150ml).';
        default:
          return 'I could not identify foods. Please include quantities and units (e.g., 40g, 1 cup, 150ml).';
      }
    }
    if (aiReturnedError) {
      final human = msg.replaceFirst('Exception: ', '').replaceFirst('AI error: ', '').trim();
      switch (lang) {
        case 'pt':
          return 'Erro da IA: ' + human;
        case 'es':
          return 'Error de IA: ' + human;
        case 'fr':
          return "Erreur de l'IA: " + human;
        case 'it':
          return 'Errore IA: ' + human;
        default:
          return 'AI error: ' + human;
      }
    }
    // Fallback generic
    switch (lang) {
      case 'pt':
        return 'Ocorreu um erro. Tente novamente.';
      case 'es':
        return 'Ocurrió un error. Inténtalo de nuevo.';
      case 'fr':
        return 'Une erreur s’est produite. Veuillez réessayer.';
      case 'it':
        return 'Si è verificato un errore. Riprova.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> _onSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = OpenAIClient();
      if (!client.isConfigured) {
        setState(() {
          _error = 'AI is not configured in this environment.';
        });
        return;
      }

      // Check FatSecret configuration and warn user
      final fatSecretClient = FatSecretHelper();
      final isFatSecretConfigured = fatSecretClient._client.isConfigured;

      if (!isFatSecretConfigured) {
        // ignore: avoid_print
        print('\n⚠️ WARNING: FatSecret API is NOT configured!');
        print('   Micronutrients (calcium, iron, vitamins) will not be available.');
        print('   To enable: Run with --dart-define=FATSECRET_CLIENT_ID=... --dart-define=FATSECRET_CLIENT_SECRET=...\n');

        // Show warning to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '⚠️ Micronutrients unavailable: FatSecret API not configured',
                style: TextStyle(fontSize: 13),
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      final json = await client.parseMealFromText(userText: text);
      // Debug minimal logging (safe)
      // ignore: avoid_print
      print('AI raw parse payload keys: ${json.keys.toList()}');
      var meals = _mapJsonToMeals(json, userText: text);
      if (meals.isEmpty) {
        throw Exception('No meals parsed');
      }

      // Enrich meals with FatSecret data
      // ignore: avoid_print
      print('\n🔄 Starting FatSecret enrichment for ${meals.length} meal(s)...');

      final fatSecretHelper = FatSecretHelper();
      final enrichedMeals = <MealEntry>[];

      for (final meal in meals) {
        // ignore: avoid_print
        print('\n📝 Processing ${mealTypeLabel(meal.mealType)} with ${meal.foods.length} food item(s)');

        final enrichedFoods = <FoodItem>[];
        for (final food in meal.foods) {
          // ignore: avoid_print
          print('   BEFORE enrichment: ${food.name} - calcium=${food.estimates.calcium.toStringAsFixed(1)}mg, iron=${food.estimates.iron.toStringAsFixed(1)}mg');

          final enriched = await fatSecretHelper.enrichFoodItem(food);
          enrichedFoods.add(enriched);

          // ignore: avoid_print
          print('   AFTER enrichment: ${enriched.name} - calcium=${enriched.estimates.calcium.toStringAsFixed(1)}mg, iron=${enriched.estimates.iron.toStringAsFixed(1)}mg');
        }

        // Recalculate totals with enriched data
        double c = 0, p = 0, cb = 0, ft = 0;
        double calcium = 0, iron = 0, magnesium = 0, zinc = 0, potassium = 0, sodium = 0;
        double vitA = 0, vitC = 0, vitD = 0, vitE = 0;
        double fiber = 0, sugar = 0, satFat = 0, chol = 0;

        for (final f in enrichedFoods) {
          c += f.estimates.calories;
          p += f.estimates.proteinG;
          cb += f.estimates.carbsG;
          ft += f.estimates.fatG;
          calcium += f.estimates.calcium;
          iron += f.estimates.iron;
          magnesium += f.estimates.magnesium;
          zinc += f.estimates.zinc;
          potassium += f.estimates.potassium;
          sodium += f.estimates.sodium;
          vitA += f.estimates.vitaminA;
          vitC += f.estimates.vitaminC;
          vitD += f.estimates.vitaminD;
          vitE += f.estimates.vitaminE;
          fiber += f.estimates.fiber;
          sugar += f.estimates.sugar;
          satFat += f.estimates.saturatedFat;
          chol += f.estimates.cholesterol;
        }

        // ignore: avoid_print
        print('   ✅ Meal totals: calcium=${calcium.toStringAsFixed(1)}mg, iron=${iron.toStringAsFixed(1)}mg, vitA=${vitA.toStringAsFixed(1)}, vitC=${vitC.toStringAsFixed(1)}mg');

        enrichedMeals.add(meal.copyWith(
          foods: enrichedFoods,
          totals: Macros(
            calories: c,
            proteinG: p,
            carbsG: cb,
            fatG: ft,
            calcium: calcium,
            iron: iron,
            magnesium: magnesium,
            zinc: zinc,
            potassium: potassium,
            sodium: sodium,
            vitaminA: vitA,
            vitaminC: vitC,
            vitaminD: vitD,
            vitaminE: vitE,
            fiber: fiber,
            sugar: sugar,
            saturatedFat: satFat,
            cholesterol: chol,
          ),
        ));
      }

      // ignore: avoid_print
      print('\n✅ Enrichment complete!\n');

      if (!mounted) return;
      // If authenticated, persist to Firestore; otherwise fallback to local provider
      final auth = AuthService();
      if (auth.isAuthenticated) {
        final fbMeals = context.read<FirebaseMealProvider>();
        for (final m in enrichedMeals) {
          await fbMeals.addMeal(m.copyWith(id: ''));
        }
      } else {
        final mealProvider = context.read<MealProvider>();
        mealProvider.addMeals(DateTime.now(), enrichedMeals);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = _friendlyErrorMessage(e, context);
      });
      // ignore: avoid_print
      print('AI parse error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _onUploadImage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false, withData: true);
      final file = result?.files.first;
      final bytes = file?.bytes;
      if (bytes == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final client = OpenAIClient();
      if (!client.isConfigured) {
        setState(() {
          _error = 'AI is not configured in this environment.';
        });
        return;
      }
      final json = await client.analyzeNutritionLabelFromImage(imageBytes: bytes);
      // Show pretty JSON as a dialog for now
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nutrition Label (AI)'),
          content: SingleChildScrollView(
              child: Text(const JsonEncoder.withIndent('  ').convert(json))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = _friendlyErrorMessage(e, context);
      });
      // ignore: avoid_print
      print('AI label analyze error: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // --- Parsing helpers ---
  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final match = RegExp(r"[-+]?[0-9]*\.?[0-9]+").firstMatch(v.replaceAll(',', '.'));
      if (match != null) {
        return double.tryParse(match.group(0)!) ?? 0.0;
      }
    }
    return 0.0;
  }

  String _normalizeMealTypeLabel(String raw) {
    final s = (raw).toLowerCase();
    // Portuguese
    if (s.contains('café') || s.contains('cafe') || s.contains('manhã') || s.contains('manha') || s.contains('break')) return 'breakfast';
    if (s.contains('almo') || s.contains('tarde') || s.contains('lunch')) return 'lunch';
    if (s.contains('jantar') || s.contains('noite') || s.contains('dinner')) return 'dinner';
    if (s.contains('lanche') || s.contains('snack')) return 'snack';
    
    // Spanish
    if (s.contains('desayuno')) return 'breakfast';
    if (s.contains('almuerzo')) return 'lunch';
    if (s.contains('comida ')) return 'lunch';
    if (s.contains('cena')) return 'dinner';
    if (s.contains('merienda') || s.contains('colacion') || s.contains('colación')) return 'snack';

    // French
    if (s.contains('petit déj') || s.contains('petit dej') || s.contains('petit-dej')) return 'breakfast';
    if (s.contains('déjeuner') || s.contains('dejeuner')) return 'lunch';
    if (s.contains('dîner') || s.contains('diner')) return 'dinner';
    if (s.contains('goûter') || s.contains('gouter')) return 'snack';

    // Italian
    if (s.contains('colazione')) return 'breakfast';
    if (s.contains('pranzo')) return 'lunch';
    if (s.contains('cena')) return 'dinner';
    if (s.contains('spuntino')) return 'snack';

    return 'snack';
  }

  Map<String, dynamic> _normalizeEstimates(Map<String, dynamic> raw) {
    final cal = _toDouble(raw['calories'] ?? raw['kcal'] ?? raw['cal'] ?? raw['energy']);
    final p = _toDouble(
      raw['protein_g'] ?? raw['protein'] ?? raw['proteina'] ?? raw['proteína'] ?? raw['protéines'] ?? raw['proteine'] ?? raw['proteinG'],
    );
    final c = _toDouble(
      raw['carbs_g'] ?? raw['carbs'] ?? raw['carbohydrates'] ?? raw['carboidratos'] ?? raw['carbohidratos'] ?? raw['hidratos'] ?? raw['glucides'] ?? raw['carboidrati'] ?? raw['carbsG'],
    );
    final f = _toDouble(
      raw['fat_g'] ?? raw['fat'] ?? raw['gordura'] ?? raw['grasa'] ?? raw['grasas'] ?? raw['lipidos'] ?? raw['lípidos'] ?? raw['lipides'] ?? raw['grassi'] ?? raw['fatG'],
    );
    return {
      'calories': cal,
      'protein_g': p,
      'carbs_g': c,
      'fat_g': f,
    };
  }

  // Simple heuristic nutrition estimates (per 100 g/ml or per unit) for common foods
  Macros _estimateMacrosFor(String name, double qty, String unit) {
    final n = name.toLowerCase();
    double calPer = 0, pPer = 0, cPer = 0, fPer = 0; // per 100g or 100ml unless noted
    bool perUnit = false; // if true, per single unit (slice/cup/tbsp/tsp/piece)

    bool isLiquid = unit.contains('ml');

    // Bread/Toast
    if (n.contains('torrada') || n.contains('toast') || n.contains('pão') || n.contains('pao') || n.contains('bread')) {
      calPer = 265; pPer = 9; cPer = 49; fPer = 3.2; // per 100 g
    }
    // Butter
    else if (n.contains('manteig') || n.contains('butter')) {
      calPer = 717; pPer = 0.9; cPer = 0.1; fPer = 81; // per 100 g
    }
    // Black coffee
    else if (n.contains('café') || n.contains('cafe') || n.contains('coffee')) {
      calPer = 1; pPer = 0.1; cPer = 0; fPer = 0; // per 100 ml
      isLiquid = true;
    }
    // Orange juice
    else if (n.contains('suco de laranja') || n.contains('jugo de naranja') || n.contains('orange juice') || (n.contains('suco') && n.contains('laran'))) {
      calPer = 45; pPer = 0.7; cPer = 10.4; fPer = 0.2; // per 100 ml
      isLiquid = true;
    }
    // Cooked rice
    else if (n.contains('arroz') || n.contains('rice')) {
      calPer = 130; pPer = 2.4; cPer = 28; fPer = 0.3; // per 100 g (cooked)
    }
    // Grilled chicken breast
    else if ((n.contains('peito') && n.contains('frango')) || n.contains('chicken breast')) {
      calPer = 165; pPer = 31; cPer = 0; fPer = 3.6; // per 100 g (cooked)
    }
    // Generic milk
    else if (n.contains('leite') || n.contains('milk')) {
      calPer = 60; pPer = 3.2; cPer = 5; fPer = 3.3; // per 100 ml (whole milk)
      isLiquid = true;
    }
    // Generic cheese
    else if (n.contains('queijo') || n.contains('cheese')) {
      calPer = 350; pPer = 25; cPer = 3; fPer = 27; // per 100 g
    }

    // Scale by quantity
    double factor;
    if (perUnit) {
      factor = qty; // qty is number of units
    } else if (isLiquid) {
      factor = qty / 100.0; // ml -> per 100 ml
    } else {
      factor = qty / 100.0; // g -> per 100 g
    }
    return Macros(
      calories: (calPer * factor).clamp(0, double.infinity),
      proteinG: (pPer * factor).clamp(0, double.infinity),
      carbsG: (cPer * factor).clamp(0, double.infinity),
      fatG: (fPer * factor).clamp(0, double.infinity),
    );
  }

  FoodItem _inferFoodDefaults(FoodItem item) {
    var qty = item.quantity;
    var unit = item.unit.isEmpty ? '' : item.unit.toLowerCase();

    // Infer unit if empty: assume grams for solids when name hints solid; ml for beverages
    final lower = item.name.toLowerCase();
    final looksDrink = lower.contains('café') || lower.contains('cafe') || lower.contains('coffee') || lower.contains('suco') || lower.contains('jugo') || lower.contains('juice') || lower.contains('leite') || lower.contains('milk');
    if (unit.isEmpty) {
      unit = looksDrink ? 'ml' : 'g';
    }

    // Infer quantity if zero using typical defaults
    if (qty <= 0) {
      if (lower.contains('manteig') || lower.contains('butter')) {
        qty = 7; // default butter spread per slice
      } else if (looksDrink) {
        qty = 240; // default cup
      } else if (lower.contains('peito') && lower.contains('frango')) {
        qty = 150;
      } else if (lower.contains('arroz') || lower.contains('rice')) {
        qty = 150;
      } else if (lower.contains('torrada') || lower.contains('toast') || lower.contains('pão') || lower.contains('pao') || lower.contains('bread')) {
        qty = 40; // one toast example
      } else {
        qty = 100; // safe default
      }
    }

    // If estimates are zeros, compute rough estimates
    final needsEst = item.estimates.calories <= 0 && item.estimates.proteinG <= 0 && item.estimates.carbsG <= 0 && item.estimates.fatG <= 0;
    final est = needsEst ? _estimateMacrosFor(item.name, qty, unit) : item.estimates;

    return FoodItem(name: item.name, quantity: qty, unit: unit, estimates: est);
  }

  List<MealEntry> _mapJsonToMeals(Map<String, dynamic> payload, {String? userText}) {
    // Surface AI/proxy errors early
    if (payload.containsKey('error')) {
      final err = payload['error'];
      throw Exception('AI error: ${err is String ? err : jsonEncode(err)}');
    }
    // Unwrap common wrappers, e.g., { data: {...} } or { result: {...} }
    if (payload['data'] is Map<String, dynamic>) {
      payload = (payload['data'] as Map<String, dynamic>);
    }
    if (payload['result'] is Map<String, dynamic>) {
      payload = (payload['result'] as Map<String, dynamic>);
    }

    List<dynamic> mealsJson = const [];

    // Primary path: meals as list of objects
    if (payload['meals'] is List) {
      mealsJson = payload['meals'] as List;
    }

    // Alternate: meals as a map { breakfast: [foods], lunch: [foods], ... }
    if (mealsJson.isEmpty && payload['meals'] is Map) {
      final m = (payload['meals'] as Map).cast<String, dynamic>();
      final keys = ['breakfast', 'lunch', 'dinner', 'snack'];
      for (final k in keys) {
        final foods = m[k];
        if (foods is List && foods.isNotEmpty) {
          mealsJson.add({'mealType': k, 'foods': foods});
        }
      }
    }

    // Root-level meal buckets (without "meals"): { breakfast: [...], lunch: [...] }
    if (mealsJson.isEmpty) {
      final keys = ['breakfast', 'lunch', 'dinner', 'snack'];
      for (final k in keys) {
        final foods = payload[k];
        if (foods is List && foods.isNotEmpty) {
          mealsJson.add({'mealType': k, 'foods': foods});
        }
      }
    }

    // Other common variants
    if (mealsJson.isEmpty && payload['meal'] is Map) {
      final mealMap = (payload['meal'] as Map).cast<String, dynamic>();
      mealsJson = [
        {
          'mealType': mealMap['mealType'] ?? mealMap['meal_type'] ?? mealMap['type'] ?? 'snack',
          'foods': mealMap['foods'] ?? mealMap['items'] ?? [],
        }
      ];
    }

    if (mealsJson.isEmpty && payload['entries'] is List) {
      mealsJson = (payload['entries'] as List);
    }

    if (mealsJson.isEmpty && payload['records'] is List) {
      mealsJson = (payload['records'] as List);
    }

    // Fallbacks for simpler responses at root
    if (mealsJson.isEmpty) {
      if (payload['foods'] is List) {
        mealsJson = [
          {
            'mealType': 'snack',
            'foods': payload['foods'],
          }
        ];
      } else if (payload['items'] is List) {
        mealsJson = [
          {
            'mealType': 'snack',
            'foods': payload['items'],
          }
        ];
      } else if (payload['food'] is Map) {
        mealsJson = [
          {
            'mealType': 'snack',
            'foods': [payload['food']],
          }
        ];
      }
    }

    final List<MealEntry> meals = [];
    for (final m in mealsJson) {
      if (m is! Map<String, dynamic>) continue;
      final typeStrRaw = (m['mealType'] ?? m['meal_type'] ?? m['type'] ?? 'snack').toString();
      final typeStr = _normalizeMealTypeLabel(typeStrRaw);

      // Accept different property names for foods
      List foodsJson = (m['foods'] as List?) ?? (m['items'] as List?) ?? (m['food'] is Map ? [m['food']] : const []);

      // Normalize: allow list of strings
      foodsJson = foodsJson.map((f) {
        if (f is String) return {'name': f};
        return f;
      }).toList();

      var foods = foodsJson.whereType<Map<String, dynamic>>().map((f) {
        final estimatesRaw = (f['estimates'] ?? f['macros'] ?? f['nutrition'] ?? f['nutrients'] ?? {}) as Map<String, dynamic>;
        final normalizedEst = _normalizeEstimates(estimatesRaw);

        // Attempt to infer unit from quantity if it was given as a string like "150ml"
        String unit = (f['unit'] ?? '').toString();
        double qty = 0;
        final q = f['quantity'] ?? f['qty'];
        if (q is String) {
          // extract unit trail letters
          final unitMatch = RegExp(r"[a-zA-ZçÇáÁãÃéÉíÍóÓõÕúÚ]+\.?$").firstMatch(q.trim());
          if (unit.isEmpty && unitMatch != null) {
            unit = unitMatch.group(0)!.toLowerCase();
          }
          qty = _toDouble(q);
        } else {
          qty = _toDouble(q);
        }

        final item = FoodItem.fromJson({
          'name': (f['name'] ?? f['food'] ?? '').toString(),
          'quantity': qty,
          'unit': unit,
          'estimates': normalizedEst,
        });
        return _inferFoodDefaults(item);
      }).toList();

      // Heuristic: if text mentions butter but no butter item, and there is toast/bread, add default butter 7g
      final text = (userText ?? '').toLowerCase();
      final mentionsButter = text.contains('manteig') || text.contains('butter');
      final hasButter = foods.any((f) => f.name.toLowerCase().contains('manteig') || f.name.toLowerCase().contains('butter'));
      final hasToast = foods.any((f) => f.name.toLowerCase().contains('torrada') || f.name.toLowerCase().contains('toast') || f.name.toLowerCase().contains('pão') || f.name.toLowerCase().contains('pao') || f.name.toLowerCase().contains('bread'));
      if (mentionsButter && !hasButter && hasToast) {
        foods = [...foods, _inferFoodDefaults(const FoodItem(name: 'manteiga', quantity: 7, unit: 'g'))];
      }

      // Compute totals
      double c = 0, p = 0, cb = 0, ft = 0;
      for (final f in foods) {
        c += f.estimates.calories;
        p += f.estimates.proteinG;
        cb += f.estimates.carbsG;
        ft += f.estimates.fatG;
      }

      meals.add(MealEntry(
        id: '',
        date: DateTime.now(),
        mealType: mealTypeFromString(typeStr),
        foods: foods,
        totals: Macros(calories: c, proteinG: p, carbsG: cb, fatG: ft),
      ));
    }

    // If still empty, last-resort: infer one meal from free text if provided
    if (meals.isEmpty && (userText != null && userText.isNotEmpty)) {
      // Try to infer meal type from text
      final type = _normalizeMealTypeLabel(userText);
      meals.add(MealEntry(
        id: '',
        date: DateTime.now(),
        mealType: mealTypeFromString(type),
        foods: const [],
        totals: const Macros(),
      ));
    }

    return meals.where((m) => m.foods.isNotEmpty).toList();
  }
}
