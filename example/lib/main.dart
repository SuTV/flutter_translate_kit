import 'package:flutter/material.dart';
import 'package:flutter_translate_kit/flutter_translate_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ One-time init — set Hindi as default language
  await TranslationService().init(
    targetLanguage: TranslateLanguage.hindi,
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ KitScope handles locale + RTL automatically
    return KitScope(
      builder: (locale, delegates) => MaterialApp(
        title: 'flutter_translate_kit Example',
        locale: locale,
        localizationsDelegates: delegates,
        supportedLocales: KitScope.supportedLocales,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✅ KitText auto-translates
        title: KitText('My App', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguagePicker(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language switcher
            const KitLanguageSwitcher(
              languages: [
                TranslateLanguage.english,
                TranslateLanguage.hindi,
                TranslateLanguage.arabic,
                TranslateLanguage.french,
                TranslateLanguage.spanish,
                TranslateLanguage.urdu,
              ],
            ),

            const SizedBox(height: 24),

            // All these translate automatically
            KitText(
              'Welcome to the app!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const KitText('This text is translated on-device using ML Kit.'),
            const SizedBox(height: 8),
            const KitText('No internet connection required.'),
            const SizedBox(height: 8),
            const KitText('Supports 50+ languages out of the box.'),

            const SizedBox(height: 24),

            // Model download
            KitModelDownloadButton(
              language: TranslateLanguage.hindi,
              onDownloaded: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hindi model ready!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final mediaQuery = MediaQuery.of(context);
        final bottomInset = mediaQuery.viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const KitText(
                      'Change language',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const KitText(
                  'Pick a language. If needed, the translation model will be downloaded before switching.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                KitLanguageSwitcher(
                  languages: const [
                    TranslateLanguage.english,
                    TranslateLanguage.hindi,
                    TranslateLanguage.arabic,
                    TranslateLanguage.french,
                    TranslateLanguage.spanish,
                    TranslateLanguage.german,
                    TranslateLanguage.urdu,
                    TranslateLanguage.chinese,
                    TranslateLanguage.japanese,
                  ],
                  onChanged: (_) => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}