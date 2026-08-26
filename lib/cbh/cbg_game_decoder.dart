// Decoding of the .cbg move stream. Ported from the reference Python
// implementation (game.py) at https://github.com/asdfjkl/cbh2pgn -
// MIT licensed - and extended to build a full variation tree (the
// reference only ever exports the flattened python-chess tree, which
// happens to support variations already; we build the equivalent
// structure ourselves since Dart has no python-chess).

import 'dart:typed_data';

import 'package:chess/chess.dart' as cjs;

import 'bin_utils.dart';
import 'cb_constants.dart';
import 'game_tree.dart';

const int _maskStartWithInitial = 0x40000000;
const int _maskIsEncoded = 0x80000000;
const int _maskSpecialEncoding = 0x4000000;
const int _maskGameLen = 0x00FFFFFF;
const int _maskIs960 = 0xA000000;

class GameInfo {
  final bool notInitial;
  final bool notEncoded;
  final bool is960;
  final bool specialEncoding;
  final int gameLen;

  GameInfo({
    required this.notInitial,
    required this.notEncoded,
    required this.is960,
    required this.specialEncoding,
    required this.gameLen,
  });
}

GameInfo getInfoGameLen(Uint8List cbg, int offset) {
  final sizeInfo = readUint32BE(cbg, offset);
  return GameInfo(
    notInitial: ((sizeInfo & _maskStartWithInitial) >> 30) == 1,
    notEncoded: ((sizeInfo & _maskIsEncoded) >> 31) == 1,
    is960: (sizeInfo & _maskIs960) != 0,
    specialEncoding: ((sizeInfo & _maskSpecialEncoding) >> 26) == 1,
    gameLen: sizeInfo & _maskGameLen,
  );
}

/// 8x8 board of (pieceType, pieceNr) pairs used purely to interpret the
/// relative move encoding - independent from the `chess` package board,
/// which is kept in sync separately (via FEN) to produce SAN.
class CbPosition {
  final List<List<int>> type;
  final List<List<int?>> nr;

  CbPosition._(this.type, this.nr);

  factory CbPosition.empty() => CbPosition._(
        List.generate(8, (_) => List<int>.filled(8, 0)),
        List.generate(8, (_) => List<int?>.filled(8, null)),
      );

  CbPosition clone() => CbPosition._(
        [for (final row in type) [...row]],
        [for (final row in nr) [...row]],
      );
}

/// piece type (1..12) -> list of up to 8 squares (file, rank), null = unused.
class CbPieceLists {
  final List<List<(int, int)?>> byType;

  CbPieceLists._(this.byType);

  factory CbPieceLists.empty() =>
      CbPieceLists._(List.generate(13, (_) => List<(int, int)?>.filled(8, null)));

  CbPieceLists clone() => CbPieceLists._([for (final l in byType) [...l]]);
}

class _BitReader {
  final Uint8List bytes;
  int bitPos = 0;
  _BitReader(this.bytes);
  int get bitLength => bytes.length * 8;
  int readBit() {
    final byteIdx = bitPos >> 3;
    final bitIdx = 7 - (bitPos & 7);
    final bit = (bytes[byteIdx] >> bitIdx) & 1;
    bitPos++;
    return bit;
  }
}

