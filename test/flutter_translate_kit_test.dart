import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter_translate_kit/flutter_translate_kit.dart';

void main() {
  group('KitLanguages', () {
    test('fromCode returns correct TranslateLanguage for valid codes', () {
      expect(KitLanguages.fromCode('en'), TranslateLanguage.english);
      expect(KitLanguages.fromCode('hi'), TranslateLanguage.hindi);
      expect(KitLanguages.fromCode('ar'), TranslateLanguage.arabic);
      expect(KitLanguages.fromCode('fr'), TranslateLanguage.french);
    });

    test('fromCode returns null for unknown codes', () {
      expect(KitLanguages.fromCode('xx'), isNull);
      expect(KitLanguages.fromCode(''), isNull);
    });

    test('fromCode is case-insensitive', () {
      expect(KitLanguages.fromCode('EN'), TranslateLanguage.english);
      expect(KitLanguages.fromCode('Hi'), TranslateLanguage.hindi);
    });

    test('isRTL returns true for RTL languages', () {
      expect(KitLanguages.isRTL(TranslateLanguage.arabic), isTrue);
      expect(KitLanguages.isRTL(TranslateLanguage.urdu), isTrue);
      expect(KitLanguages.isRTL(TranslateLanguage.hebrew), isTrue);
      expect(KitLanguages.isRTL(TranslateLanguage.persian), isTrue);
    });

    test('isRTL returns false for LTR languages', () {
      expect(KitLanguages.isRTL(TranslateLanguage.english), isFalse);
      expect(KitLanguages.isRTL(TranslateLanguage.hindi), isFalse);
      expect(KitLanguages.isRTL(TranslateLanguage.french), isFalse);
    });

    test('getDisplayName returns readable name', () {
      expect(KitLanguages.getDisplayName(TranslateLanguage.english), 'English');
      expect(KitLanguages.getDisplayName(TranslateLanguage.hindi), 'हिन्दी');
      expect(KitLanguages.getDisplayName(TranslateLanguage.arabic), 'العربية');
    });

    test('all returns a non-empty list of languages', () {
      expect(KitLanguages.all, isNotEmpty);
      expect(KitLanguages.all, contains(TranslateLanguage.english));
    });
  });

  group('KitLanguageExtension', () {
    test('displayName returns readable name', () {
      expect(TranslateLanguage.english.displayName, 'English');
    });

    test('isRTL works via extension', () {
      expect(TranslateLanguage.arabic.isRTL, isTrue);
      expect(TranslateLanguage.english.isRTL, isFalse);
    });
  });
}
