import 'dart:async';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'supported_languages.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// TranslationService
///
/// The core singleton that powers flutter_translate_kit.
///
/// Features:
///   • On-device ML Kit translation (offline, free, 50+ languages)
///   • Smart Hive cache — translated once, served forever
///   • Reactive language stream — UI rebuilds automatically
///   • Model download management with progress callbacks
///   • RTL auto-detection
/// ─────────────────────────────────────────────────────────────────────────────
class TranslationService {
  TranslationService._internal();
  static final TranslationService instance = TranslationService._internal();
  factory TranslationService() => instance;

  // ── State ──────────────────────────────────────────────────────────────────
  static const String _cacheBoxName = 'ftk_translations';
  static const String _settingsBoxName = 'ftk_settings';
  static const String _langKey = 'selected_language';

  late Box<String> _cacheBox;
  late Box<dynamic> _settingsBox;

  final BehaviorSubject<TranslateLanguage> _languageSubject =
  BehaviorSubject<TranslateLanguage>.seeded(TranslateLanguage.english);

  final BehaviorSubject<bool> _languageChangingSubject =
  BehaviorSubject<bool>.seeded(false);

  OnDeviceTranslator? _translator;
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.english;

  bool _initialized = false;
  bool _disposed = false;

  /// Number of [translate] calls currently in progress (used to hide loading only when all done).
  int _pendingTranslations = 0;
  Completer<void>? _languageChangeCompleter;

  /// Delay after emitting new language before we start waiting for pending translations
  /// (gives KitText widgets time to rebuild and call [translate]). Default: 350ms.
  static Duration languageChangeSettleDuration = const Duration(milliseconds: 350);

  /// Max time to wait for pending translations after a language change. Default: 10s.
  static Duration languageChangeMaxWait = const Duration(seconds: 10);

  // ── Public Getters ─────────────────────────────────────────────────────────

  /// Stream that emits whenever the language changes.
  /// Widgets listen to this to rebuild.
  Stream<TranslateLanguage> get languageStream => _languageSubject.stream;

  /// True while language is switching and the app is still updating text.
  /// Use with [KitLanguageChangeOverlay] to show a loading screen.
  bool get isLanguageChanging => _languageChangingSubject.value;

  /// Stream that emits when [isLanguageChanging] changes.
  Stream<bool> get languageChangingStream => _languageChangingSubject.stream;

  /// Current active language
  TranslateLanguage get currentLanguage => _languageSubject.value;

  /// Is the current language RTL? (Arabic, Urdu, Hebrew, Persian, etc.)
  bool get isRTL => KitLanguages.isRTL(currentLanguage);

  bool get isInitialized => _initialized;

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Initialize the service. Call this once in main() before runApp().
  ///
  /// ```dart
  /// await TranslationService().init(
  ///   sourceLanguage: TranslateLanguage.english,
  ///   targetLanguage: TranslateLanguage.hindi,
  /// );
  /// ```
  Future<void> init({
    TranslateLanguage sourceLanguage = TranslateLanguage.english,
    TranslateLanguage targetLanguage = TranslateLanguage.english,
    bool clearCacheOnInit = false,
  }) async {
    if (_initialized) return;

    await Hive.initFlutter();
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    if (clearCacheOnInit) await _cacheBox.clear();

    _sourceLanguage = sourceLanguage;

    // Restore previously saved language or use provided target
    final savedLang = _settingsBox.get(_langKey);
    if (savedLang != null) {
      _targetLanguage = KitLanguages.fromCode(savedLang) ?? targetLanguage;
    } else {
      _targetLanguage = targetLanguage;
    }

    _languageSubject.add(_targetLanguage);
    await _initTranslator();
    _initialized = true;

    log('[TranslateKit] Initialized → ${_targetLanguage.bcpCode}', name: 'flutter_translate_kit');
  }

  // ── Language Switching ─────────────────────────────────────────────────────

  /// Switch the entire app to a new language.
  /// Persists across app restarts.
  /// Loading stays visible until all visible [KitText] widgets have finished
  /// translating (or [languageChangeMaxWait] is reached).
  ///
  /// ```dart
  /// await TranslationService().setLanguage(TranslateLanguage.hindi);
  /// ```
  Future<void> setLanguage(TranslateLanguage language) async {
    if (language == _targetLanguage) return;
    if (_disposed) return;

    _languageChangingSubject.add(true);
    _languageChangeCompleter = Completer<void>();

    try {
      _targetLanguage = language;
      await _settingsBox.put(_langKey, language.bcpCode);
      await _initTranslator();
      _languageSubject.add(language);
      log('[TranslateKit] Language changed → ${language.bcpCode}', name: 'flutter_translate_kit');

      // Give widgets time to rebuild and call translate()
      await Future.delayed(languageChangeSettleDuration);

      if (_disposed) return;
      if (_pendingTranslations == 0 && false == _languageChangeCompleter?.isCompleted) {
        _languageChangeCompleter?.complete();
      }
      final completer = _languageChangeCompleter;
      if (completer != null && !completer.isCompleted) {
        await completer.future.timeout(
          languageChangeMaxWait,
          onTimeout: () {
            log('[TranslateKit] Language change wait timed out', name: 'flutter_translate_kit');
          },
        );
      }
    } finally {
      _languageChangeCompleter = null;
      if (!_disposed) _languageChangingSubject.add(false);
    }
  }