({CbPosition position, CbPieceLists pieceLists}) decodePieceLocations(
  Uint8List setupBitstream,
) {
  final reader = _BitReader(setupBitstream);
  final position = CbPosition.empty();
  final pieceLists = CbPieceLists.empty();
  int bIdx = 0;

  int nextFreeSlot(int pieceType) {
    final l = pieceLists.byType[pieceType];
    for (var i = 0; i < l.length; i++) {
      if (l[i] == null) return i;
    }
    throw const FormatException('too many pieces of one kind in start setup');
  }

  while (reader.bitPos < reader.bitLength && bIdx < 64) {
    final bit = reader.readBit();
    if (bit == 0) {
      bIdx++;
      continue;
    }
    if (reader.bitLength - reader.bitPos < 4) {
      throw FormatException('Error decoding start position at bit ${reader.bitPos}');
    }
    var code = 1;
    for (var k = 0; k < 4; k++) {
      code = (code << 1) | reader.readBit();
    }
    final file = absToXY[bIdx][0];
    final rank = absToXY[bIdx][1];
    switch (code) {
      case 17: // 10001
        position.type[file][rank] = wKing;
        position.nr[file][rank] = 0;
        pieceLists.byType[wKing][0] = (file, rank);
      case 18: // 10010
        final idx = nextFreeSlot(wQueen);
        position.type[file][rank] = wQueen;
        position.nr[file][rank] = idx;
        pieceLists.byType[wQueen][idx] = (file, rank);
      case 19: // 10011
        final idx = nextFreeSlot(wKnight);
        position.type[file][rank] = wKnight;
        position.nr[file][rank] = idx;
        pieceLists.byType[wKnight][idx] = (file, rank);
      case 20: // 10100
        final idx = nextFreeSlot(wBishop);
        position.type[file][rank] = wBishop;
        position.nr[file][rank] = idx;
        pieceLists.byType[wBishop][idx] = (file, rank);
      case 21: // 10101
        final idx = nextFreeSlot(wRook);
        position.type[file][rank] = wRook;
        position.nr[file][rank] = idx;
        pieceLists.byType[wRook][idx] = (file, rank);
      case 22: // 10110
        final idx = nextFreeSlot(wPawn);
        position.type[file][rank] = wPawn;
        position.nr[file][rank] = idx;
        pieceLists.byType[wPawn][idx] = (file, rank);
      case 25: // 11001
        position.type[file][rank] = bKing;
        position.nr[file][rank] = 0;
        pieceLists.byType[bKing][0] = (file, rank);
      case 26: // 11010
        final idx = nextFreeSlot(bQueen);
        position.type[file][rank] = bQueen;
        position.nr[file][rank] = idx;
        pieceLists.byType[bQueen][idx] = (file, rank);
      case 27: // 11011
        final idx = nextFreeSlot(bKnight);
        position.type[file][rank] = bKnight;
        position.nr[file][rank] = idx;
        pieceLists.byType[bKnight][idx] = (file, rank);
      case 28: // 11100
        final idx = nextFreeSlot(bBishop);
        position.type[file][rank] = bBishop;
        position.nr[file][rank] = idx;
        pieceLists.byType[bBishop][idx] = (file, rank);
      case 29: // 11101
        final idx = nextFreeSlot(bRook);
        position.type[file][rank] = bRook;
        position.nr[file][rank] = idx;
        pieceLists.byType[bRook][idx] = (file, rank);
      case 30: // 11110
        final idx = nextFreeSlot(bPawn);
        position.type[file][rank] = bPawn;
        position.nr[file][rank] = idx;
        pieceLists.byType[bPawn][idx] = (file, rank);
      default:
        throw FormatException('Error parsing position setup, piece code: $code');
    }
    bIdx++;
  }
  return (position: position, pieceLists: pieceLists);
}

