// EXPERIMENTAL best-effort parser for the .cba annotations file (text
// comments and move-quality symbols such as !, ?, !!, ??).
//
// Unlike the rest of this package, this is NOT ported from a working,
// tested reference implementation - the reference cbh2pgn project does not
// read this file at all. The record layout below is reconstructed from a
// community forum thread describing the format (TalkChess.com), which was
// itself never cross-checked against a real .cba file by this code.
//
// Every read here is defensive: if anything looks inconsistent (an offset
// running past the buffer, an unexpected type byte, a byte count that
// doesn't add up), the offending entry - or the rest of that game's
// annotations - is silently dropped rather than throwing. A parsing
// mistake here must never be able to break move/PGN decoding, and should
// be treated as "needs validation against a real database" rather than
// as trustworthy as the rest of the .cbh/.cbg/.cbp/.cbt port.

import 'dart:convert';
import 'dart:typed_data';

class CbaAnnotation {
  /// Best-effort absolute ply index this annotation attaches to (1-based,
  /// matching the mainline ply counter used while decoding the game's
  /// moves). Only mainline-attached annotations are supported.
  final int plyPosition;
  final String? textBefore;
  final String? textAfter;
  final String? nagSuffix;

  CbaAnnotation({
    required this.plyPosition,
    this.textBefore,
    this.textAfter,
    this.nagSuffix,
  });
}

const Map<int, String> _nagSuffixes = {
  1: '!',
  2: '?',
  3: '!!',
  4: '??',
  5: '!?',
  6: '?!',
};

int _readUint24LE(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}

int _readUint32BE(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _readUint16LE(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

String? _decodeText(Uint8List bytes, int offset, int length) {
  if (length < 2 || offset + length > bytes.length) return null;
  // Best-effort guess: first content byte is a language marker, the rest
  // is the actual comment text.
  final textBytes = bytes.sublist(offset + 1, offset + length);
  var text = utf8.decode(textBytes, allowMalformed: true);
  final zeroIndex = text.indexOf('\u0000');
  if (zeroIndex >= 0) text = text.substring(0, zeroIndex);
  text = text.trim();
  return text.isEmpty ? null : text;
}

/// Parses the whole .cba file into a map of (1-based cbh record index) ->
/// list of annotations for that game. Returns an empty map (never throws)
/// if the file doesn't look like the assumed layout at all.
Map<int, List<CbaAnnotation>> parseCbaFile(Uint8List cba) {
  final result = <int, List<CbaAnnotation>>{};
  var offset = 0;
  while (offset + 14 <= cba.length) {
    try {
      final gameId = _readUint24LE(cba, offset);
      final byteCount = _readUint32BE(cba, offset + 10);
      final dataStart = offset + 14;
      final dataEnd = dataStart + byteCount;
      if (byteCount < 0 || dataEnd > cba.length) {
        // Doesn't fit - stop trying to parse the rest of the file rather
        // than guessing wildly from a wrong offset.
        break;
      }
      final entries = _parseGameEntries(cba, dataStart, dataEnd);
      if (entries.isNotEmpty) {
        result.putIfAbsent(gameId, () => []).addAll(entries);
      }
      offset = dataEnd;
    } catch (_) {
      // Bail out of the whole file on the first structural surprise -
      // better to silently produce no comments than garbled ones.
      break;
    }
  }
  return result;
}

List<CbaAnnotation> _parseGameEntries(Uint8List cba, int start, int end) {
  final entries = <CbaAnnotation>[];
  var offset = start;
  while (offset + 6 <= end) {
    try {
      final plyPosition = _readUint24LE(cba, offset);
      final type = cba[offset + 3];
      final length = _readUint16LE(cba, offset + 4);
      final contentOffset = offset + 6;
      if (contentOffset + length > end) break;

      switch (type) {
        case 0x03: // symbol / NAG
          if (length >= 1) {
            final code = cba[contentOffset];
            final suffix = _nagSuffixes[code];
            if (suffix != null) {
              entries.add(CbaAnnotation(plyPosition: plyPosition, nagSuffix: suffix));
            }
          }
        case 0x02: // text after move
          final text = _decodeText(cba, contentOffset, length);
          if (text != null) {
            entries.add(CbaAnnotation(plyPosition: plyPosition, textAfter: text));
          }
        case 0x82: // text before move
          final text = _decodeText(cba, contentOffset, length);
          if (text != null) {
            entries.add(CbaAnnotation(plyPosition: plyPosition, textBefore: text));
          }
        default:
          // Medal badges (0x22) and anything unrecognized are skipped.
          break;
      }
      offset = contentOffset + length;
    } catch (_) {
      break;
    }
  }
  return entries;
}
