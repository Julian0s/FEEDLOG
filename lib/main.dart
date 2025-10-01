import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/meal_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/firebase_profile_provider.dart';
import 'core/providers/firebase_meal_provider.dart';
import 'core/router/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'firebase_options.dart';
import 'firestore/firestore_service.dart';
import 'firestore/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Firestore service
  FirestoreService().initialize();
  
  runApp(const FeedLogApp());
}

class FeedLogApp extends StatefulWidget {
  const FeedLogApp({super.key});

  @override
  State<FeedLogApp> createState() => _FeedLogAppState();
}

class _FeedLogAppState extends State<FeedLogApp> {
  late final ThemeProvider _themeProvider;
  late final LocaleProvider _localeProvider;
  late final GoRouter _router;
  late final ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _localeProvider = LocaleProvider();
    _router = AppRouterConfig.build();
    _profileProvider = ProfileProvider();
    // Load persisted settings
    _themeProvider.load();
    _localeProvider.load();
    _profileProvider.load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _localeProvider),
        ChangeNotifierProvider.value(value: _profileProvider),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        // Firebase providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseProfileProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseMealProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, theme, locale, _) {
          return MaterialApp.router(
            title: 'FEEDLOG',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: theme.mode,
            routerConfig: _router,
            locale: locale.locale,
            supportedLocales: const [Locale('en'), Locale('es')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