String cbPositionToFen(
  CbPosition position, {
  required int epFile,
  required bool isBlacksTurn,
  required bool wLong,
  required bool wShort,
  required bool bLong,
  required bool bShort,
  required int nextMoveNo,
}) {
  final buf = StringBuffer();
  for (var rank = 7; rank >= 0; rank--) {
    var emptyCount = 0;
    for (var file = 0; file < 8; file++) {
      final piece = position.type[file][rank];
      if (piece == 0) {
        emptyCount++;
        continue;
      }
      if (emptyCount > 0) {
        buf.write(emptyCount);
        emptyCount = 0;
      }
      buf.write(_fenLetterFor(piece));
    }
    if (emptyCount > 0) buf.write(emptyCount);
    if (rank > 0) buf.write('/');
  }
  buf.write(isBlacksTurn ? ' b' : ' w');
  if (wLong || wShort || bLong || bShort) {
    buf.write(' ');
    if (wShort) buf.write('K');
    if (wLong) buf.write('Q');
    if (bShort) buf.write('k');
    if (bLong) buf.write('q');
  } else {
    buf.write(' -');
  }
  if (epFile > 0) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    buf.write(' ${files[epFile - 1]}');
    buf.write(isBlacksTurn ? '3 ' : '6 ');
  } else {
    buf.write(' - ');
  }
  buf.write('0 ');
  buf.write(nextMoveNo);
  return buf.toString();
}

String _fenLetterFor(int piece) {
  switch (piece) {
    case wKing:
      return 'K';
    case wQueen:
      return 'Q';
    case wRook:
      return 'R';
    case wBishop:
      return 'B';
    case wKnight:
      return 'N';
    case wPawn:
      return 'P';
    case bKing:
      return 'k';
    case bQueen:
      return 'q';
    case bRook:
      return 'r';
    case bBishop:
      return 'b';
    case bKnight:
      return 'n';
    case bPawn:
      return 'p';
    default:
      throw StateError('unknown piece type $piece');
  }
}

const int _maskEpFile = 0x7;
const int _maskTurn = 0x10;
const int _maskWhiteCastleLong = 1;
const int _maskWhiteCastleShort = 2;
const int _maskBlackCastleLong = 4;
const int _maskBlackCastleShort = 8;

({String fen, CbPosition position, CbPieceLists pieceLists}) decodeStartPosition(
  Uint8List cbg,
  int offset,
) {
  final epFile = cbg[offset + 4 + 1] & _maskEpFile;
  final blackToMove = (cbg[offset + 4 + 1] & _maskTurn) >> 4 == 1;
  final wLong = (cbg[offset + 4 + 2] & _maskWhiteCastleLong) != 0;
  final wShort = (cbg[offset + 4 + 2] & _maskWhiteCastleShort) != 0;
  final bLong = (cbg[offset + 4 + 2] & _maskBlackCastleLong) != 0;
  final bShort = (cbg[offset + 4 + 2] & _maskBlackCastleShort) != 0;
  final nextMoveNo = cbg[offset + 4 + 3];
  final setupBitstream = cbg.sublist(offset + 8, offset + 8 + 24);
  final decoded = decodePieceLocations(setupBitstream);
  final fen = cbPositionToFen(
    decoded.position,
    epFile: epFile,
    isBlacksTurn: blackToMove,
    wLong: wLong,
    wShort: wShort,
    bLong: bLong,
    bShort: bShort,
    nextMoveNo: nextMoveNo,
  );
  return (fen: fen, position: decoded.position, pieceLists: decoded.pieceLists);
}

/// The standard chess starting position, hard-coded exactly like the
/// reference cbh2pgn.py does for games that start from the initial setup
/// (avoids running the bitstream decoder for the common case).
({CbPosition position, CbPieceLists pieceLists}) standardStartSetup() {
  final position = CbPosition.empty();
  final pieceLists = CbPieceLists.empty();

  void place(int file, int rank, int pieceType, int? nr) {
    position.type[file][rank] = pieceType;
    position.nr[file][rank] = nr ?? 0;
    if (nr != null) {
      pieceLists.byType[pieceType][nr] = (file, rank);
    } else {
      pieceLists.byType[pieceType][0] = (file, rank);
    }
  }

  // Rooks, knights, bishops, queen, king - white then black.
  place(0, 0, wRook, 0);
  place(7, 0, wRook, 1);
  place(1, 0, wKnight, 0);
  place(6, 0, wKnight, 1);
  place(2, 0, wBishop, 0);
  place(5, 0, wBishop, 1);
  place(3, 0, wQueen, 0);
  place(4, 0, wKing, null);

  place(0, 7, bRook, 0);
  place(7, 7, bRook, 1);
  place(1, 7, bKnight, 0);
  place(6, 7, bKnight, 1);
  place(2, 7, bBishop, 0);
  place(5, 7, bBishop, 1);
  place(3, 7, bQueen, 0);
  place(4, 7, bKing, null);

  for (var file = 0; file < 8; file++) {
    place(file, 1, wPawn, file);
    place(file, 6, bPawn, file);
  }

  return (position: position, pieceLists: pieceLists);
}

