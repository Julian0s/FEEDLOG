import 'dart:convert';
import 'package:http/http.dart' as http;

// IMPORTANT: Environment-driven configuration (provided at runtime)
const String clientId = String.fromEnvironment('FATSECRET_CLIENT_ID');
const String clientSecret = String.fromEnvironment('FATSECRET_CLIENT_SECRET');

/// FatSecret Platform API client with OAuth 2.0 authentication
class FatSecretClient {
  final http.Client _http;
  String? _accessToken;
  DateTime? _tokenExpiry;

  FatSecretClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;

  /// OAuth 2.0 token endpoint
  static const String _tokenEndpoint = 'https://oauth.fatsecret.com/connect/token';

  /// API base endpoint
  static const String _apiBase = 'https://platform.fatsecret.com/rest';

  // --- Public API ---

  /// Search for foods by name
  /// Returns list of foods with basic info (food_id, name, description)
  Future<List<Map<String, dynamic>>> searchFoods({
    required String query,
    int maxResults = 20,
    int pageNumber = 0,
  }) async {
    await _ensureValidToken();

    final uri = Uri.parse('$_apiBase/foods/search/v1').replace(queryParameters: {
      'search_expression': query,
      'max_results': maxResults.toString(),
      'page_number': pageNumber.toString(),
      'format': 'json',
    });

    final res = await _http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw FatSecretError('Food search failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    // Handle response structure: { "foods": { "food": [...] } }
    if (decoded['foods'] is Map) {
      final foods = decoded['foods'] as Map<String, dynamic>;
      final foodList = foods['food'];

      if (foodList is List) {
        return foodList.cast<Map<String, dynamic>>();
      } else if (foodList is Map) {
        // Single result
        return [foodList.cast<String, dynamic>()];
      }
    }

    return [];
  }

  /// Get detailed nutrition data for a specific food by ID
  /// Returns complete nutritional info including micronutrients (vitamins, minerals)
  Future<Map<String, dynamic>> getFoodDetails({
    required String foodId,
  }) async {
    await _ensureValidToken();

    final uri = Uri.parse('$_apiBase/food/v4').replace(queryParameters: {
      'food_id': foodId,
      'format': 'json',
    });

    final res = await _http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw FatSecretError('Get food details failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return decoded['food'] as Map<String, dynamic>;
  }

  // --- Internal helpers ---

  /// Ensures we have a valid access token, refreshing if necessary
  Future<void> _ensureValidToken() async {
    if (!isConfigured) {
      throw FatSecretError('FatSecret API is not configured. Provide FATSECRET_CLIENT_ID and FATSECRET_CLIENT_SECRET.');
    }

    // Check if token is still valid (with 5 minute buffer)
    if (_accessToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
        return; // Token still valid
      }
    }

    // Request new token
    await _requestAccessToken();
  }

  /// Request OAuth 2.0 access token using client credentials
  Future<void> _requestAccessToken() async {
    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    final res = await _http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
        'scope': 'basic',
      },
    );

    if (res.statusCode != 200) {
      throw FatSecretError('OAuth token request failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    _accessToken = decoded['access_token'] as String;
    final expiresIn = decoded['expires_in'] as int; // seconds
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

    // ignore: avoid_print
    print('FatSecret access token acquired, expires in $expiresIn seconds');
  }
}

class FatSecretError implements Exception {
  final String message;
  FatSecretError(this.message);

  @override
  String toString() => message;
}