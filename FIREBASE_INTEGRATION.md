# FEEDLOG Firebase Integration

## Overview
This document outlines the complete Firebase client code integration for the FEEDLOG app, including authentication, Firestore database, and security configuration.

## Files Created/Modified

### Configuration Files
- `firebase.json` - Firebase project configuration with Firestore rules and indexes
- `firestore.rules` - Security rules for Firestore collections
- `firestore.indexes.json` - Composite indexes for efficient queries
- `pubspec.yaml` - Added Firebase dependencies

### Core Firebase Services
- `lib/firestore/firestore_data_schema.dart` - Data models for Firestore collections
- `lib/firestore/firestore_service.dart` - Main service and repository classes
- `lib/firestore/auth_service.dart` - Authentication service and provider

### Updated Providers
- `lib/core/providers/firebase_profile_provider.dart` - Firebase-integrated profile management
- `lib/core/providers/firebase_meal_provider.dart` - Firebase-integrated meal management
- `lib/main.dart` - Firebase initialization and provider setup

### Authentication UI
- `lib/features/auth/login_page.dart` - Sign in page
- `lib/features/auth/signup_page.dart` - Account creation page  
- `lib/features/auth/auth_wrapper.dart` - Authentication state wrapper
- `lib/core/router/app_router.dart` - Updated with auth routes

## Firebase Collections

### 1. `user_profiles`
Stores user profile information and onboarding data.
- **Security**: Private to each user (owner_id == auth.uid)
- **Fields**: personal info, goals, activity level, dietary restrictions

### 2. `user_meals` 
Stores meal entries with nutrition data and AI analysis.
- **Security**: Private to each user (owner_id == auth.uid)
- **Fields**: meal details, macros, photos, AI analysis
- **Indexes**: By date, meal type, and user

### 3. `user_progress`
Tracks progress metrics like weight, calories, exercise.
- **Security**: Private to each user (owner_id == auth.uid) 
- **Fields**: metric type, value, date, notes
- **Indexes**: By date and metric type

### 4. `user_goals`
Stores user-defined nutrition and fitness goals.
- **Security**: Private to each user (owner_id == auth.uid)
- **Fields**: goal type, target value, target date, active status

### 5. `user_settings`
App preferences and notification settings.
- **Security**: Private to each user (owner_id == auth.uid)
- **Fields**: theme, language, units, notification preferences

### 6. `food_items` (Public)
Database of food items with nutrition information.
- **Security**: Read-only for authenticated users
- **Fields**: name, brand, nutrition per serving, barcode

## Key Features

### Authentication
- Email/password sign in and registration
- Anonymous guest access
- Password reset functionality
- Profile management (display name, photo)

### Data Sync
- Real-time sync between local and Firestore
- Offline support with local caching
- Automatic conflict resolution
- Loading states and error handling

### Security
- Private user data (meals, profile, goals)
- Public food database for all users
- Proper validation rules
- Owner-based access control

## Usage

### Initialize Firebase
Firebase is automatically initialized in `main()` before the app starts.

### Access Services
```dart
final firestoreService = FirestoreService();
// Use repositories: userMeals, userProfiles, userProgress, etc.
```

### Authentication
```dart
final authProvider = context.read<AuthProvider>();
await authProvider.signInWithEmailAndPassword(email, password);
```

### Data Operations
```dart
// Load meals for today
final mealProvider = context.read<FirebaseMealProvider>();
await mealProvider.loadMealsForDate(DateTime.now());

// Save profile
final profileProvider = context.read<FirebaseProfileProvider>();
await profileProvider.saveToFirestore();
```

## Deployment Notes

1. Deploy Firestore rules and indexes:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

2. The app supports both authenticated and anonymous users
3. Data is synced automatically when users are online
4. Local caching ensures offline functionality

## Next Steps

- Add batch operations for bulk data sync
- Implement data migration utilities  
- Add analytics and crash reporting
- Set up cloud functions for server-side operations
- Implement push notifications