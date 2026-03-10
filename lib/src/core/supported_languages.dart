import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// KitLanguages
///
/// Helper class for language metadata:
///   • BCP-47 code ↔ TranslateLanguage conversion
///   • RTL detection (Arabic, Urdu, Hebrew, Persian, etc.)
///   • Human-readable display names
/// ─────────────────────────────────────────────────────────────────────────────
class KitLanguages {
  KitLanguages._();

  /// RTL language codes
  static const Set<String> _rtlCodes = {
    'ar', // Arabic
    'ur', // Urdu
    'he', // Hebrew
    'fa', // Persian / Farsi
  };

  /// Map of BCP-47 code → TranslateLanguage
  static const Map<String, TranslateLanguage> _codeMap = {
    'af': TranslateLanguage.afrikaans,
    'ar': TranslateLanguage.arabic,
    'be': TranslateLanguage.belarusian,
    'bg': TranslateLanguage.bulgarian,
    'bn': TranslateLanguage.bengali,
    'ca': TranslateLanguage.catalan,
    'cs': TranslateLanguage.czech,
    'cy': TranslateLanguage.welsh,
    'da': TranslateLanguage.danish,
    'de': TranslateLanguage.german,
    'el': TranslateLanguage.greek,
    'en': TranslateLanguage.english,
    'eo': TranslateLanguage.esperanto,
    'es': TranslateLanguage.spanish,
    'et': TranslateLanguage.estonian,
    'fa': TranslateLanguage.persian,
    'fi': TranslateLanguage.finnish,
    'fr': TranslateLanguage.french,
    'ga': TranslateLanguage.irish,
    'gl': TranslateLanguage.galician,
    'gu': TranslateLanguage.gujarati,
    'he': TranslateLanguage.hebrew,
    'hi': TranslateLanguage.hindi,
    'hr': TranslateLanguage.croatian,
    'hu': TranslateLanguage.hungarian,
    'id': TranslateLanguage.indonesian,
    'is': TranslateLanguage.icelandic,
    'it': TranslateLanguage.italian,
    'ja': TranslateLanguage.japanese,
    'ka': TranslateLanguage.georgian,
    'kn': TranslateLanguage.kannada,
    'ko': TranslateLanguage.korean,
    'lt': TranslateLanguage.lithuanian,
    'lv': TranslateLanguage.latvian,
    'mk': TranslateLanguage.macedonian,
    'mr': TranslateLanguage.marathi,
    'ms': TranslateLanguage.malay,
    'mt': TranslateLanguage.maltese,
    'nl': TranslateLanguage.dutch,
    'no': TranslateLanguage.norwegian,
    'pl': TranslateLanguage.polish,
    'pt': TranslateLanguage.portuguese,
    'ro': TranslateLanguage.romanian,
    'ru': TranslateLanguage.russian,
    'sk': TranslateLanguage.slovak,
    'sl': TranslateLanguage.slovenian,
    'sq': TranslateLanguage.albanian,
    'sv': TranslateLanguage.swedish,
    'sw': TranslateLanguage.swahili,
    'ta': TranslateLanguage.tamil,
    'te': TranslateLanguage.telugu,
    'th': TranslateLanguage.thai,
    'tl': TranslateLanguage.tagalog,
    'tr': TranslateLanguage.turkish,
    'uk': TranslateLanguage.ukrainian,
    'ur': TranslateLanguage.urdu,
    'vi': TranslateLanguage.vietnamese,
    'zh': TranslateLanguage.chinese,
  };

  /// Human-readable display names
  static const Map<TranslateLanguage, String> displayNames = {
    TranslateLanguage.afrikaans: 'Afrikaans',
    TranslateLanguage.arabic: 'العربية',
    TranslateLanguage.bengali: 'বাংলা',
    TranslateLanguage.chinese: '中文',
    TranslateLanguage.croatian: 'Hrvatski',
    TranslateLanguage.czech: 'Čeština',
    TranslateLanguage.danish: 'Dansk',
    TranslateLanguage.dutch: 'Nederlands',
    TranslateLanguage.english: 'English',
    TranslateLanguage.french: 'Français',
    TranslateLanguage.german: 'Deutsch',
    TranslateLanguage.greek: 'Ελληνικά',
    TranslateLanguage.gujarati: 'ગુજરાતી',
    TranslateLanguage.hebrew: 'עברית',
    TranslateLanguage.hindi: 'हिन्दी',
    TranslateLanguage.hungarian: 'Magyar',
    TranslateLanguage.indonesian: 'Bahasa Indonesia',
    TranslateLanguage.italian: 'Italiano',
    TranslateLanguage.japanese: '日本語',
    TranslateLanguage.kannada: 'ಕನ್ನಡ',
    TranslateLanguage.korean: '한국어',
    TranslateLanguage.marathi: 'मराठी',
    TranslateLanguage.persian: 'فارسی',
    TranslateLanguage.polish: 'Polski',
    TranslateLanguage.portuguese: 'Português',
    TranslateLanguage.romanian: 'Română',
    TranslateLanguage.russian: 'Русский',
    TranslateLanguage.spanish: 'Español',
    TranslateLanguage.swahili: 'Kiswahili',
    TranslateLanguage.swedish: 'Svenska',
    TranslateLanguage.tamil: 'தமிழ்',
    TranslateLanguage.telugu: 'తెలుగు',
    TranslateLanguage.thai: 'ภาษาไทย',
    TranslateLanguage.turkish: 'Türkçe',
    TranslateLanguage.ukrainian: 'Українська',
    TranslateLanguage.urdu: 'اردو',
    TranslateLanguage.vietnamese: 'Tiếng Việt',
  };

  /// Convert BCP-47 code string to TranslateLanguage
  static TranslateLanguage? fromCode(String code) =>
      _codeMap[code.toLowerCase()];

  /// Check if a language is RTL
  static bool isRTL(TranslateLanguage language) =>
      _rtlCodes.contains(language.bcpCode);

  /// Get display name for a language
  static String getDisplayName(TranslateLanguage language) =>
      displayNames[language] ?? language.bcpCode;

  /// All supported languages as a list
  static List<TranslateLanguage> get all => _codeMap.values.toList();
}
