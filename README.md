# flutter_translate_kit 🌍

[![pub.dev](https://img.shields.io/pub/v/flutter_translate_kit.svg)](https://pub.dev/packages/flutter_translate_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-blue)](https://pub.dev/packages/flutter_translate_kit)

**The only Flutter localization package you'll ever need.**

> ✅ No API keys &nbsp;|&nbsp; ✅ Works offline &nbsp;|&nbsp; ✅ 50+ languages &nbsp;|&nbsp; ✅ CLI auto-wraps your entire app &nbsp;|&nbsp; ✅ RTL auto-support

---

## Why flutter_translate_kit?

| Feature | Other packages | flutter_translate_kit |
|---|---|---|
| No API key needed | ❌ Requires key | ✅ Never needed |
| Works offline | ❌ | ✅ On-device ML |
| CLI auto-wrap | ❌ | ✅ One command |
| RTL auto-detect | ❌ | ✅ Built-in |
| Smart caching | ❌ | ✅ Hive-powered |
| No `.arb` files | ❌ Required | ✅ Never needed |

---

## Quick Start

### 1. Install

```yaml
# pubspec.yaml
dependencies:
  flutter_translate_kit: ^0.0.1
```

### 2. Initialize in `main.dart`

```dart
import 'package:flutter_translate_kit/flutter_translate_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TranslationService().init(
    targetLanguage: TranslateLanguage.hindi, // 👈 Set your language
  );

  runApp(const MyApp());
}
```

### 3. Wrap your `MaterialApp` in `app.dart`

```dart
import 'package:flutter_translate_kit/flutter_translate_kit.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KitScope(
      builder: (locale, delegates) => MaterialApp(
        locale: locale,
        localizationsDelegates: delegates,
        supportedLocales: KitScope.supportedLocales,
        home: HomeScreen(),
      ),
    );
  }
}
```

### 4. Use `KitText` instead of `Text`

```dart
// Before
Text('Welcome to the app')

// After
KitText('Welcome to the app')   // auto-translates to Hindi ✅
```

---

## CLI — Auto-wrap your entire project

For large existing apps, use the CLI to automatically replace every `Text()` with `KitText()`:

```bash
# Install globally (after publishing to pub.dev)
dart pub global activate flutter_translate_kit

# Or activate locally during development
dart pub global activate --source path .

# Preview what will change (no files touched)
ftk wrap --dry-run

# Apply to all files
ftk wrap

# Check your coverage
ftk stats

# Undo if needed
ftk restore
```

**Before:**
```dart
Text('Welcome')
Text('Settings', style: TextStyle(fontSize: 16))
Text(myVariable)
```

**After (auto-generated):**
```dart
KitText('Welcome')
KitText('Settings', style: TextStyle(fontSize: 16))
KitText(myVariable)
```

---

## Features

### Switch Language at Runtime

```dart
// Switch to any of 50+ languages instantly
await TranslationService().setLanguage(TranslateLanguage.arabic);
await TranslationService().setLanguage(TranslateLanguage.french);
await TranslationService().setLanguageByCode('de'); // by BCP-47 code
```

Language preference is **persisted** — survives app restarts automatically.

### Built-in Language Switcher UI

```dart
KitLanguageSwitcher(
  languages: [
    TranslateLanguage.english,
    TranslateLanguage.hindi,
    TranslateLanguage.arabic,
    TranslateLanguage.french,
  ],
  onChanged: (lang) => print('Changed to ${lang.displayName}'),
)
```

### Model Download with Progress

```dart
KitModelDownloadButton(
  language: TranslateLanguage.hindi,
  onDownloaded: () => print('Hindi model ready!'),
)
```

### String Extension

```dart
final translated = await 'Hello World'.kit;
```

### RTL Auto-Detection

When you switch to Arabic, Urdu, Hebrew, or Persian — the entire app layout flips to RTL automatically. No extra code needed.

### Smart Translation Cache

Translated strings are cached in Hive. The same string is **never translated twice**, making subsequent launches near-instant.

```dart
print(TranslationService().cacheSize); // number of cached strings
await TranslationService().clearCache(); // reset if needed
```

### Opt out of translation

```dart
KitText('API_KEY_abc123', translate: false) // never translated
```

---

## Supported Languages (50+)

Hindi, Arabic, French, Spanish, German, Chinese, Japanese, Korean, Portuguese, Russian, Italian, Dutch, Polish, Turkish, Ukrainian, Thai, Vietnamese, Indonesian, Malay, Bengali, Gujarati, Marathi, Tamil, Telugu, Kannada, Urdu, Persian, Hebrew, and more.

---

## Platform Requirements

| Platform | Supported |
|---|---|
| Android | ✅ (API 21+) |
| iOS | ✅ (iOS 15.5+) |
| Web | ❌ (ML Kit is mobile-only) |
| Desktop | ❌ |

### Android setup

No additional setup required.

### iOS setup

In `ios/Podfile`:
```ruby
platform :ios, '15.5'
```

> **Simulator note (Xcode 26+):** Google ML Kit's native iOS frameworks don't yet include `arm64-simulator` slices, so **building for the iOS Simulator is not supported**. Test on a real device or use an Android emulator. Alternatively, use a Rosetta simulator destination in Xcode.

---

## License

MIT © 2026 — Built with ❤️ using Google ML Kit