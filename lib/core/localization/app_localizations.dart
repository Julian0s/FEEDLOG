import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static final Map<String, Map<String, String>> _localized = {
    'en': {
      'app_title': 'FEEDLOG',
      'welcome_title': 'Welcome to FEEDLOG',
      'get_started': 'Get Started',
      'home': 'Home',
      'log': 'Log',
      'progress': 'Progress',
      'settings': 'Settings',
      'ai_prompt_hint': 'Describe your meal or paste nutrition label text...',
      'send': 'Send',
      'upload_label': 'Upload Label Photo',
      'theme': 'Theme',
      'language': 'Language',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
    },
    'es': {
      'app_title': 'FEEDLOG',
      'welcome_title': 'Bienvenido a FEEDLOG',
      'get_started': 'Comenzar',
      'home': 'Inicio',
      'log': 'Registro',
      'progress': 'Progreso',
      'settings': 'Configuración',
      'ai_prompt_hint': 'Describe tu comida o pega texto de etiqueta...',
      'send': 'Enviar',
      'upload_label': 'Subir foto de etiqueta',
      'theme': 'Tema',
      'language': 'Idioma',
      'system': 'Sistema',
      'light': 'Claro',
      'dark': 'Oscuro',
    },
  };

  String t(String key) {
    final table = _localized[locale.languageCode] ?? _localized['en']!;
    return table[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
