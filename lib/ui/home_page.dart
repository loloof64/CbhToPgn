import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../cbh/cbh_database.dart';
import '../cbh/cbv_archive.dart';
import '../export/pgn_zip_export.dart';
import '../l10n/generated/app_localizations.dart';

const List<String> _requiredExtensions = ['cbh', 'cbg', 'cbp', 'cbt'];
const String _optionalExtension = 'cba';
const String _archiveExtension = 'cbv';

class _ConversionParams {
  final Uint8List cbh;
  final Uint8List cbg;
  final Uint8List cbp;
  final Uint8List cbt;
  final Uint8List? cba;
  final bool includeVariations;
  final bool includeAnnotations;
  final int? gamesPerFile;

  _ConversionParams({
    required this.cbh,
    required this.cbg,
    required this.cbp,
    required this.cbt,
    required this.cba,
    required this.includeVariations,
    required this.includeAnnotations,
    required this.gamesPerFile,
  });
}

class _ConversionOutput {
  final Uint8List zipBytes;
  final int gameCount;
  final int convertedCount;
  final List<ConversionIssue> issues;

  _ConversionOutput({
    required this.zipBytes,
    required this.gameCount,
    required this.convertedCount,
    required this.issues,
  });
}

String _issueLabel(AppLocalizations l10n, IssueKind kind) {
  switch (kind) {
    case IssueKind.notMarkedAsGame:
      return l10n.issueNotMarkedAsGame;
    case IssueKind.markedAsDeleted:
      return l10n.issueMarkedAsDeleted;
    case IssueKind.notEncoded:
      return l10n.issueNotEncoded;
    case IssueKind.chess960:
      return l10n.issueChess960;
    case IssueKind.specialEncoding:
      return l10n.issueSpecialEncoding;
    case IssueKind.decodeError:
      return l10n.issueDecodeError;
  }
}

String _issueLine(AppLocalizations l10n, ConversionIssue issue) {
  final label = _issueLabel(l10n, issue.kind);
  final labelWithDetail = issue.detail != null ? '$label (${issue.detail})' : label;
  return l10n.issueLine(issue.recordIndex, labelWithDetail);
}

