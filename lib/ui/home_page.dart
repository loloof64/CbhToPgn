import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../cbh/cbh_database.dart';
import '../export/pgn_zip_export.dart';

const List<String> _requiredExtensions = ['cbh', 'cbg', 'cbp', 'cbt'];
const String _optionalExtension = 'cba';

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
  final List<String> issueLines;

  _ConversionOutput({
    required this.zipBytes,
    required this.gameCount,
    required this.convertedCount,
    required this.issueLines,
  });
}

String _issueLabel(IssueKind kind) {
  switch (kind) {
    case IssueKind.notMarkedAsGame:
      return "n'est pas une partie";
    case IssueKind.markedAsDeleted:
      return 'marquée supprimée';
    case IssueKind.notEncoded:
      return 'format non pris en charge (non encodé)';
    case IssueKind.chess960:
      return 'Chess960, non pris en charge';
    case IssueKind.specialEncoding:
      return 'encodage spécial non pris en charge';
    case IssueKind.decodeError:
      return 'erreur de décodage';
  }
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
  final issueLines = result.issues
      .map((i) {
        final label = _issueLabel(i.kind);
        final detail = i.detail != null ? ' (${i.detail})' : '';
        return 'Partie #${i.recordIndex} : $label$detail';
      })
      .toList();
  return _ConversionOutput(
    zipBytes: zipBytes,
    gameCount: db.gameCount,
    convertedCount: result.games.length,
    issueLines: issueLines,
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

  Future<void> _pickFiles() async {
    setState(() {
      _isPicking = true;
      _selectionError = null;
      _output = null;
      _conversionError = null;
    });
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [..._requiredExtensions, _optionalExtension],
        dialogTitle: 'Sélectionnez les fichiers .cbh, .cbg, .cbp, .cbt (et .cba si besoin)',
      );
      if (files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      final newPicked = <String, PlatformFile>{};
      final newBytes = <String, Uint8List>{};
      for (final file in files) {
        final ext = file.extension?.toLowerCase();
        if (ext == null) continue;
        if (ext != _optionalExtension && !_requiredExtensions.contains(ext)) continue;
        newPicked[ext] = file;
        newBytes[ext] = await file.readAsBytes();
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
            : "Fichier(s) manquant(s) : ${missing.map((e) => '.$e').join(', ')}";
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
        _selectionError = 'Erreur pendant la sélection des fichiers : $e';
      });
    }
  }

  Future<void> _convert() async {
    if (!_hasRequiredFiles) return;
    int? gamesPerFile;
    if (_exportMode == _ExportMode.batched) {
      gamesPerFile = int.tryParse(_batchSizeController.text.trim());
      if (gamesPerFile == null || gamesPerFile < 1) {
        setState(() => _conversionError = "Taille de lot invalide.");
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
        _conversionError = 'Erreur pendant la conversion : $e';
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
        SnackBar(content: Text("Erreur pendant l'enregistrement : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CBH → PGN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Fichiers de la base', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez ensemble les fichiers .cbh, .cbg, .cbp et .cbt de la base '
                '(et .cba si vous voulez les commentaires/annotations).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isPicking ? null : _pickFiles,
                icon: const Icon(Icons.folder_open),
                label: const Text('Sélectionner les fichiers de la base'),
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
                Text('$_detectedGameCount partie(s) détectée(s) dans l\'index.'),
              ],
              const Divider(height: 32),
              Text("2. Options d'export", style: Theme.of(context).textTheme.titleMedium),
              RadioGroup<_ExportMode>(
                groupValue: _exportMode,
                onChanged: (v) => setState(() => _exportMode = v!),
                child: Column(
                  children: [
                    const RadioListTile<_ExportMode>(
                      value: _ExportMode.perGame,
                      title: Text('Un fichier PGN par partie'),
                      dense: true,
                    ),
                    RadioListTile<_ExportMode>(
                      value: _ExportMode.batched,
                      title: Row(
                        children: [
                          const Text('Regrouper par lots de '),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _batchSizeController,
                              enabled: _exportMode == _ExportMode.batched,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true),
                            ),
                          ),
                          const Text(' parties'),
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
                title: const Text('Inclure les variations'),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_fileBytes.containsKey(_optionalExtension))
                CheckboxListTile(
                  value: _includeAnnotations,
                  onChanged: (v) => setState(() => _includeAnnotations = v ?? true),
                  title: const Text('Inclure commentaires et annotations (expérimental)'),
                  subtitle: const Text(
                    "Basé sur une rétro-ingénierie non vérifiée du format .cba : "
                    "à valider sur votre base, peut être incomplet ou absent.",
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const Divider(height: 32),
              Text('3. Conversion', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: (_hasRequiredFiles && !_isConverting) ? _convert : null,
                icon: const Icon(Icons.transform),
                label: const Text('Convertir'),
              ),
              if (_isConverting) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Conversion en cours...'),
              ],
              if (_conversionError != null) ...[
                const SizedBox(height: 8),
                Text(_conversionError!, style: const TextStyle(color: Colors.red)),
              ],
              if (_output case final output?) ...[
                const SizedBox(height: 16),
                Text(
                  '${output.convertedCount} partie(s) convertie(s) sur ${output.gameCount}, '
                  '${output.issueLines.length} ignorée(s)/en erreur.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (output.issueLines.isNotEmpty)
                  ExpansionTile(
                    title: Text('Détail (${output.issueLines.length})'),
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final line in output.issueLines)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                child: Text(line, style: Theme.of(context).textTheme.bodySmall),
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
                  label: const Text('Enregistrer le ZIP'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
