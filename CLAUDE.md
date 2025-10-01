# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FEEDLOG is a Flutter-based nutrition and food logging application with Firebase backend integration. The app provides meal tracking, nutrition analysis, progress monitoring, and AI-powered meal parsing via OpenAI proxy.

## Development Commands

### Running the App
```bash
# Run in development mode
flutter run

# Run with specific device
flutter run -d <device-id>

# Run with environment variables (OpenAI proxy + FatSecret API)
flutter run --dart-define=OPENAI_PROXY_API_KEY=your_key --dart-define=OPENAI_PROXY_ENDPOINT=your_endpoint --dart-define=FATSECRET_CLIENT_ID=your_client_id --dart-define=FATSECRET_CLIENT_SECRET=your_client_secret
```

### Building
```bash
# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Build for web
flutter build web

# Generate app icons
flutter pub run flutter_launcher_icons:main
```

### Testing & Linting
```bash
# Run analyzer
flutter analyze

# Format code
flutter format .

# Clean build artifacts
flutter clean
```

### Firebase
```bash
# Deploy Firestore rules and indexes
firebase deploy --only firestore:rules,firestore:indexes

# Deploy only rules
firebase deploy --only firestore:rules

# Deploy only indexes
firebase deploy --only firestore:indexes
```

## Architecture Overview

### State Management: Provider Pattern

The app uses Provider for state management with a **dual provider architecture**:

1. **Local-first providers** ([ProfileProvider](lib/core/providers/profile_provider.dart), [MealProvider](lib/core/providers/meal_provider.dart))
   - Use SharedPreferences for persistence
   - Work offline-first
   - Used during initial development

2. **Firebase-integrated providers** ([FirebaseProfileProvider](lib/core/providers/firebase_profile_provider.dart), [FirebaseMealProvider](lib/core/providers/firebase_meal_provider.dart))
   - Sync with Firestore in real-time
   - Maintain local cache for offline support
   - Listen to auth state changes and clear data on sign-out
   - Automatically convert between local models and Firestore schemas

Both provider types coexist in [main.dart](lib/main.dart) to support gradual migration and backwards compatibility.

### Navigation: GoRouter with Auth Guards

Navigation is configured in [app_router.dart](lib/core/router/app_router.dart) using go_router:

- **Public routes**: `/login`, `/signup`, `/welcome`, `/forgot-password`
- **Protected routes** (ShellRoute): `/home`, `/log`, `/progress`, `/settings`
  - Auth guard wraps all protected routes
  - StreamBuilder listens to Firebase Auth state
  - Redirects to `/login` if unauthenticated
  - Shows bottom navigation bar with FAB (except on settings page)

The [AuthWrapper](lib/features/auth/auth_wrapper.dart) at `/` redirects authenticated users to `/home` or unauthenticated users to `/welcome`.

### Firebase Integration

#### Authentication ([auth_service.dart](lib/firestore/auth_service.dart))
- Email/password authentication
- Anonymous sign-in for guest access
- Password reset via email
- Profile management (display name, photo)
- User-friendly error messages for all Firebase Auth exceptions

#### Firestore Service ([firestore_service.dart](lib/firestore/firestore_service.dart))
Singleton service providing repository instances:
- `userProfiles`: User profile data and onboarding info
- `userMeals`: Meal entries with nutrition data
- `userProgress`: Progress metrics (weight, exercise, etc.)
- `userGoals`: User-defined nutrition/fitness goals
- `userSettings`: App preferences and settings
- `foodItems`: Public food database (read-only for users)

**Repository Pattern**: All repositories extend `BaseRepository<T>` with common CRUD operations and automatic owner ID injection.

#### Firestore Collections ([firestore_data_schema.dart](lib/firestore/firestore_data_schema.dart))
1. `user_profiles`: Personal info, goals, activity level, dietary restrictions
2. `user_meals`: Meal entries with foods, macros, photos, AI analysis
3. `user_progress`: Time-series metrics (weight, calories, exercise)
4. `user_goals`: User-defined targets with deadlines
5. `user_settings`: Theme, language, units, notification preferences
6. `food_items`: Public food database (admin-managed)

**Security model** ([firestore.rules](firestore.rules)):
- All user collections enforce `owner_id == auth.uid`
- Public collections (`food_items`, `recipes`) are read-only for authenticated users
- Write access to public collections requires server-side admin privileges

### Data Conversion Pattern

Firebase-integrated providers implement bidirectional conversion:

**Local → Firestore** (`_convertToFirestore`):
- Maps local `MealEntry`/`UserProfile` models to `UserMealFS`/`UserProfileFS`
- Injects `owner_id` from current auth user
- Sets timestamps (`createdAt`, `updatedAt`)

**Firestore → Local** (`_convertFromFirestore`):
- Maps Firestore schemas back to local models
- Extracts nested arrays (e.g., `foodItems` → `List<FoodItem>`)
- Parses enum strings (e.g., `"breakfast"` → `MealType.breakfast`)

This pattern allows UI code to use clean local models while maintaining Firestore compatibility.

