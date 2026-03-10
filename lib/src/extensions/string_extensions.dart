import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../core/translation_service.dart';
import '../core/supported_languages.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// String Extensions
///
/// Usage:
///   final greeting = await 'Hello'.kit;
///   final title = await 'Settings'.translated(to: TranslateLanguage.hindi);
/// ─────────────────────────────────────────────────────────────────────────────
extension KitStringExtension on String {
  /// Translate this string using the current app language.
  ///
  ///   final text = await 'Welcome'.kit;
  Future<String> get kit => TranslationService.instance.translate(this);

  /// Translate to a specific language.
  ///
  ///   final text = await 'Hello'.translated(to: TranslateLanguage.hindi);
  Future<String> translated({required TranslateLanguage to}) async {
    final service = TranslationService.instance;
    await service.setLanguage(to);
    return service.translate(this);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// TranslateLanguage Extensions
/// ─────────────────────────────────────────────────────────────────────────────
extension KitLanguageExtension on TranslateLanguage {
  /// Human-readable display name (e.g. "हिन्दी" for hindi)
  String get displayName => KitLanguages.getDisplayName(this);

  /// Whether this is a RTL language
  bool get isRTL => KitLanguages.isRTL(this);
}