// Groups converted games into one or more PGN files and packs them into a
// single ZIP archive.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../cbh/cbh_database.dart';

/// Builds ZIP bytes from [games].
///
/// If [gamesPerFile] is null, every game gets its own PGN file. Otherwise
/// games are grouped into files of at most [gamesPerFile] games each.
Uint8List buildPgnZip(
  List<ConvertedGame> games, {
  required int? gamesPerFile,
  String baseName = 'games',
}) {
  final archive = Archive();

  if (gamesPerFile == null) {
    for (final game in games) {
      final name = '${baseName}_${game.recordIndex.toString().padLeft(6, '0')}.pgn';
      _addPgnFile(archive, name, game.pgnText);
    }
  } else {
    for (var start = 0; start < games.length; start += gamesPerFile) {
      final end =
          (start + gamesPerFile) < games.length ? start + gamesPerFile : games.length;
      final batch = games.sublist(start, end);
      final text = batch.map((g) => g.pgnText).join();
      final batchNumber = (start ~/ gamesPerFile) + 1;
      final name = '${baseName}_batch_${batchNumber.toString().padLeft(4, '0')}.pgn';
      _addPgnFile(archive, name, text);
    }
  }

  final zipBytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipBytes);
}

void _addPgnFile(Archive archive, String name, String content) {
  final data = utf8.encode(content);
  archive.addFile(ArchiveFile(name, data.length, data));
}
