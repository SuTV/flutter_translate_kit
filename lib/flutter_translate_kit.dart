/// flutter_translate_kit
///
/// A complete Flutter localization toolkit.
/// On-device ML translation, zero config, offline-first.
///
/// Quick start:
///
/// 1. In main.dart:
///    await TranslationService().init(
///      targetLanguage: TranslateLanguage.hindi,
///    );
///
/// 2. Wrap your MaterialApp:
///    KitScope(
///      builder: (locale, delegates) => MaterialApp(
///        locale: locale,
///        localizationsDelegates: delegates,
///        ...
///      ),
///    )
///
/// 3. Use KitText instead of Text:
///    KitText('Hello World')
///
/// 4. Or use the CLI to auto-wrap your entire project:
///    dart pub global activate flutter_translate_kit
///    ftk wrap

library flutter_translate_kit;

// Core service
export 'src/core/translation_service.dart';
export 'src/core/supported_languages.dart';

// Widgets
export 'src/widgets/kit_text.dart';
export 'src/widgets/kit_scope.dart';
export 'src/widgets/kit_language_switcher.dart';

// Extensions
export 'src/extensions/string_extensions.dart';

// Re-export TranslateLanguage for convenience
export 'package:google_mlkit_translation/google_mlkit_translation.dart'
    show TranslateLanguage;