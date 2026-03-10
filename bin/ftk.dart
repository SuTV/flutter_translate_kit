#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// ─────────────────────────────────────────────────────────────────────────────
/// flutter_translate_kit CLI
///
/// Activate globally:
///   dart pub global activate flutter_translate_kit
///
/// Commands:
///   ftk wrap              — Wrap all Text() with KitText() in lib/
///   ftk wrap --dry-run    — Preview changes without modifying files
///   ftk restore           — Undo all changes (restores .bak files)
///   ftk stats             — Show translation stats for your project
/// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:path/path.dart' as p;

// ── Config ────────────────────────────────────────────────────────────────────
const String libDir = 'lib';
const bool createBackups = true;
const String importLine =
    "import 'package:flutter_translate_kit/flutter_translate_kit.dart';";

const List<String> skipFilePatterns = [
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '_test.dart',
  'generated/',
  'l10n/',
  '.mocks.dart',
];

const List<String> skipContentPatterns = [
  'AppConstants.',
  'ApiConstant.',
  'Routes.',
  'AppRoutes.',
  'Strings.',
  'Keys.',
];

// ── Entry point ───────────────────────────────────────────────────────────────
void main(List<String> args) {
  final command = args.isNotEmpty ? args[0] : 'help';
  final isDryRun = args.contains('--dry-run');

  printBanner();

  switch (command) {
    case 'wrap':
      runWrap(isDryRun: isDryRun);
    case 'restore':
      runRestore();
    case 'stats':
      runStats();
    default:
      printHelp();
  }
}

// ── WRAP command ──────────────────────────────────────────────────────────────
void runWrap({bool isDryRun = false}) {
  print('Mode : ${isDryRun ? "DRY RUN (no files changed)" : "LIVE (files will be modified)"}');
  print('Dir  : $libDir\n');

  final dir = Directory(libDir);
  if (!dir.existsSync()) {
    print('❌ "$libDir" not found. Run from your Flutter project root.');
    exit(1);
  }

  final dartFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !skipFilePatterns.any((pat) => f.path.contains(pat)))
      .toList();

  print('📂 Found ${dartFiles.length} dart files...\n');

  int totalFiles = 0, modifiedFiles = 0, totalWrapped = 0;
  final report = <String>[];

  for (final file in dartFiles) {
    totalFiles++;
    final original = file.readAsStringSync();

    if (!original.contains('Text(')) continue;

    final (newContent, count) = wrapTextWidgets(original);
    if (count == 0) continue;

    final withImport = ensureImport(newContent);
    modifiedFiles++;
    totalWrapped += count;

    final rel = p.relative(file.path, from: libDir);
    report.add('[$count] $rel');
    print('  ✅ $rel → $count Text() → KitText()');

    if (!isDryRun) {
      if (createBackups) {
        File('${file.path}.bak').writeAsStringSync(original);
      }
      file.writeAsStringSync(withImport);
    }
  }

  printSummary(totalFiles, modifiedFiles, totalWrapped, isDryRun);
}

// ── RESTORE command ───────────────────────────────────────────────────────────
void runRestore() {
  print('♻️  Restoring from backups...\n');
  int count = 0;

  for (final bak in Directory(libDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.bak'))) {
    final original = bak.path.replaceAll('.bak', '');
    File(original).writeAsStringSync(bak.readAsStringSync());
    bak.deleteSync();
    print('  ♻️  Restored: $original');
    count++;
  }

  print('\n✅ Restored $count files.');
}

// ── STATS command ─────────────────────────────────────────────────────────────
void runStats() {
  final dir = Directory(libDir);
  if (!dir.existsSync()) {
    print('❌ "$libDir" not found.');
    exit(1);
  }

  int totalText = 0, totalKitText = 0, totalFiles = 0;

  for (final file in dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !skipFilePatterns.any((pat) => f.path.contains(pat)))) {
    final content = file.readAsStringSync();
    final textCount = RegExp(r'(?<![a-zA-Z_])Text\(').allMatches(content).length;
    final kitCount = 'KitText('.allMatches(content).length;
    if (textCount > 0 || kitCount > 0) {
      totalFiles++;
      totalText += textCount;
      totalKitText += kitCount;
    }
  }

  print('📊 Project Translation Stats\n');
  print('  Files with Text()   : $totalFiles');
  print('  Plain Text()        : $totalText  ← not yet translated');
  print('  KitText()           : $totalKitText  ← translated ✅');

  final total = totalText + totalKitText;
  if (total > 0) {
    final pct = ((totalKitText / total) * 100).toStringAsFixed(1);
    print('\n  Coverage: $pct%');
  }
}