const String standardStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void _decreasePieceNr(
  CbPieceLists pieceLists,
  CbPosition position,
  int targetPieceType,
  int targetNr,
) {
  final l = pieceLists.byType[targetPieceType];
  for (var nr = targetNr; nr < 7; nr++) {
    l[nr] = l[nr + 1];
  }
  l[7] = null;
  for (var x = 0; x < 8; x++) {
    for (var y = 0; y < 8; y++) {
      final p = position.type[x][y];
      final t = position.nr[x][y];
      if (p == targetPieceType && t != null && t > targetNr) {
        position.nr[x][y] = t - 1;
      }
    }
  }
}

bool _isMinorOrMajor(int pieceType) {
  return pieceType != wKing &&
      pieceType != bKing &&
      pieceType != wPawn &&
      pieceType != bPawn &&
      pieceType != 0;
}

/// Applies a decoded one-byte move; returns (from, to) algebraic squares.
(String, String) _applyOneByteMove(
  CbPieceLists pieceLists,
  int pieceType,
  int pieceNr,
  CbPosition position,
  Map<int, List<int>> encMap,
  int tkn, {
  bool pawnFlip = false,
}) {
  final from = pieceLists.byType[pieceType][pieceNr]!;
  final (i, j) = from;
  position.type[i][j] = 0;
  position.nr[i][j] = null;
  var addXY = encMap[tkn]!;
  var addX = addXY[0];
  var addY = addXY[1];
  if (pawnFlip) {
    addX = -addX;
    addY = -addY;
  }
  final i1 = (i + addX) % 8;
  final j1 = (j + addY) % 8;
  final targetType = position.type[i1][j1];
  final targetNr = position.nr[i1][j1];
  if (targetType != 0 && _isMinorOrMajor(targetType) && targetNr != null) {
    _decreasePieceNr(pieceLists, position, targetType, targetNr);
  }
  position.type[i1][j1] = pieceType;
  position.nr[i1][j1] = pieceNr;
  pieceLists.byType[pieceType][pieceNr] = (i1, j1);

  if (pieceType == wKing && tkn == 0x76) {
    // castle short: move the white rook from h1 to f1.
    position.type[7][0] = 0;
    position.nr[7][0] = null;
    final rooks = pieceLists.byType[wRook];
    for (var idx = 0; idx < rooks.length; idx++) {
      if (rooks[idx] == (7, 0)) {
        rooks[idx] = (5, 0);
        position.type[5][0] = wRook;
        position.nr[5][0] = idx;
        break;
      }
    }
  }
  if (pieceType == bKing && tkn == 0x76) {
    position.type[7][7] = 0;
    position.nr[7][7] = null;
    final rooks = pieceLists.byType[bRook];
    for (var idx = 0; idx < rooks.length; idx++) {
      if (rooks[idx] == (7, 7)) {
        rooks[idx] = (5, 7);
        position.type[5][7] = bRook;
        position.nr[5][7] = idx;
        break;
      }
    }
  }
  if (pieceType == wKing && tkn == 0xB5) {
    // castle long: move the white rook from a1 to d1.
    position.type[0][0] = 0;
    position.nr[0][0] = null;
    final rooks = pieceLists.byType[wRook];
    for (var idx = 0; idx < rooks.length; idx++) {
      if (rooks[idx] == (0, 0)) {
        rooks[idx] = (3, 0);
        position.type[3][0] = wRook;
        position.nr[3][0] = idx;
        break;
      }
    }
  }
  if (pieceType == bKing && tkn == 0xB5) {
    position.type[0][7] = 0;
    position.nr[0][7] = null;
    final rooks = pieceLists.byType[bRook];
    for (var idx = 0; idx < rooks.length; idx++) {
      if (rooks[idx] == (0, 7)) {
        rooks[idx] = (3, 7);
        position.type[3][7] = bRook;
        position.nr[3][7] = idx;
        break;
      }
    }
  }
  return (squareName(i, j), squareName(i1, j1));
}

