// Renders a decoded game (headers + GameNode tree) as PGN text, including
// nested variations, comments and NAG suffixes.

import '../cbh/game_tree.dart';

class PgnHeaders {
  final String event;
  final String site;
  final String date;
  final String round;
  final String white;
  final String black;
  final String result;
  final int? whiteElo;
  final int? blackElo;

  const PgnHeaders({
    required this.event,
    required this.site,
    required this.date,
    required this.round,
    required this.white,
    required this.black,
    required this.result,
    this.whiteElo,
    this.blackElo,
  });
}

String _escapeTag(String value) => value.replaceAll('\\', r'\\').replaceAll('"', r'\"');

String _escapeComment(String value) =>
    value.replaceAll('{', '(').replaceAll('}', ')').replaceAll(RegExp(r'\s+'), ' ').trim();

void _maybeWriteMoveNumber(StringBuffer buf, String parentFen, bool forced) {
  final fields = parentFen.split(' ');
  final sideToMove = fields.length > 1 ? fields[1] : 'w';
  final fullmove = fields.length > 5 ? fields[5] : '1';
  if (sideToMove == 'w') {
    buf.write('$fullmove. ');
  } else if (forced) {
    buf.write('$fullmove... ');
  }
}

void _writeMoveToken(StringBuffer buf, GameNode node) {
  final before = node.commentBefore;
  if (before != null && before.isNotEmpty) {
    buf.write('{${_escapeComment(before)}} ');
  }
  buf.write(node.san ?? '');
  final nag = node.nagSuffix;
  if (nag != null) buf.write(nag);
  buf.write(' ');
  final after = node.commentAfter;
  if (after != null && after.isNotEmpty) {
    buf.write('{${_escapeComment(after)}} ');
  }
}

/// Renders the continuation starting at [node]: `node.variations[0]` inline,
/// any further entries in `node.variations` as parenthesized side lines,
/// recursing depth-first so nested variations render correctly.
void _renderFrom(StringBuffer buf, GameNode node, {required bool forceNumber}) {
  var current = node;
  var needNumber = forceNumber;
  while (current.variations.isNotEmpty) {
    final mainChild = current.variations[0];
    _maybeWriteMoveNumber(buf, current.fen, needNumber);
    _writeMoveToken(buf, mainChild);
    needNumber = false;

    for (var i = 1; i < current.variations.length; i++) {
      final sideChild = current.variations[i];
      buf.write('(');
      _maybeWriteMoveNumber(buf, current.fen, true);
      _writeMoveToken(buf, sideChild);
      _renderFrom(buf, sideChild, forceNumber: false);
      buf.write(') ');
      needNumber = true;
    }

    current = mainChild;
  }
}

/// Renders a single game (headers + movetext) as PGN text, terminated with
/// a blank line as PGN convention requires between games in the same file.
String writeSingleGamePgn(PgnHeaders headers, GameNode root) {
  final buf = StringBuffer();
  buf.writeln('[Event "${_escapeTag(headers.event)}"]');
  buf.writeln('[Site "${_escapeTag(headers.site)}"]');
  buf.writeln('[Date "${_escapeTag(headers.date)}"]');
  buf.writeln('[Round "${_escapeTag(headers.round)}"]');
  buf.writeln('[White "${_escapeTag(headers.white)}"]');
  buf.writeln('[Black "${_escapeTag(headers.black)}"]');
  buf.writeln('[Result "${_escapeTag(headers.result)}"]');
  if (headers.whiteElo != null && headers.whiteElo != 0) {
    buf.writeln('[WhiteElo "${headers.whiteElo}"]');
  }
  if (headers.blackElo != null && headers.blackElo != 0) {
    buf.writeln('[BlackElo "${headers.blackElo}"]');
  }
  buf.writeln();

  final movetext = StringBuffer();
  _renderFrom(movetext, root, forceNumber: true);
  movetext.write(headers.result);
  buf.writeln(movetext.toString().trim());
  buf.writeln();
  return buf.toString();
}
