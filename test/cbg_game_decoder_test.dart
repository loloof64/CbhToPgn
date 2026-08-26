import 'dart:typed_data';

import 'package:cbh_to_pgn/cbh/cbg_game_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

List<String?> _mainlineSans(DecodedGame decoded) {
  final sans = <String?>[];
  var node = decoded.root;
  while (node.variations.isNotEmpty) {
    node = node.variations[0];
    sans.add(node.san);
  }
  return sans;
}

void main() {
  test('standardStartSetup produces the standard starting FEN', () {
    final setup = standardStartSetup();
    final fen = cbPositionToFen(
      setup.position,
      epFile: 0,
      isBlacksTurn: false,
      wLong: true,
      wShort: true,
      bLong: true,
      bShort: true,
      nextMoveNo: 1,
    );
    expect(fen, standardStartFen);
  });

  test('decodes a single one-byte pawn move (1. e4)', () {
    final setup = standardStartSetup();
    final gameBytes = Uint8List.fromList([0xFF]);
    final decoded = decodeGame(gameBytes, setup.position, setup.pieceLists);

    expect(decoded.error, isNull);
    expect(_mainlineSans(decoded), ['e4']);
  });

  test('decodes two plies with the running obfuscation counter (1. e4 e5)', () {
    final setup = standardStartSetup();
    // Byte 0: tkn = 0xFF - 0 = 0xFF -> white e-pawn two squares (e4).
    // Byte 1: processedMoves is now 1, so byte must be (tkn + 1) % 256 for
    // tkn to decode back to 0xFF -> black e-pawn two squares (e5).
    final gameBytes = Uint8List.fromList([0xFF, 0x00]);
    final decoded = decodeGame(gameBytes, setup.position, setup.pieceLists);

    expect(decoded.error, isNull);
    expect(_mainlineSans(decoded), ['e4', 'e5']);
  });

  test('decodes a short opening sequence (1. e4 e5 2. Nf3)', () {
    final setup = standardStartSetup();
    // 1. e4  : tkn 0xFF, processedMoves 0 -> byte 0xFF
    // 1...e5 : tkn 0xFF, processedMoves 1 -> byte (0xFF+1)%256 = 0x00
    // 2. Nf3 : the kingside knight is the *second* entry in the white
    //          knight piece list (appended after the queenside knight
    //          during setup), so it uses CB_KNIGHT_2_ENC. g1->f3 is
    //          offset (-1,2), which is token 0xFE in that table.
    //          processedMoves is 2 -> byte (0xFE+2)%256 = 0x00
    final gameBytes = Uint8List.fromList([0xFF, 0x00, 0x00]);
    final decoded = decodeGame(gameBytes, setup.position, setup.pieceLists);

    expect(decoded.error, isNull);
    expect(_mainlineSans(decoded), ['e4', 'e5', 'Nf3']);
  });
}
