// Orchestrates the whole conversion: iterates every .cbh record, decodes
// the corresponding game from .cbg, resolves player/tournament names, and
// produces PGN text per game. Mirrors the per-record loop of the reference
// cbh2pgn.py script, including which records get silently skipped.

import 'dart:typed_data';

import '../pgn/pgn_writer.dart';
import 'cba_annotations.dart';
import 'cbg_game_decoder.dart';
import 'cbh_header.dart';
import 'cbp_player.dart';
import 'cbt_tournament.dart';
import 'game_tree.dart';

enum IssueKind {
  notMarkedAsGame,
  markedAsDeleted,
  notEncoded,
  chess960,
  specialEncoding,
  decodeError,
}

class ConversionIssue {
  final int recordIndex;
  final IssueKind kind;
  final String? detail;
  ConversionIssue(this.recordIndex, this.kind, [this.detail]);
}

class ConvertedGame {
  final int recordIndex;
  final String pgnText;
  final String? decodeError;
  ConvertedGame({required this.recordIndex, required this.pgnText, this.decodeError});
}

class ConversionResult {
  final List<ConvertedGame> games;
  final List<ConversionIssue> issues;
  ConversionResult({required this.games, required this.issues});
}

class CbhDatabase {
  final Uint8List cbh;
  final Uint8List cbg;
  final Uint8List cbp;
  final Uint8List cbt;
  final Uint8List? cba;

  CbhDatabase({
    required this.cbh,
    required this.cbg,
    required this.cbp,
    required this.cbt,
    this.cba,
  });

  /// Number of game slots in the index (record 0 is a dummy/header slot,
  /// exactly like the reference implementation's `range(1, nr_records)`).
  int get gameCount {
    final total = cbh.length ~/ cbhRecordSize;
    return total > 0 ? total - 1 : 0;
  }

  ConversionResult convertAll({
    bool includeVariations = true,
    bool includeAnnotations = true,
  }) {
    final annotationsByGame = (includeAnnotations && cba != null)
        ? parseCbaFile(cba!)
        : const <int, List<CbaAnnotation>>{};

    final games = <ConvertedGame>[];
    final issues = <ConversionIssue>[];
    final nrRecords = cbh.length ~/ cbhRecordSize;

    for (var i = 1; i < nrRecords; i++) {
      try {
        final record = CbhRecord(cbh.sublist(i * cbhRecordSize, (i + 1) * cbhRecordSize));
        if (!record.isGame) {
          issues.add(ConversionIssue(i, IssueKind.notMarkedAsGame));
          continue;
        }
        if (record.isMarkedAsDeleted) {
          issues.add(ConversionIssue(i, IssueKind.markedAsDeleted));
          continue;
        }

        final gameOffset = record.gameOffset;
        final info = getInfoGameLen(cbg, gameOffset);
        if (info.notEncoded) {
          issues.add(ConversionIssue(i, IssueKind.notEncoded));
          continue;
        }
        if (info.is960) {
          issues.add(ConversionIssue(i, IssueKind.chess960));
          continue;
        }
        if (info.specialEncoding) {
          issues.add(ConversionIssue(i, IssueKind.specialEncoding));
          continue;
        }

        final DecodedGame decoded;
        if (info.notInitial) {
          final start = decodeStartPosition(cbg, gameOffset);
          final moveBytes = cbg.sublist(gameOffset + 4 + 28, gameOffset + info.gameLen);
          decoded = decodeGame(moveBytes, start.position, start.pieceLists, fen: start.fen);
        } else {
          final setup = standardStartSetup();
          final moveBytes = cbg.sublist(gameOffset + 4, gameOffset + info.gameLen);
          decoded = decodeGame(moveBytes, setup.position, setup.pieceLists);
        }

        if (includeAnnotations) {
          final gameAnnotations = annotationsByGame[i];
          if (gameAnnotations != null) {
            for (final a in gameAnnotations) {
              final node = decoded.mainlinePlyNodes[a.plyPosition];
              if (node == null) continue;
              if (a.nagSuffix != null) node.nagSuffix = a.nagSuffix;
              if (a.textBefore != null) node.commentBefore = a.textBefore;
              if (a.textAfter != null) node.commentAfter = a.textAfter;
            }
          }
        }

        final root = includeVariations ? decoded.root : _pruneToMainline(decoded.root);

        final whiteName = getPlayerName(cbp, record.whitePlayerOffset);
        final blackName = getPlayerName(cbp, record.blackPlayerOffset);
        final (event, site) = getEventSite(cbt, record.tournamentOffset);
        final (whiteElo, blackElo) = record.ratings;
        final round = record.subround != 0
            ? '${record.round}(${record.subround})'
            : '${record.round}';

        final headers = PgnHeaders(
          event: event.isEmpty ? '?' : event,
          site: site.isEmpty ? '?' : site,
          date: record.pgnDate,
          round: round,
          white: whiteName,
          black: blackName,
          result: record.result,
          whiteElo: whiteElo,
          blackElo: blackElo,
        );

        final pgnText = writeSingleGamePgn(headers, root);
        games.add(ConvertedGame(recordIndex: i, pgnText: pgnText, decodeError: decoded.error));
        if (decoded.error != null) {
          issues.add(ConversionIssue(i, IssueKind.decodeError, decoded.error));
        }
      } catch (e) {
        issues.add(ConversionIssue(i, IssueKind.decodeError, e.toString()));
      }
    }

    return ConversionResult(games: games, issues: issues);
  }
}

GameNode _pruneToMainline(GameNode node) {
  final copy = GameNode(san: node.san, fen: node.fen)
    ..commentBefore = node.commentBefore
    ..commentAfter = node.commentAfter
    ..nagSuffix = node.nagSuffix;
  if (node.variations.isNotEmpty) {
    copy.variations.add(_pruneToMainline(node.variations[0]));
  }
  return copy;
}