### OpenAI Integration ([openai_config.dart](lib/openai/openai_config.dart))

**Environment-driven configuration**:
- API key and endpoint provided via `--dart-define` flags at runtime
- Never hardcode credentials in source

**Multi-language meal parsing** (`parseMealFromText`):
- Accepts casual input in any language (English, Spanish, Portuguese, French, Italian, etc.)
- Infers missing quantities/units using typical portion sizes
- Returns structured JSON with meals, foods, and nutrition estimates
- Handles comma decimals and normalizes to dot decimals

**Dual API support with automatic fallback**:
1. Attempts Responses API (`/responses` endpoint) first
2. Falls back to Chat Completions API (`/chat/completions`) if:
   - Responses endpoint returns error about missing `messages` parameter
   - Proxy doesn't support Responses API (404/400 errors)
   - Endpoint returns "unrecognized request argument" errors

**Nutrition label OCR** (`analyzeNutritionLabelFromImage`):
- Accepts image bytes, base64-encodes, and sends to vision-capable model
- Extracts serving size, nutrients, and nutrition facts in structured JSON

### FatSecret Integration ([fatsecret_config.dart](lib/fatsecret/fatsecret_config.dart))

**Environment-driven configuration**:
- Client ID and Secret provided via `--dart-define` flags at runtime
- OAuth 2.0 authentication with automatic token refresh
- Never hardcode credentials in source

**Food search and enrichment** ([fatsecret_helper.dart](lib/fatsecret/fatsecret_helper.dart)):
- Searches FatSecret database for foods by name
- Retrieves detailed nutrition data including micronutrients
- Automatically scales nutrition data to match user's portion size
- Integrates with OpenAI flow to enrich AI-parsed meals with real nutrition data

**Nutritional data provided**:
- **Macros**: Calories, protein, carbs, fat, fiber, sugar, saturated fat, cholesterol
- **Minerals**: Calcium, iron, magnesium, zinc, potassium, sodium
- **Vitamins**: Vitamin A, C, D, E

**Usage flow**:
1. User inputs meal via chat (OpenAI parses text)
2. For each food item, FatSecret searches for best match
3. Detailed nutrition data fetched and scaled to quantity
4. Enriched meal saved to Firestore with complete micronutrient data

### Models

**Core models** ([meal_models.dart](lib/core/models/meal_models.dart), [profile_models.dart](lib/core/models/profile_models.dart)):
- `MealEntry`: Meal with date, type, foods, and totals
- `FoodItem`: Individual food with quantity, unit, and nutrition estimates
- `Macros`: Complete nutrition data including macros (calories, protein, carbs, fat), micronutrients (minerals and vitamins), and additional fields (fiber, sugar, saturated fat, cholesterol)
- `UserProfile`: Personal info, goals, activity level, computed TDEE and macro targets

All models are immutable (`@immutable`) with `copyWith`, `toJson`, and `fromJson` methods.

### Localization

- `AppLocalizations` provides i18n support ([app_localizations.dart](lib/core/localization/app_localizations.dart))
- Supported locales: English (`en`), Spanish (`es`)
- `LocaleProvider` persists user's language preference

## Development Notes

### Adding New Firestore Collections
1. Define schema in [firestore_data_schema.dart](lib/firestore/firestore_data_schema.dart)
2. Create repository class extending `BaseRepository<T>` in [firestore_service.dart](lib/firestore/firestore_service.dart)
3. Add security rules in [firestore.rules](firestore.rules)
4. Add indexes if needed in [firestore.indexes.json](firestore.indexes.json)
5. Deploy: `firebase deploy --only firestore:rules,firestore:indexes`

### Working with Providers
- Use `context.read<T>()` to access provider without listening
- Use `context.watch<T>()` or `Consumer<T>` to rebuild on changes
- Firebase providers listen to auth state and auto-clear on sign-out
- Always check `isAuthenticated` before Firestore operations

### Testing OpenAI Integration
- Set environment variables when running: `flutter run --dart-define=OPENAI_PROXY_API_KEY=... --dart-define=OPENAI_PROXY_ENDPOINT=...`
- Check `OpenAIClient.isConfigured` before calling API methods
- Test with multi-language inputs to verify meal type normalization

### Testing FatSecret Integration
- Set environment variables when running: `flutter run --dart-define=FATSECRET_CLIENT_ID=... --dart-define=FATSECRET_CLIENT_SECRET=...`
- Check `FatSecretClient.isConfigured` before calling API methods
- App gracefully falls back to OpenAI-only estimates if FatSecret not configured
- Micronutrients on home dashboard will show real data from FatSecret-enriched meals

### Onboarding Flow
1. `/welcome` → User chooses sign up or sign in
2. `/onboarding/step1` → Personal info (name, age, gender, height, weight)
3. `/onboarding/step2` → Activity level
4. `/onboarding/step3` → Goals (goal type, target weight)
5. `/onboarding/step4` → Results (computed TDEE and macro targets)
6. Profile saved to Firestore via `FirebaseProfileProvider.finalizeOnboarding()`