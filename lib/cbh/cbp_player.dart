// Player name lookup in a .cbp file. Ported from player.py at
// https://github.com/asdfjkl/cbh2pgn - MIT licensed.

import 'dart:convert';
import 'dart:typed_data';

String _readZeroTerminatedString(Uint8List bytes, int offset, int length) {
  final slice = bytes.sublist(offset, offset + length);
  final decoded = utf8.decode(slice, allowMalformed: true);
  final zeroIndex = decoded.indexOf('\u0000');
  return zeroIndex >= 0 ? decoded.substring(0, zeroIndex) : decoded;
}

/// Returns "Last, First" for the player at [playerNo] in the .cbp file bytes.
String getPlayerName(Uint8List cbpBytes, int playerNo) {
  final int recordOffset;
  final versionByte = cbpBytes[0x18];
  if (versionByte == 4) {
    recordOffset = 32 + (playerNo * 67);
  } else if (versionByte == 0) {
    recordOffset = 28 + (playerNo * 67);
  } else {
    throw StateError('unknown CBP file version: $versionByte');
  }
  final lastName = _readZeroTerminatedString(cbpBytes, recordOffset + 9, 30);
  final firstName = _readZeroTerminatedString(cbpBytes, recordOffset + 39, 20);
  return '$lastName, $firstName';
}
