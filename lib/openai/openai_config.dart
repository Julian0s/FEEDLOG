import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// IMPORTANT: Environment-driven configuration (provided by Dreamflow at runtime)
const String apiKey = String.fromEnvironment('OPENAI_PROXY_API_KEY');
const String endpoint = String.fromEnvironment('OPENAI_PROXY_ENDPOINT');

class OpenAIClient {
  final http.Client _http;
  OpenAIClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  bool get isConfigured => apiKey.isNotEmpty && endpoint.isNotEmpty;

  // --- Public API ---
  Future<Map<String, dynamic>> parseMealFromText({
    required String userText,
    String model = 'gpt-4o',
  }) async {
    final base = endpoint.replaceAll(RegExp(r'/+$'), '');
    final responsesUri = Uri.parse('$base/responses');
    final chatUri = Uri.parse('$base/chat/completions');

    final systemPrompt = '''You are a nutrition extraction assistant for a food diary.
The user may write casually in ANY language (Portuguese, Spanish, English, French, Italian, etc.) and may include typos, slang, or country-specific expressions.
Task: Parse the user's message into one or more meals and foods, inferring missing details when needed.
Return ONLY a JSON object following EXACTLY this schema (no extra text):
{"meals":[{"mealType":"breakfast|lunch|dinner|snack","foods":[{"name":"...","quantity":number,"unit":"g|ml|slice|cup|tbsp|tsp|piece","estimates":{"calories":number,"protein_g":number,"carbs_g":number,"fat_g":number}}]}],"dailyTotals":{"calories":number,"protein_g":number,"carbs_g":number,"fat_g":number}}
Rules:
- mealType must be in ENGLISH tokens [breakfast, lunch, dinner, snack] regardless of user's language. Examples: "café da manhã"/"desayuno"/"petit déjeuner"/"colazione" -> breakfast; "almoço"/"almuerzo"/"déjeuner"/"pranzo" -> lunch; "jantar"/"cena"/"dîner" -> dinner; "lanche"/"merienda"/"goûter"/"spuntino" -> snack.
- Always include at least one meal and at least one food. Split text into separate meals if the user mentions more than one (e.g., "no café da manhã... e no almoço...").
- Quantities: if a quantity or unit is missing, INFER a reasonable default and still fill quantity + unit. Use typical portions: e.g., butter on toast ≈ 5–10 g per slice (use 7 g if unspecified), black coffee cup ≈ 240 ml, espresso ≈ 30 ml, orange juice cup ≈ 240 ml, cooked rice per serving ≈ 150 g, grilled chicken breast ≈ 150 g.
- Accept comma decimals and normalize to dot decimals (e.g., 150,5 ml -> 150.5 with unit ml).
- Provide numeric estimates for calories/protein_g/carbs_g/fat_g for each food. If exact values are unknown, use reasonable nutrition estimates per 100 g/ml and scale by quantity.
- Output MUST be valid JSON only with no commentary, code fences, or explanation.
Examples:
- PT-BR: "café da manhã: uma torrada de 40g com manteiga e um café sem açúcar" -> breakfast with foods [ {name:"torrada", quantity:40, unit:"g", ...}, {name:"manteiga", quantity:7, unit:"g", ...}, {name:"café preto", quantity:240, unit:"ml", ...} ]
- ES: "almuerzo: 200g de arroz con 150g de pechuga de pollo y un vaso de jugo de naranja (150ml)" -> lunch with three foods.
''';

    // 1) Try Responses API payload (some proxies accept this format)
    final responsesPayload = {
      'model': model,
      'input': [
        {
          'role': 'system',
          'content': [
            {'type': 'text', 'text': systemPrompt}
          ],
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userText}
          ],
        }
      ],
      'response_format': {'type': 'json_object'},
    };

    // 2) Chat Completions fallback payload
    final chatPayload = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userText},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.2,
    };

    Map<String, dynamic> decoded;

    // Attempt #1: Responses API
    try {
      decoded = await _postJson(responsesUri, responsesPayload);
      // Debug: log shallow keys to help diagnose proxy format differences
      // ignore: avoid_print
      print('OpenAI Responses raw top-level keys: ${decoded.keys.toList()}');
      if (_isMessagesMissingError(decoded)) {
        // ignore: avoid_print
        print('Responses endpoint rejected payload (missing messages). Falling back to Chat Completions...');
        decoded = await _postJson(chatUri, chatPayload);
      }
    } on OpenAIError catch (e) {
      // If the Responses endpoint is not supported by the proxy (400/404/etc.),
      // fall back to Chat Completions automatically.
      final lower = e.message.toLowerCase();
      final shouldFallback = lower.contains('responses') ||
          lower.contains('unrecognized request argument supplied: input') ||
          lower.contains('missing required parameter:') ||
          lower.contains('404');
      if (shouldFallback) {
        decoded = await _postJson(chatUri, chatPayload);
      } else {
        rethrow;
      }
    }

    // Normalize and extract text/JSON from either API
    final content = _extractTextContent(decoded);
    try {
      final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
      return json;
    } catch (_) {
      final extracted = _tryExtractJson(content);
      if (extracted != null) {
        try {
          final Map<String, dynamic> json = jsonDecode(extracted) as Map<String, dynamic>;
          return json;
        } catch (_) {}
      }
      final fallback = _findEmbeddedJsonInResponse(decoded);
      if (fallback != null) return fallback;
      throw OpenAIError('Malformed JSON from model');
    }
  }

  Future<Map<String, dynamic>> analyzeNutritionLabelFromImage({
    required Uint8List imageBytes,
    String model = 'gpt-4o',
  }) async {
    final base = endpoint.replaceAll(RegExp(r'/+$'), '');
    final responsesUri = Uri.parse('$base/responses');
    final chatUri = Uri.parse('$base/chat/completions');

    final base64Img = base64Encode(imageBytes);
    final systemPrompt = 'You are an expert OCR and nutrition label analyzer. Extract nutrition facts from the label image and output a JSON object with fields: serving_size, servings_per_container, nutrients: array of { name, amount, unit, per_serving }, and notes.';

    final responsesPayload = {
      'model': model,
      'input': [
        {
          'role': 'system',
          'content': [
            {'type': 'text', 'text': systemPrompt}
          ],
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Extract nutrition information in JSON. Be precise and include units.'
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,' + base64Img}
            }
          ],
        }
      ],
      'response_format': {'type': 'json_object'},
    };

    final chatPayload = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Extract nutrition information in JSON. Be precise and include units.'},
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,' + base64Img}},
          ]
        },
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.2,
    };

    Map<String, dynamic> decoded;
    try {
      decoded = await _postJson(responsesUri, responsesPayload);
      if (_isMessagesMissingError(decoded)) {
        // ignore: avoid_print
        print('Responses endpoint rejected payload (missing messages). Falling back to Chat Completions (image)...');
        decoded = await _postJson(chatUri, chatPayload);
      }
    } on OpenAIError catch (e) {
      final lower = e.message.toLowerCase();
      final shouldFallback = lower.contains('responses') ||
          lower.contains('unrecognized request argument supplied: input') ||
          lower.contains('missing required parameter:') ||
          lower.contains('404');
      if (shouldFallback) {
        decoded = await _postJson(chatUri, chatPayload);
      } else {
        rethrow;
      }
    }

    final content = _extractTextContent(decoded);
    try {
      final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
      return json;
    } catch (e) {
      throw OpenAIError('Malformed JSON from model: $e');
    }
  }

  // --- Internal helpers ---
  Future<Map<String, dynamic>> _postJson(Uri uri, Map<String, dynamic> payload) async {
    final res = await _http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: utf8.encode(jsonEncode(payload)),
    );

    // Some proxies return 200 with { error: {...} }. Others return 4xx.
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw OpenAIError('OpenAI error: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    // Debug shallow keys to help in diagnostics
    // ignore: avoid_print
    print('OpenAI Responses raw top-level keys: ${decoded.keys.toList()}');

    // If proxy returns an error payload with 200 status, surface it to the caller.
    if (decoded.containsKey('error')) {
      // ignore: avoid_print
      print('OpenAI raw error payload: ${jsonEncode(decoded['error'])}');
    }

    return decoded;
  }

  static bool _isMessagesMissingError(Map<String, dynamic> decoded) {
    if (!decoded.containsKey('error')) return false;
    final err = decoded['error'];
    String? message;
    if (err is Map) {
      if (err['message'] is String) message = err['message'] as String;
      // Some proxies wrap error in { error: { error: { message } } }
      if (message == null && err['error'] is Map && err['error']['message'] is String) {
        message = err['error']['message'] as String;
      }
    } else if (err is String) {
      message = err;
    }
    if (message == null) return false;
    final lower = message.toLowerCase();
    return lower.contains("missing required parameter: 'messages'") || lower.contains('missing required parameter: messages');
  }

  static String? _tryExtractJson(String content) {
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return content.substring(start, end + 1);
    }
    return null;
  }

  static String _extractTextContent(Map<String, dynamic> response) {
    // If an error bubbled through, return a structured error string
    if (response.containsKey('error')) {
      final e = response['error'];
      return jsonEncode({'error': e is String ? e : (e is Map ? e : 'Unknown error')});
    }

    // Normalize different proxy formats for the Responses or Chat APIs
    try {
      // Responses API canonical: { output: [ { content: [ { type: 'output_text', text: '...' } ] } ] }
      final output = response['output'];
      if (output is String && output.isNotEmpty) return output;
      if (output is Map) {
        final content = output['content'];
        if (content is List && content.isNotEmpty) {
          final jsonItem = content.firstWhere(
            (c) => c is Map && (c['type'] == 'output_json' || c['type'] == 'json') && c['json'] is Map,
            orElse: () => null,
          );
          if (jsonItem is Map && jsonItem['json'] is Map) {
            return jsonEncode(jsonItem['json']);
          }
          final textItem = content.firstWhere(
            (c) => c is Map && (c['type'] == 'output_text' || c['type'] == 'text'),
            orElse: () => null,
          );
          if (textItem is Map) {
            final t = textItem['text'];
            if (t is String) return t;
            if (t is Map) return jsonEncode(t);
          }
          final str = content.firstWhere((c) => c is String, orElse: () => null);
          if (str is String) return str;
        }
        final text = output['text'];
        if (text is String && text.isNotEmpty) return text;
      }
      if (output is List && output.isNotEmpty) {
        final first = output.first;
        if (first is Map) {
          final content = first['content'];
          if (content is List && content.isNotEmpty) {
            final jsonItem = content.firstWhere(
              (c) => c is Map && (c['type'] == 'output_json' || c['type'] == 'json') && c['json'] is Map,
              orElse: () => null,
            );
            if (jsonItem is Map && jsonItem['json'] is Map) {
              return jsonEncode(jsonItem['json']);
            }
            final textItem = content.firstWhere(
              (c) => c is Map && (c['type'] == 'output_text' || c['type'] == 'text'),
              orElse: () => null,
            );
            if (textItem is Map) {
              final t = textItem['text'];
              if (t is String) return t;
              if (t is Map) return jsonEncode(t);
            }
            if (content.isNotEmpty && content.first is String) {
              return content.join(' ');
            }
          }
          final text = first['text'];
          if (text is String && text.isNotEmpty) return text;
        }
      }

      // Chat Completions canonical: choices[0].message.content
      final choices = response['choices'];
      if (choices is List && choices.isNotEmpty) {
        final msg = choices.first['message'];
        if (msg is Map && msg['content'] is String) return msg['content'] as String;
        final contentArr = msg is Map ? msg['content'] : null;
        if (contentArr is List && contentArr.isNotEmpty) {
          final maybeText = contentArr.firstWhere(
            (x) => x is Map && (x['type'] == 'text' || x['type'] == 'output_text'),
            orElse: () => null,
          );
          if (maybeText is Map) {
            final t = maybeText['text'];
            if (t is String) return t;
            if (t is Map) return jsonEncode(t);
          }
          final strItem = contentArr.firstWhere(
            (x) => x is String,
            orElse: () => null,
          );
          if (strItem is String) return strItem;
        }
      }

      // Root-level content variants
      final rootContent = response['content'];
      if (rootContent is String && rootContent.isNotEmpty) return rootContent;
      if (rootContent is Map) return jsonEncode(rootContent);
      if (rootContent is List && rootContent.isNotEmpty) {
        final str = rootContent.firstWhere((x) => x is String, orElse: () => null);
        if (str is String) return str;
      }
      final message = response['message'];
      if (message is Map && message['content'] is String) return message['content'] as String;
    } catch (_) {}
    return jsonEncode({'error': 'No content'});
  }

  static Map<String, dynamic>? _findEmbeddedJsonInResponse(dynamic response) {
    try {
      if (response is Map) {
        for (final entry in response.entries) {
          final v = entry.value;
          if (v is Map<String, dynamic>) {
            if (v.containsKey('meals') || v.containsKey('dailyTotals') || v.containsKey('foods')) {
              return v.cast<String, dynamic>();
            }
            final nested = _findEmbeddedJsonInResponse(v);
            if (nested != null) return nested;
          }
          if (v is String) {
            final extracted = _tryExtractJson(v);
            if (extracted != null) {
              final obj = jsonDecode(extracted);
              if (obj is Map<String, dynamic>) return obj;
            }
          }
          if (v is List) {
            for (final item in v) {
              final nested = _findEmbeddedJsonInResponse(item);
              if (nested != null) return nested;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}

class OpenAIError implements Exception {
  final String message;
  OpenAIError(this.message);
  @override
  String toString() => message;
}