  /// Convenience: set language by BCP-47 code string (e.g. 'hi', 'ar', 'fr')
  Future<void> setLanguageByCode(String code) async {
    final lang = KitLanguages.fromCode(code);
    if (lang == null) {
      log('[TranslateKit] Unknown language code: $code', name: 'flutter_translate_kit');
      return;
    }
    await setLanguage(lang);
  }

  // ── Translation ────────────────────────────────────────────────────────────

  /// Translate a single string.
  /// Returns original text if source == target or on error.
  ///
  /// Results are cached in Hive — same string is never translated twice.
  Future<String> translate(String text) async {
    if (!_initialized || _disposed) return text;
    if (text.trim().isEmpty) return text;
    if (_sourceLanguage == _targetLanguage) return text;

    _pendingTranslations++;
    try {
      // Check cache first (safe, no native calls)
      final cacheKey = '${_targetLanguage.bcpCode}::$text';
      final cached = _cacheBox.get(cacheKey);
      if (cached != null) return cached;

      final translator = _translator;
      if (translator == null) return text;

      try {
        final translated = await translator.translateText(text);
        if (!_disposed) await _cacheBox.put(cacheKey, translated);
        return translated;
      } catch (e, stack) {
        log('[TranslateKit] Translation error (returning original): $e', name: 'flutter_translate_kit');
        log('[TranslateKit] $stack', name: 'flutter_translate_kit');
        return text;
      }
    } finally {
      _pendingTranslations--;
      if (_pendingTranslations == 0 && false == _languageChangeCompleter?.isCompleted) {
        _languageChangeCompleter?.complete();
      }
    }
  }

  /// Translate multiple strings at once (batch).
  /// More efficient than calling translate() in a loop.
  Future<List<String>> translateBatch(List<String> texts) async {
    return Future.wait(texts.map((t) => translate(t)));
  }

  // ── Model Management ───────────────────────────────────────────────────────

  /// Check if a language model is already downloaded on device.
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    final manager = OnDeviceTranslatorModelManager();
    return manager.isModelDownloaded(language.bcpCode);
  }

  /// Pre-download a language model.
  /// Useful to download models on Wi-Fi before the user needs them.
  Future<void> downloadModel(
      TranslateLanguage language, {
        void Function(double progress)? onProgress,
      }) async {
    final manager = OnDeviceTranslatorModelManager();
    final isDownloaded = await manager.isModelDownloaded(language.bcpCode);
    if (isDownloaded) {
      onProgress?.call(1.0);
      return;
    }

    log('[TranslateKit] Downloading model: ${language.bcpCode}', name: 'flutter_translate_kit');
    onProgress?.call(0.0);
    await manager.downloadModel(language.bcpCode, isWifiRequired: false);
    onProgress?.call(1.0);
    log('[TranslateKit] Model downloaded: ${language.bcpCode}', name: 'flutter_translate_kit');
  }

  /// Delete a downloaded model to free device storage.
  Future<void> deleteModel(TranslateLanguage language) async {
    final manager = OnDeviceTranslatorModelManager();
    await manager.deleteModel(language.bcpCode);
  }

  // ── Cache Management ───────────────────────────────────────────────────────

  /// Clear the translation cache.
  Future<void> clearCache() async {
    await _cacheBox.clear();
    log('[TranslateKit] Cache cleared', name: 'flutter_translate_kit');
  }

  /// Get cache size (number of cached translations)
  int get cacheSize => _cacheBox.length;

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _initTranslator() async {
    if (_sourceLanguage == _targetLanguage) return;

    _translator = OnDeviceTranslator(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    if (false == _languageChangeCompleter?.isCompleted) {
      _languageChangeCompleter?.complete();
    }
    _languageChangeCompleter = null;
    _languageChangingSubject.add(false);
    await _translator?.close();
    _translator = null;
    await _languageSubject.close();
    await _languageChangingSubject.close();
  }
}