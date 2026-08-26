// Tree representation of a decoded game, supporting variations (sidelines)
// and optional comments/NAG annotations.
//
// Convention (mirroring python-chess's GameNode, which the reference
// cbh2pgn implementation relies on): a node's `variations` list holds all
// continuations from that node. `variations[0]` is the direct continuation
// (rendered inline, without parentheses); any further entries are side
// variations (rendered in parentheses).

class GameNode {
  /// SAN of the move that led to this node. Null only for the root node.
  String? san;

  /// FEN of the position *after* this node's move (used to reload the
  /// chess engine when generating SAN for further moves).
  String fen;

  /// Comment attached before this move's SAN (e.g. "before move" .cba entry).
  String? commentBefore;

  /// Comment attached after this move's SAN.
  String? commentAfter;

  /// NAG suffix glyph appended directly to the SAN, e.g. "!", "?", "!!".
  String? nagSuffix;

  final List<GameNode> variations = [];

  GameNode({this.san, required this.fen});

  GameNode addVariation({required String san, required String fen}) {
    final child = GameNode(san: san, fen: fen);
    variations.add(child);
    return child;
  }
}
