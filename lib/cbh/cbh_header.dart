// Parsing of a single 46-byte .cbh record.
// Ported from the reference Python implementation (header.py) at
// https://github.com/asdfjkl/cbh2pgn - MIT licensed.

import 'dart:typed_data';

import 'bin_utils.dart';

const int cbhRecordSize = 46;

const int _maskIsGame = 0x01;
const int _maskMarkedForDeletion = 0x80;
const int _maskDay = 0x00000000001F;
const int _maskMonth = 0x0000000001E0;
const int _maskYear = 0xFFFE00;

class CbhRecord {
  final Uint8List bytes;

  CbhRecord(this.bytes) : assert(bytes.length == cbhRecordSize);

  bool get isGame => (_maskIsGame & bytes[0]) != 0;

  bool get isMarkedAsDeleted => ((_maskMarkedForDeletion & bytes[0]) >> 7) == 1;

  int get gameOffset => readUint32BE(bytes, 1);

  int get whitePlayerOffset => readUint24BE(bytes, 9);

  int get blackPlayerOffset => readUint24BE(bytes, 12);

  int get tournamentOffset => readUint24BE(bytes, 15);

  /// Returns (year, month, day). 0 means "unknown" for that field.
  (int, int, int) get yearMonthDay {
    final yymmdd = readUint24BE(bytes, 24);
    final year = (yymmdd & _maskYear) >> 9;
    final month = (yymmdd & _maskMonth) >> 5;
    final day = yymmdd & _maskDay;
    return (year, month, day);
  }

  /// PGN Date tag value, e.g. "2021.03.??".
  String get pgnDate {
    final (year, month, day) = yearMonthDay;
    final y = year != 0 ? year.toString().padLeft(4, '0') : '????';
    final m = month != 0 ? month.toString().padLeft(2, '0') : '??';
    final d = day != 0 ? day.toString().padLeft(2, '0') : '??';
    return '$y.$m.$d';
  }

  /// PGN Result tag value.
  String get result {
    final code = bytes[27];
    switch (code) {
      case 2:
        return '1-0';
      case 1:
        return '1/2-1/2';
      case 0:
        return '0-1';
      default:
        return '*';
    }
  }

  int get round => bytes[29];

  int get subround => bytes[30];

  /// Returns (whiteElo, blackElo).
  (int, int) get ratings {
    final whiteElo = readUint16BE(bytes, 31);
    final blackElo = readUint16BE(bytes, 33);
    return (whiteElo, blackElo);
  }
}
