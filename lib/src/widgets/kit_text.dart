import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../core/translation_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// KitText
///
/// A drop-in replacement for Flutter's Text widget that auto-translates
/// its content using on-device ML Kit.
///
/// Usage:
///   // Before
///   Text('Welcome to the app')
///
///   // After
///   KitText('Welcome to the app')
///
/// All standard Text properties are supported:
///   KitText(
///     'Hello World',
///     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
///     textAlign: TextAlign.center,
///   )
///
/// Opt out of translation:
///   KitText('API_KEY_123', translate: false)
/// ─────────────────────────────────────────────────────────────────────────────
class KitText extends StatefulWidget {
  final String data;
  final bool translate;

  // Standard Text properties
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const KitText(
      this.data, {
        super.key,
        this.translate = true,
        this.style,
        this.textAlign,
        this.textDirection,
        this.locale,
        this.softWrap,
        this.overflow,
        this.textScaler,
        this.maxLines,
        this.semanticsLabel,
        this.textWidthBasis,
        this.textHeightBehavior,
        this.selectionColor,
      });

  @override
  State<KitText> createState() => _KitTextState();
}

class _KitTextState extends State<KitText> {
  String _displayText = '';
  TranslateLanguage? _lastLanguage;

  @override
  void initState() {
    super.initState();
    _displayText = widget.data;
    _translate();
  }

  @override
  void didUpdateWidget(KitText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _translate();
    }
  }

  Future<void> _translate() async {
    if (!widget.translate) {
      setState(() => _displayText = widget.data);
      return;
    }

    final service = TranslationService.instance;
    if (!service.isInitialized) {
      setState(() => _displayText = widget.data);
      return;
    }

    final translated = await service.translate(widget.data);
    if (mounted) {
      setState(() => _displayText = translated);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to language changes and re-translate
    return StreamBuilder<TranslateLanguage>(
      stream: TranslationService.instance.languageStream,
      builder: (context, snapshot) {
        final currentLang = snapshot.data;
        if (currentLang != null && currentLang != _lastLanguage) {
          _lastLanguage = currentLang;
          // Retranslate when language changes
          WidgetsBinding.instance.addPostFrameCallback((_) => _translate());
        }

        // Auto RTL direction
        final isRTL = TranslationService.instance.isRTL;
        final effectiveDirection =
            widget.textDirection ?? (isRTL ? TextDirection.rtl : TextDirection.ltr);

        return Text(
          _displayText,
          style: widget.style,
          textAlign: widget.textAlign,
          textDirection: effectiveDirection,
          locale: widget.locale,
          softWrap: widget.softWrap,
          overflow: widget.overflow,
          textScaler: widget.textScaler,
          maxLines: widget.maxLines,
          semanticsLabel: widget.semanticsLabel,
          textWidthBasis: widget.textWidthBasis,
          textHeightBehavior: widget.textHeightBehavior,
          selectionColor: widget.selectionColor,
        );
      },
    );
  }
}