// ── Wrap logic ────────────────────────────────────────────────────────────────
(String, int) wrapTextWidgets(String content) {
  final buffer = StringBuffer();
  int i = 0;
  int wrapped = 0;

  while (i < content.length) {
    final idx = content.indexOf('Text(', i);
    if (idx == -1) {
      buffer.write(content.substring(i));
      break;
    }

    buffer.write(content.substring(i, idx));

    // Skip SomeText(, RichText(, SelectableText(
    final charBefore = idx > 0 ? content[idx - 1] : ' ';
    if (RegExp(r'[a-zA-Z_]').hasMatch(charBefore)) {
      buffer.write('Text(');
      i = idx + 5;
      continue;
    }

    final widget = extractWidget(content, idx);
    if (widget == null) {
      buffer.write('Text(');
      i = idx + 5;
      continue;
    }

    // Skip constants
    if (skipContentPatterns.any((p) => widget.contains(p))) {
      buffer.write(widget);
      i = idx + widget.length;
      continue;
    }

    // Skip empty Text('')
    if (RegExp(r'''Text\(\s*['"]["']''').hasMatch(widget)) {
      buffer.write(widget);
      i = idx + widget.length;
      continue;
    }

    // Skip already wrapped
    final preCtx = content.substring((idx - 15).clamp(0, content.length), idx);
    if (preCtx.contains('KitText(') || preCtx.contains('child: Text(')) {
      buffer.write(widget);
      i = idx + widget.length;
      continue;
    }

    buffer.write(widget.replaceFirst('Text(', 'KitText('));
    i = idx + widget.length;
    wrapped++;
  }

  return (buffer.toString(), wrapped);
}

String? extractWidget(String content, int start) {
  int i = start;
  while (i < content.length && content[i] != '(') i++;
  if (i >= content.length) return null;
  int depth = 0;
  final s = start;
  while (i < content.length) {
    if (content[i] == '(') depth++;
    if (content[i] == ')') {
      depth--;
      if (depth == 0) return content.substring(s, i + 1);
    }
    i++;
  }
  return null;
}

String ensureImport(String content) {
  if (content.contains(importLine)) return content;
  final last =
      RegExp(r'^import .+;', multiLine: true).allMatches(content).lastOrNull;
  if (last != null) {
    return content.substring(0, last.end) +
        '\n$importLine' +
        content.substring(last.end);
  }
  return '$importLine\n\n$content';
}

// ── Print helpers ─────────────────────────────────────────────────────────────
void printBanner() {
  print('');
  print('╔══════════════════════════════════════════════════╗');
  print('║         flutter_translate_kit  CLI  ftk          ║');
  print('╚══════════════════════════════════════════════════╝');
  print('');
}

void printHelp() {
  print('Commands:');
  print('  ftk wrap              Wrap Text() → KitText() in lib/');
  print('  ftk wrap --dry-run    Preview without changing files');
  print('  ftk restore           Undo all changes from backups');
  print('  ftk stats             Show translation coverage stats');
}

void printSummary(int total, int modified, int wrapped, bool isDryRun) {
  print('');
  print('╔══════════════════════════════════════════════════╗');
  print('║  Files scanned  : $total');
  print('║  Files modified : $modified');
  print('║  Text() wrapped : $wrapped');
  print('╚══════════════════════════════════════════════════╝');
  if (isDryRun) {
    print('\n⚠️  DRY RUN — no files were changed.\n');
  } else {
    print('\n✅ Done! Run: flutter pub get && flutter run\n');
  }
}
