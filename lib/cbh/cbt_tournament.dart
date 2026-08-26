// Tournament (event/site) lookup in a .cbt file. Ported from tournament.py
// at https://github.com/asdfjkl/cbh2pgn - MIT licensed.

import 'dart:convert';
import 'dart:typed_data';

String _readZeroTerminatedString(Uint8List bytes, int offset, int length) {
  final slice = bytes.sublist(offset, offset + length);
  final decoded = utf8.decode(slice, allowMalformed: true);
  final zeroIndex = decoded.indexOf('\u0000');
  return zeroIndex >= 0 ? decoded.substring(0, zeroIndex) : decoded;
}

/// Returns (event title, site/place) for the tournament at [tournamentNo].
(String, String) getEventSite(Uint8List cbtBytes, int tournamentNo) {
  final int recordOffset;
  final versionByte = cbtBytes[0x18];
  if (versionByte == 4) {
    recordOffset = 32 + (tournamentNo * 99);
  } else if (versionByte == 0) {
    recordOffset = 28 + (tournamentNo * 99);
  } else {
    throw StateError('unknown CBT file version: $versionByte');
  }
  final title = _readZeroTerminatedString(cbtBytes, recordOffset + 9, 40);
  final place = _readZeroTerminatedString(cbtBytes, recordOffset + 49, 30);
  return (title, place);
}