/// Applies a decoded two-byte move (promotions, or 4th+ piece of a kind).
/// Returns (from, to, promotionLetter?).
(String, String, String?) _applyTwoByteMove(
  CbPieceLists pieceLists,
  int i,
  int j,
  int i1,
  int j1,
  CbPosition position,
  int cbPromotionCode,
) {
  final pieceType = position.type[i][j];
  final pieceNr = position.nr[i][j];
  position.type[i][j] = 0;
  position.nr[i][j] = null;

  final targetType = position.type[i1][j1];
  final targetNr = position.nr[i1][j1];
  if (targetType != 0 && _isMinorOrMajor(targetType) && targetNr != null) {
    _decreasePieceNr(pieceLists, position, targetType, targetNr);
  }

  String? promotionStr;
  var promotedPieceType = 0;
  if (pieceType != wPawn && pieceType != bPawn) {
    position.type[i1][j1] = pieceType;
    position.nr[i1][j1] = pieceNr;
    if (pieceNr != null) pieceLists.byType[pieceType][pieceNr] = (i1, j1);
  } else {
    if (pieceType == wPawn && j1 == 7) {
      (promotedPieceType, promotionStr) = _promotionFor(cbPromotionCode, isWhite: true);
    }
    if (pieceType == bPawn && j1 == 0) {
      (promotedPieceType, promotionStr) = _promotionFor(cbPromotionCode, isWhite: false);
    }
  }
  if (promotedPieceType != 0) {
    final l = pieceLists.byType[promotedPieceType];
    var freeIdx = 0;
    while (l[freeIdx] != null) {
      freeIdx++;
    }
    l[freeIdx] = (i1, j1);
    position.type[i1][j1] = promotedPieceType;
    position.nr[i1][j1] = freeIdx;
  }
  return (squareName(i, j), squareName(i1, j1), promotionStr);
}

(int, String) _promotionFor(int cbPromotionCode, {required bool isWhite}) {
  switch (cbPromotionCode) {
    case 0:
      return (isWhite ? wQueen : bQueen, 'q');
    case 1:
      return (isWhite ? wRook : bRook, 'r');
    case 2:
      return (isWhite ? wBishop : bBishop, 'b');
    case 3:
      return (isWhite ? wKnight : bKnight, 'n');
    default:
      throw FormatException('unknown promotion piece code $cbPromotionCode');
  }
}

class DecodedGame {
  final GameNode root;
  final String? error;

  /// Mainline-only ply index (1-based, matching the running `processedMoves`
  /// counter used to de-obfuscate the byte stream) -> the node created for
  /// that ply. Used for the best-effort .cba comment/NAG attachment; moves
  /// that happen inside a variation are not tracked here.
  final Map<int, GameNode> mainlinePlyNodes;

  DecodedGame({required this.root, required this.mainlinePlyNodes, this.error});
}

/// Applies a move (via the `chess` package) starting from [fen] and returns
/// its SAN plus the resulting FEN. Returns null if the move is illegal.
({String san, String fen})? _applyToBoard(
  String fen,
  String from,
  String to,
  String? promotion,
) {
  final board = cjs.Chess();
  if (!board.load(fen)) return null;
  final Map<String, String> moveArg = {'from': from, 'to': to};
  if (promotion != null) moveArg['promotion'] = promotion;
  if (!board.move(moveArg)) return null;
  final history = board.getHistory();
  if (history.isEmpty) return null;
  return (san: history.last as String, fen: board.fen);
}

