import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../core/translation_service.dart';
import '../core/supported_languages.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// KitLanguageSwitcher
///
/// A ready-made dropdown widget to let users switch app language.
///
/// Usage:
///   KitLanguageSwitcher(
///     languages: [
///       TranslateLanguage.english,
///       TranslateLanguage.hindi,
///       TranslateLanguage.arabic,
///     ],
///   )
/// ─────────────────────────────────────────────────────────────────────────────
class KitLanguageSwitcher extends StatefulWidget {
  /// Languages to show in the dropdown
  final List<TranslateLanguage> languages;

  /// Optional custom decoration
  final InputDecoration? decoration;

  /// Called after language is changed
  final void Function(TranslateLanguage)? onChanged;

  const KitLanguageSwitcher({
    super.key,
    required this.languages,
    this.decoration,
    this.onChanged,
  });

  @override
  State<KitLanguageSwitcher> createState() => _KitLanguageSwitcherState();
}

class _KitLanguageSwitcherState extends State<KitLanguageSwitcher> {
  late TranslateLanguage _selected;
  TranslateLanguage? _downloadingLanguage;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _selected = TranslationService.instance.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButtonFormField<TranslateLanguage>(
      value: widget.languages.contains(_selected) ? _selected : widget.languages.first,
      decoration: widget.decoration ??
          const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
      items: widget.languages.map((lang) {
        return DropdownMenuItem(
          value: lang,
          child: Text(KitLanguages.getDisplayName(lang)),
        );
      }).toList(),
      onChanged: (lang) async {
        if (lang == null) return;
        setState(() => _selected = lang);
        final service = TranslationService.instance;

        // If the model for this language isn't downloaded yet, download it first
        final isDownloaded = await service.isModelDownloaded(lang);
        if (!isDownloaded) {
          if (mounted) {
            setState(() {
              _downloadingLanguage = lang;
              _downloadProgress = 0.0;
            });
          }

          await service.downloadModel(
            lang,
            onProgress: (p) {
              if (mounted) {
                setState(() {
                  _downloadProgress = p;
                });
              }
            },
          );
        }

        await service.setLanguage(lang);

        if (mounted) {
          setState(() {
            _downloadingLanguage = null;
            _downloadProgress = 0.0;
          });
        }

        widget.onChanged?.call(lang);
      },
    );

    // If we're downloading a model for the selected language, show inline progress UI
    if (_downloadingLanguage != null && _downloadingLanguage == _selected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dropdown,
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _downloadProgress > 0.0 && _downloadProgress < 1.0 ? _downloadProgress : null,
          ),
          const SizedBox(height: 4),
          Text(
            'Preparing ${KitLanguages.getDisplayName(_downloadingLanguage!)}...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return dropdown;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// KitModelDownloadButton
///
/// A button that shows download progress for a language model.
/// Use this to pre-download models on Wi-Fi.
///
/// Usage:
///   KitModelDownloadButton(language: TranslateLanguage.hindi)
/// ─────────────────────────────────────────────────────────────────────────────
class KitModelDownloadButton extends StatefulWidget {
  final TranslateLanguage language;
  final VoidCallback? onDownloaded;

  const KitModelDownloadButton({
    super.key,
    required this.language,
    this.onDownloaded,
  });

  @override
  State<KitModelDownloadButton> createState() => _KitModelDownloadButtonState();
}

class _KitModelDownloadButtonState extends State<KitModelDownloadButton> {
  bool _downloading = false;
  bool _downloaded = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkDownloaded();
  }

  Future<void> _checkDownloaded() async {
    final downloaded =
    await TranslationService.instance.isModelDownloaded(widget.language);
    if (mounted) setState(() => _downloaded = downloaded);
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0.0;
    });
    await TranslationService.instance.downloadModel(
      widget.language,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    if (mounted) {
      setState(() {
        _downloading = false;
        _downloaded = true;
      });
      widget.onDownloaded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_downloaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            '${KitLanguages.getDisplayName(widget.language)} ready',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      );
    }

    if (_downloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(value: _progress, strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Downloading ${KitLanguages.getDisplayName(widget.language)}...'),
        ],
      );
    }

    return TextButton.icon(
      onPressed: _download,
      icon: const Icon(Icons.download, size: 16),
      label: Text('Download ${KitLanguages.getDisplayName(widget.language)}'),
    );
  }
}