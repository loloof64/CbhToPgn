import 'dart:convert';
import 'dart:typed_data';

import 'package:cbh_to_pgn/cbh/cbh_database.dart';
import 'package:cbh_to_pgn/cbh/cbh_header.dart';
import 'package:flutter_test/flutter_test.dart';

void _writeName(Uint8List buf, int offset, String text) {
  final bytes = utf8.encode(text);
  buf.setRange(offset, offset + bytes.length, bytes);
}

Uint8List _buildCbp() {
  // version byte 0 -> record layout: 28 + playerNo*67, last name at +9
  // (30 bytes), first name at +39 (20 bytes).
  final buf = Uint8List(28 + 2 * 67);
  buf[0x18] = 0;
  _writeName(buf, 28 + 0 * 67 + 9, 'Doe');
  _writeName(buf, 28 + 0 * 67 + 39, 'John');
  _writeName(buf, 28 + 1 * 67 + 9, 'Smith');
  _writeName(buf, 28 + 1 * 67 + 39, 'Anna');
  return buf;
}

Uint8List _buildCbt() {
  final buf = Uint8List(28 + 99);
  buf[0x18] = 0;
  _writeName(buf, 28 + 9, 'Test Open');
  _writeName(buf, 28 + 49, 'Testville');
  return buf;
}

Uint8List _buildCbh() {
  // Record 0: dummy header slot (never read as a game).
  // Record 1: a single real game.
  final buf = Uint8List(cbhRecordSize * 2);
  final record = Uint8List(cbhRecordSize);
  record[0] = 0x01; // is_game
  // gameOffset = 0 (bytes 1-4, BE)
  // whitePlayerOffset = 0 (bytes 9-11)
  record[12] = 0; // blackPlayerOffset high byte
  record[13] = 0;
  record[14] = 1; // blackPlayerOffset = 1
  // tournamentOffset = 0 (bytes 15-17)
  final yymmdd = (2022 << 9) | (5 << 5) | 1;
  record[24] = (yymmdd >> 16) & 0xFF;
  record[25] = (yymmdd >> 8) & 0xFF;
  record[26] = yymmdd & 0xFF;
  record[27] = 2; // result 1-0
  record[29] = 1; // round
  buf.setRange(cbhRecordSize, cbhRecordSize * 2, record);
  return buf;
}

Uint8List _buildCbg() {
  // Single-game file: 4-byte size/flags header (initial position, encoded,
  // no special flags) followed by one move byte (1. e4).
  final moveBytes = <int>[0xFF];
  final gameLen = 4 + moveBytes.length;
  final buf = Uint8List(gameLen);
  buf[0] = (gameLen >> 24) & 0xFF;
  buf[1] = (gameLen >> 16) & 0xFF;
  buf[2] = (gameLen >> 8) & 0xFF;
  buf[3] = gameLen & 0xFF;
  buf.setRange(4, gameLen, moveBytes);
  return buf;
}

void main() {
  test('converts a minimal synthetic database end-to-end', () {
    final db = CbhDatabase(
      cbh: _buildCbh(),
      cbg: _buildCbg(),
      cbp: _buildCbp(),
      cbt: _buildCbt(),
    );

    expect(db.gameCount, 1);
    final result = db.convertAll();

    expect(result.issues, isEmpty);
    expect(result.games, hasLength(1));

    final pgn = result.games.single.pgnText;
    expect(pgn, contains('[White "Doe, John"]'));
    expect(pgn, contains('[Black "Smith, Anna"]'));
    expect(pgn, contains('[Event "Test Open"]'));
    expect(pgn, contains('[Site "Testville"]'));
    expect(pgn, contains('[Date "2022.05.01"]'));
    expect(pgn, contains('[Result "1-0"]'));
    expect(pgn, contains('1. e4'));
    expect(pgn.trim(), endsWith('1-0'));
  });
}