class _StackFrame {
  final GameNode node;
  final CbPosition position;
  final CbPieceLists pieceLists;
  final String fen;
  _StackFrame(this.node, this.position, this.pieceLists, this.fen);
}

/// Decodes the move bytes of one game into a [GameNode] tree.
///
/// [gameBytes] must already be sliced to just the move-encoding region
/// (i.e. starting right after the CBG per-game header).
DecodedGame decodeGame(
  Uint8List gameBytes,
  CbPosition position,
  CbPieceLists pieceLists, {
  String fen = standardStartFen,
}) {
  final root = GameNode(fen: fen);
  final mainlinePlyNodes = <int, GameNode>{};
  final stack = <_StackFrame>[];

  var node = root;
  var processedMoves = 0;
  var absolutePly = 0;
  var idx = 0;
  String? errorString;

  bool isWhiteToMove() => fen.split(' ')[1] == 'w';

  try {
    while (idx < gameBytes.length) {
      final rawByte = gameBytes[idx];
      final tkn = (rawByte - processedMoves) % 256;
      if (!specialCodes.contains(tkn)) {
        processedMoves = (processedMoves + 1) % 256;
      }

      if (tkn == specialSkip) {
        idx += 1;
        continue;
      }

      if (tkn == specialNullMove) {
        node = node.addVariation(san: '--', fen: fen);
        if (stack.isEmpty) {
          absolutePly++;
          mainlinePlyNodes[absolutePly] = node;
        }
        idx += 1;
        continue;
      }

      if (tkn == specialTwoByteMove) {
        final b1 = deobfuscate2b[(gameBytes[idx + 1] - processedMoves) % 256];
        final b2 = deobfuscate2b[(gameBytes[idx + 2] - processedMoves) % 256];
        final move2b = (b1 << 8) | b2;
        final src = move2b & 0x3F;
        final dst = (move2b >> 6) & 0x3F;
        final promotionCode = (move2b >> 12) & 0x3;
        final srcXY = absToXY[src];
        final dstXY = absToXY[dst];
        final (from, to, promo) = _applyTwoByteMove(
          pieceLists,
          srcXY[0],
          srcXY[1],
          dstXY[0],
          dstXY[1],
          position,
          promotionCode,
        );
        final applied = _applyToBoard(fen, from, to, promo);
        if (applied == null) {
          throw FormatException('illegal 2-byte move $from-$to (promo=$promo)');
        }
        fen = applied.fen;
        node = node.addVariation(san: applied.san, fen: fen);
        processedMoves = (processedMoves + 1) % 256;
        if (stack.isEmpty) {
          absolutePly++;
          mainlinePlyNodes[absolutePly] = node;
        }
        idx += 3;
        continue;
      }

      if (tkn == specialStartVariation) {
        stack.add(_StackFrame(node, position.clone(), pieceLists.clone(), fen));
      }
      if (tkn == specialEndVariation) {
        if (idx < gameBytes.length - 1 && stack.isNotEmpty) {
          final frame = stack.removeLast();
          node = frame.node;
          position = frame.position;
          pieceLists = frame.pieceLists;
          fen = frame.fen;
        }
      }

      final whiteToMove = isWhiteToMove();
      Map<int, List<int>>? encMap;
      int pieceType = 0;
      int pieceNr = 0;
      bool pawnFlip = false;

      if (whiteToMove) {
        if (cbKingEnc.containsKey(tkn)) {
          encMap = cbKingEnc;
          pieceType = wKing;
          pieceNr = 0;
        } else if (cbQueen1Enc.containsKey(tkn)) {
          encMap = cbQueen1Enc;
          pieceType = wQueen;
          pieceNr = 0;
        } else if (cbQueen2Enc.containsKey(tkn)) {
          encMap = cbQueen2Enc;
          pieceType = wQueen;
          pieceNr = 1;
        } else if (cbQueen3Enc.containsKey(tkn)) {
          encMap = cbQueen3Enc;
          pieceType = wQueen;
          pieceNr = 2;
        } else if (cbRook1Enc.containsKey(tkn)) {
          encMap = cbRook1Enc;
          pieceType = wRook;
          pieceNr = 0;
        } else if (cbRook2Enc.containsKey(tkn)) {
          encMap = cbRook2Enc;
          pieceType = wRook;
          pieceNr = 1;
        } else if (cbRook3Enc.containsKey(tkn)) {
          encMap = cbRook3Enc;
          pieceType = wRook;
          pieceNr = 2;
        } else if (cbBishop1Enc.containsKey(tkn)) {
          encMap = cbBishop1Enc;
          pieceType = wBishop;
          pieceNr = 0;
        } else if (cbBishop2Enc.containsKey(tkn)) {
          encMap = cbBishop2Enc;
          pieceType = wBishop;
          pieceNr = 1;
        } else if (cbBishop3Enc.containsKey(tkn)) {
          encMap = cbBishop3Enc;
          pieceType = wBishop;
          pieceNr = 2;
        } else if (cbKnight1Enc.containsKey(tkn)) {
          encMap = cbKnight1Enc;
          pieceType = wKnight;
          pieceNr = 0;
        } else if (cbKnight2Enc.containsKey(tkn)) {
          encMap = cbKnight2Enc;
          pieceType = wKnight;
          pieceNr = 1;
        } else if (cbKnight3Enc.containsKey(tkn)) {
          encMap = cbKnight3Enc;
          pieceType = wKnight;
          pieceNr = 2;
        } else if (cbPawnAEnc.containsKey(tkn)) {
          encMap = cbPawnAEnc;
          pieceType = wPawn;
          pieceNr = 0;
        } else if (cbPawnBEnc.containsKey(tkn)) {
          encMap = cbPawnBEnc;
          pieceType = wPawn;
          pieceNr = 1;
        } else if (cbPawnCEnc.containsKey(tkn)) {
          encMap = cbPawnCEnc;
          pieceType = wPawn;
          pieceNr = 2;
        } else if (cbPawnDEnc.containsKey(tkn)) {
          encMap = cbPawnDEnc;
          pieceType = wPawn;
          pieceNr = 3;
        } else if (cbPawnEEnc.containsKey(tkn)) {
          encMap = cbPawnEEnc;
          pieceType = wPawn;
          pieceNr = 4;
        } else if (cbPawnFEnc.containsKey(tkn)) {
          encMap = cbPawnFEnc;
          pieceType = wPawn;
          pieceNr = 5;
        } else if (cbPawnGEnc.containsKey(tkn)) {
          encMap = cbPawnGEnc;
          pieceType = wPawn;
          pieceNr = 6;
        } else if (cbPawnHEnc.containsKey(tkn)) {
          encMap = cbPawnHEnc;
          pieceType = wPawn;
          pieceNr = 7;
        }
      } else {
        if (cbKingEnc.containsKey(tkn)) {
          encMap = cbKingEnc;
          pieceType = bKing;
          pieceNr = 0;
        } else if (cbQueen1Enc.containsKey(tkn)) {
          encMap = cbQueen1Enc;
          pieceType = bQueen;
          pieceNr = 0;
        } else if (cbQueen2Enc.containsKey(tkn)) {
          encMap = cbQueen2Enc;
          pieceType = bQueen;
          pieceNr = 1;
        } else if (cbQueen3Enc.containsKey(tkn)) {
          encMap = cbQueen3Enc;
          pieceType = bQueen;
          pieceNr = 2;
        } else if (cbRook1Enc.containsKey(tkn)) {
          encMap = cbRook1Enc;
          pieceType = bRook;
          pieceNr = 0;
        } else if (cbRook2Enc.containsKey(tkn)) {
          encMap = cbRook2Enc;
          pieceType = bRook;
          pieceNr = 1;
        } else if (cbRook3Enc.containsKey(tkn)) {
          encMap = cbRook3Enc;
          pieceType = bRook;
          pieceNr = 2;
        } else if (cbBishop1Enc.containsKey(tkn)) {
          encMap = cbBishop1Enc;
          pieceType = bBishop;
          pieceNr = 0;
        } else if (cbBishop2Enc.containsKey(tkn)) {
          encMap = cbBishop2Enc;
          pieceType = bBishop;
          pieceNr = 1;
        } else if (cbBishop3Enc.containsKey(tkn)) {
          encMap = cbBishop3Enc;
          pieceType = bBishop;
          pieceNr = 2;
        } else if (cbKnight1Enc.containsKey(tkn)) {
          encMap = cbKnight1Enc;
          pieceType = bKnight;
          pieceNr = 0;
        } else if (cbKnight2Enc.containsKey(tkn)) {
          encMap = cbKnight2Enc;
          pieceType = bKnight;
          pieceNr = 1;
        } else if (cbKnight3Enc.containsKey(tkn)) {
          encMap = cbKnight3Enc;
          pieceType = bKnight;
          pieceNr = 2;
        } else if (cbPawnAEnc.containsKey(tkn)) {
          encMap = cbPawnAEnc;
          pieceType = bPawn;
          pieceNr = 0;
          pawnFlip = true;
        } else if (cbPawnBEnc.containsKey(tkn)) {
          encMap = cbPawnBEnc;
          pieceType = bPawn;
          pieceNr = 1;
          pawnFlip = true;
        } else if (cbPawnCEnc.containsKey(tkn)) {
          encMap = cbPawnCEnc;
          pieceType = bPawn;
          pieceNr = 2;
          pawnFlip = true;
        } else if (cbPawnDEnc.containsKey(tkn)) {
          encMap = cbPawnDEnc;
          pieceType = bPawn;
          pieceNr = 3;
          pawnFlip = true;
        } else if (cbPawnEEnc.containsKey(tkn)) {
          encMap = cbPawnEEnc;
          pieceType = bPawn;
          pieceNr = 4;
          pawnFlip = true;
        } else if (cbPawnFEnc.containsKey(tkn)) {
          encMap = cbPawnFEnc;
          pieceType = bPawn;
          pieceNr = 5;
          pawnFlip = true;
        } else if (cbPawnGEnc.containsKey(tkn)) {
          encMap = cbPawnGEnc;
          pieceType = bPawn;
          pieceNr = 6;
          pawnFlip = true;
        } else if (cbPawnHEnc.containsKey(tkn)) {
          encMap = cbPawnHEnc;
          pieceType = bPawn;
          pieceNr = 7;
          pawnFlip = true;
        }
      }

      if (encMap != null) {
        final (from, to) = _applyOneByteMove(
          pieceLists,
          pieceType,
          pieceNr,
          position,
          encMap,
          tkn,
          pawnFlip: pawnFlip,
        );
        final applied = _applyToBoard(fen, from, to, null);
        if (applied == null) {
          throw FormatException('illegal move $from-$to');
        }
        fen = applied.fen;
        node = node.addVariation(san: applied.san, fen: fen);
        if (stack.isEmpty) {
          absolutePly++;
          mainlinePlyNodes[absolutePly] = node;
        }
      }

      idx += 1;
    }
  } on FormatException catch (e) {
    errorString = e.message;
  } on StateError catch (e) {
    errorString = e.message;
  }

  return DecodedGame(root: root, mainlinePlyNodes: mainlinePlyNodes, error: errorString);
}
