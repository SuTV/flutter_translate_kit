import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../core/translation_service.dart';
import '../core/supported_languages.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// KitScope
///
/// Wrap your MaterialApp with KitScope to:
///   • Automatically set locale when language changes
///   • Auto-switch between LTR ↔ RTL layouts
///   • Handle all localization delegates
///
/// Usage in app.dart:
///
///   @override
///   Widget build(BuildContext context) {
///     return KitScope(
///       builder: (locale, delegates) => MaterialApp(
///         locale: locale,
///         localizationsDelegates: delegates,
///         supportedLocales: KitScope.supportedLocales,
///         home: HomeScreen(),
///       ),
///     );
///   }
/// ─────────────────────────────────────────────────────────────────────────────
class KitScope extends StatefulWidget {
  final Widget Function(
      Locale locale,
      List<LocalizationsDelegate> delegates,
      ) builder;

  const KitScope({super.key, required this.builder});

  static const List<LocalizationsDelegate> localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static List<Locale> get supportedLocales =>
      KitLanguages.all.map((l) => Locale(l.bcpCode)).toList();

  @override
  State<KitScope> createState() => _KitScopeState();
}

class _KitScopeState extends State<KitScope> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(TranslationService.instance.currentLanguage.bcpCode);

    TranslationService.instance.languageStream.listen((lang) {
      if (mounted) {
        setState(() => _locale = Locale(lang.bcpCode));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_locale, KitScope.localizationDelegates);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// KitDirectionality
///
/// Wraps a widget tree in automatic LTR/RTL Directionality.
/// Use this inside your Scaffold or root widget if you need
/// manual RTL control beyond what MaterialApp provides.
/// ─────────────────────────────────────────────────────────────────────────────
class KitDirectionality extends StatelessWidget {
  final Widget child;

  const KitDirectionality({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TranslateLanguage>(
      stream: TranslationService.instance.languageStream,
      builder: (context, snapshot) {
        final isRTL = TranslationService.instance.isRTL;
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: child,
        );
      },
    );
  }
}