Future<_ConversionOutput> _runConversion(_ConversionParams params) async {
  final db = CbhDatabase(
    cbh: params.cbh,
    cbg: params.cbg,
    cbp: params.cbp,
    cbt: params.cbt,
    cba: params.cba,
  );
  final result = db.convertAll(
    includeVariations: params.includeVariations,
    includeAnnotations: params.includeAnnotations,
  );
  final zipBytes = buildPgnZip(result.games, gamesPerFile: params.gamesPerFile);
  return _ConversionOutput(
    zipBytes: zipBytes,
    gameCount: db.gameCount,
    convertedCount: result.games.length,
    issues: result.issues,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _ExportMode { perGame, batched }

class _HomePageState extends State<HomePage> {
  final Map<String, PlatformFile> _pickedFiles = {};
  final Map<String, Uint8List> _fileBytes = {};
  String? _selectionError;
  int? _detectedGameCount;

  _ExportMode _exportMode = _ExportMode.batched;
  final _batchSizeController = TextEditingController(text: '200');
  bool _includeVariations = true;
  bool _includeAnnotations = true;

  bool _isPicking = false;
  bool _isConverting = false;
  _ConversionOutput? _output;
  String? _conversionError;

  @override
  void dispose() {
    _batchSizeController.dispose();
    super.dispose();
  }

  bool get _hasRequiredFiles =>
      _requiredExtensions.every((ext) => _fileBytes.containsKey(ext));

  bool get _hasSomethingToReset =>
      _pickedFiles.isNotEmpty ||
      _selectionError != null ||
      _output != null ||
      _conversionError != null;

  void _resetAll() {
    setState(() {
      _pickedFiles.clear();
      _fileBytes.clear();
      _selectionError = null;
      _detectedGameCount = null;
      _output = null;
      _conversionError = null;
      _includeAnnotations = true;
    });
  }

  Future<void> _pickFiles() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isPicking = true;
      _selectionError = null;
      _output = null;
      _conversionError = null;
    });
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [..._requiredExtensions, _optionalExtension, _archiveExtension],
        dialogTitle: l10n.filePickerDialogTitle,
      );
      if (files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      final newPicked = <String, PlatformFile>{};
      final newBytes = <String, Uint8List>{};
      final archiveFile = files.firstWhere(
        (f) => f.extension?.toLowerCase() == _archiveExtension,
        orElse: () => files.first,
      );
      if (archiveFile.extension?.toLowerCase() == _archiveExtension) {
        newPicked[_archiveExtension] = archiveFile;
        final archiveBytes = await archiveFile.readAsBytes();
        final extracted = extractCbvArchive(archiveBytes);
        for (final ext in [..._requiredExtensions, _optionalExtension]) {
          final bytes = extracted[ext];
          if (bytes != null) newBytes[ext] = bytes;
        }
      } else {
        for (final file in files) {
          final ext = file.extension?.toLowerCase();
          if (ext == null) continue;
          if (ext != _optionalExtension && !_requiredExtensions.contains(ext)) continue;
          newPicked[ext] = file;
          newBytes[ext] = await file.readAsBytes();
        }
        await _autoLoadSiblingFiles(newPicked, newBytes);
      }

      final missing = _requiredExtensions.where((ext) => !newBytes.containsKey(ext)).toList();

      setState(() {
        _pickedFiles
          ..clear()
          ..addAll(newPicked);
        _fileBytes
          ..clear()
          ..addAll(newBytes);
        _selectionError = missing.isEmpty
            ? null
            : l10n.missingFilesError(missing.length, missing.map((e) => '.$e').join(', '));
        _detectedGameCount =
            _hasRequiredFiles ? (_fileBytes['cbh']!.length ~/ 46 - 1).clamp(0, 1 << 31) : null;
        if (!_fileBytes.containsKey(_optionalExtension)) {
          _includeAnnotations = false;
        }
        _isPicking = false;
      });
    } catch (e) {
      setState(() {
        _isPicking = false;
        _selectionError = l10n.fileSelectionError('$e');
      });
    }
  }

  /// Fills in any required/optional file not explicitly picked by looking,
  /// next to an already-picked file, for sibling files sharing the same
  /// base name (ChessBase databases always bundle .cbh/.cbg/.cbp/.cbt/.cba
  /// this way), so selecting the .cbh alone is enough on desktop platforms.
  Future<void> _autoLoadSiblingFiles(
    Map<String, PlatformFile> picked,
    Map<String, Uint8List> bytes,
  ) async {
    final reference = picked['cbh'] ?? (picked.isEmpty ? null : picked.values.first);
    final refPath = reference?.path;
    if (refPath == null) return;

    final separatorIndex = refPath.lastIndexOf(RegExp(r'[\\/]'));
    final dir = separatorIndex >= 0 ? refPath.substring(0, separatorIndex + 1) : '';
    final refName = separatorIndex >= 0 ? refPath.substring(separatorIndex + 1) : refPath;
    final dotIndex = refName.lastIndexOf('.');
    final baseName = dotIndex > 0 ? refName.substring(0, dotIndex) : refName;

    for (final ext in [..._requiredExtensions, _optionalExtension]) {
      if (bytes.containsKey(ext)) continue;
      for (final candidateExt in {ext, ext.toUpperCase()}) {
        final candidate = File('$dir$baseName.$candidateExt');
        if (await candidate.exists()) {
          bytes[ext] = await candidate.readAsBytes();
          break;
        }
      }
    }
  }

  Future<void> _convert() async {
    if (!_hasRequiredFiles) return;
    final l10n = AppLocalizations.of(context);
    int? gamesPerFile;
    if (_exportMode == _ExportMode.batched) {
      gamesPerFile = int.tryParse(_batchSizeController.text.trim());
      if (gamesPerFile == null || gamesPerFile < 1) {
        setState(() => _conversionError = l10n.invalidBatchSize);
        return;
      }
    }

    setState(() {
      _isConverting = true;
      _conversionError = null;
      _output = null;
    });

    try {
      final params = _ConversionParams(
        cbh: _fileBytes['cbh']!,
        cbg: _fileBytes['cbg']!,
        cbp: _fileBytes['cbp']!,
        cbt: _fileBytes['cbt']!,
        cba: _fileBytes[_optionalExtension],
        includeVariations: _includeVariations,
        includeAnnotations: _includeAnnotations && _fileBytes.containsKey(_optionalExtension),
        gamesPerFile: gamesPerFile,
      );
      final output = await compute(_runConversion, params);
      setState(() {
        _output = output;
        _isConverting = false;
      });
    } catch (e) {
      setState(() {
        _isConverting = false;
        _conversionError = l10n.conversionError('$e');
      });
    }
  }

  Future<void> _saveZip() async {
    final output = _output;
    if (output == null) return;
    try {
      await FilePicker.saveFile(
        fileName: 'parties_pgn.zip',
        bytes: output.zipBytes,
        mimeType: 'application/zip',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveError('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: _hasSomethingToReset ? _resetAll : null,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.resetTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sectionFilesTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l10n.filesDescription, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isPicking ? null : _pickFiles,
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.selectFilesButton),
              ),
              const SizedBox(height: 8),
              if (_pickedFiles.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final ext in [..._requiredExtensions, _optionalExtension])
                      Chip(
                        avatar: Icon(
                          _fileBytes.containsKey(ext) ? Icons.check_circle : Icons.cancel,
                          size: 18,
                          color: _fileBytes.containsKey(ext) ? Colors.green : Colors.grey,
                        ),
                        label: Text('.$ext'),
                      ),
                  ],
                ),
              if (_selectionError != null) ...[
                const SizedBox(height: 8),
                Text(_selectionError!, style: const TextStyle(color: Colors.red)),
              ],
              if (_detectedGameCount != null) ...[
                const SizedBox(height: 8),
                Text(l10n.detectedGameCount(_detectedGameCount!)),
              ],
              const Divider(height: 32),
              Text(l10n.sectionOptionsTitle, style: Theme.of(context).textTheme.titleMedium),
              RadioGroup<_ExportMode>(
                groupValue: _exportMode,
                onChanged: (v) => setState(() => _exportMode = v!),
                child: Column(
                  children: [
                    RadioListTile<_ExportMode>(
                      value: _ExportMode.perGame,
                      title: Text(l10n.perGameOption),
                      dense: true,
                    ),
                    RadioListTile<_ExportMode>(
                      value: _ExportMode.batched,
                      title: Row(
                        children: [
                          Text(l10n.batchSizePrefix),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _batchSizeController,
                              enabled: _exportMode == _ExportMode.batched,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                            ),
                          ),
                          Text(l10n.batchSizeSuffix),
                        ],
                      ),
                      dense: true,
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                value: _includeVariations,
                onChanged: (v) => setState(() => _includeVariations = v ?? true),
                title: Text(l10n.includeVariations),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_fileBytes.containsKey(_optionalExtension))
                CheckboxListTile(
                  value: _includeAnnotations,
                  onChanged: (v) => setState(() => _includeAnnotations = v ?? true),
                  title: Text(l10n.includeAnnotations),
                  subtitle: Text(l10n.includeAnnotationsSubtitle),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const Divider(height: 32),
              Text(l10n.sectionConversionTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: (_hasRequiredFiles && !_isConverting) ? _convert : null,
                icon: const Icon(Icons.transform),
                label: Text(l10n.convertButton),
              ),
              if (_isConverting) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(l10n.convertingInProgress),
              ],
              if (_conversionError != null) ...[
                const SizedBox(height: 8),
                Text(_conversionError!, style: const TextStyle(color: Colors.red)),
              ],
              if (_output case final output?) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.conversionSummary(
                    output.convertedCount,
                    output.gameCount,
                    output.issues.length,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (output.issues.isNotEmpty)
                  ExpansionTile(
                    title: Text(l10n.detailsExpansionTitle(output.issues.length)),
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final issue in output.issues)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                child: Text(
                                  _issueLine(l10n, issue),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _saveZip,
                  icon: const Icon(Icons.save_alt),
                  label: Text(l10n.saveZipButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
