import 'dart:typed_data';

import 'package:cbh_to_pgn/cbh/cbh_header.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _buildRecord({
  bool isGame = true,
  bool deleted = false,
  int gameOffset = 0,
  int whiteOffset = 0,
  int blackOffset = 0,
  int tournamentOffset = 0,
  int year = 0,
  int month = 0,
  int day = 0,
  int resultCode = 3,
  int round = 0,
  int subround = 0,
  int whiteElo = 0,
  int blackElo = 0,
}) {
  final bytes = Uint8List(cbhRecordSize);
  bytes[0] = (isGame ? 0x01 : 0x00) | (deleted ? 0x80 : 0x00);
  bytes[1] = (gameOffset >> 24) & 0xFF;
  bytes[2] = (gameOffset >> 16) & 0xFF;
  bytes[3] = (gameOffset >> 8) & 0xFF;
  bytes[4] = gameOffset & 0xFF;
  bytes[9] = (whiteOffset >> 16) & 0xFF;
  bytes[10] = (whiteOffset >> 8) & 0xFF;
  bytes[11] = whiteOffset & 0xFF;
  bytes[12] = (blackOffset >> 16) & 0xFF;
  bytes[13] = (blackOffset >> 8) & 0xFF;
  bytes[14] = blackOffset & 0xFF;
  bytes[15] = (tournamentOffset >> 16) & 0xFF;
  bytes[16] = (tournamentOffset >> 8) & 0xFF;
  bytes[17] = tournamentOffset & 0xFF;
  final yymmdd = (year << 9) | (month << 5) | day;
  bytes[24] = (yymmdd >> 16) & 0xFF;
  bytes[25] = (yymmdd >> 8) & 0xFF;
  bytes[26] = yymmdd & 0xFF;
  bytes[27] = resultCode;
  bytes[29] = round;
  bytes[30] = subround;
  bytes[31] = (whiteElo >> 8) & 0xFF;
  bytes[32] = whiteElo & 0xFF;
  bytes[33] = (blackElo >> 8) & 0xFF;
  bytes[34] = blackElo & 0xFF;
  return bytes;
}

void main() {
  group('CbhRecord', () {
    test('decodes flags, offsets, date, result, round and ratings', () {
      final record = CbhRecord(_buildRecord(
        isGame: true,
        deleted: false,
        gameOffset: 123456,
        whiteOffset: 42,
        blackOffset: 99,
        tournamentOffset: 7,
        year: 2021,
        month: 3,
        day: 15,
        resultCode: 2,
        round: 5,
        subround: 2,
        whiteElo: 2500,
        blackElo: 2400,
      ));

      expect(record.isGame, isTrue);
      expect(record.isMarkedAsDeleted, isFalse);
      expect(record.gameOffset, 123456);
      expect(record.whitePlayerOffset, 42);
      expect(record.blackPlayerOffset, 99);
      expect(record.tournamentOffset, 7);
      expect(record.yearMonthDay, (2021, 3, 15));
      expect(record.pgnDate, '2021.03.15');
      expect(record.result, '1-0');
      expect(record.round, 5);
      expect(record.subround, 2);
      expect(record.ratings, (2500, 2400));
    });

    test('handles deleted / non-game / unknown-date / unknown-result records', () {
      final record = CbhRecord(_buildRecord(isGame: false, deleted: true, resultCode: 9));
      expect(record.isGame, isFalse);
      expect(record.isMarkedAsDeleted, isTrue);
      expect(record.pgnDate, '????.??.??');
      expect(record.result, '*');
    });

    test('maps result codes to PGN result strings', () {
      expect(CbhRecord(_buildRecord(resultCode: 2)).result, '1-0');
      expect(CbhRecord(_buildRecord(resultCode: 1)).result, '1/2-1/2');
      expect(CbhRecord(_buildRecord(resultCode: 0)).result, '0-1');
      expect(CbhRecord(_buildRecord(resultCode: 3)).result, '*');
    });
  });
}
