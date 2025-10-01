import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal_models.dart';
import '../../firestore/auth_service.dart';
import '../providers/firebase_meal_provider.dart';
import '../../services/cloud_functions_service.dart';

/// UPDATED: This version uses Firebase Cloud Functions instead of direct API calls
/// No more --dart-define credentials needed! API keys are stored securely in backend.
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
  final _cloudFunctions = CloudFunctionsService();
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

    if (msg.contains('unauthenticated')) {
      switch (lang) {
        case 'pt':
          return 'Você precisa estar logado para usar esta funcionalidade.';
        case 'es':
          return 'Debes iniciar sesión para usar esta función.';
        default:
          return 'You must be logged in to use this feature.';
      }
    }

    if (msg.contains('Parse meal failed') || msg.contains('Parse + enrich failed')) {
      switch (lang) {
        case 'pt':
          return 'Não consegui entender. Tente simplificar a descrição (ex.: quantidades e unidades).';
        case 'es':
          return 'No pude entender. Intenta simplificar la descripción (cantidades y unidades).';
        default:
          return "I couldn't understand. Try simplifying the description (quantities and units).";
      }
    }

    // Fallback generic
    switch (lang) {
      case 'pt':
        return 'Ocorreu um erro. Tente novamente.';
      case 'es':
        return 'Ocurrió un error. Inténtalo de nuevo.';
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
      // Call Cloud Function - no API keys needed in app!
      final enrichedMeals = await _cloudFunctions.parseMealWithEnrichment(
        userText: text,
      );

      if (enrichedMeals.isEmpty) {
        throw Exception('No meals parsed');
      }

      if (!mounted) return;

      // Save to Firestore or local storage
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

      // Call Cloud Function for OCR
      final json = await _cloudFunctions.analyzeNutritionLabel(imageBytes: bytes);

      // Show result
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
}
