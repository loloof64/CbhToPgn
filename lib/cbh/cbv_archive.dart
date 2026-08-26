// Parser/decompressor for ChessBase .cbv archives (a single file bundling
// the .cbh/.cbg/.cbp/.cbt/.cba companion files, produced by ChessBase's
// "Backup database" / "Archive" feature). The format is undocumented; this
// is a clean-room Dart port of the algorithm described by the GPL-3.0
// `uncbv` project (https://github.com/antoyo/uncbv, by Antoni Boucher),
// validated against real .cbv archives rather than copied from its source.
//
// Layout: an 8-byte header, then a fixed-size table of contents (one
// 173-byte record per companion file: a null-terminated name, a
// little-endian compressed size and decompressed size), followed by the
// compressed bytes of each file back to back in table order. Each file is
// split into one or more blocks; each block is independently flagged as
// stored, LZ-compressed, Huffman-coded, or both.
//
// Encrypted archives (ChessBase's "Crypted" backup option, saved as .cbz)
// are not supported - the header check below will reject them cleanly.

import 'dart:typed_data';

class CbvFormatException implements Exception {
  final String message;
  CbvFormatException(this.message);

  @override
  String toString() => message;
}

int _readUint16LE(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int _readUint32LE(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

class _CbvFileEntry {
  final String filename;
  final int compressedSize;
  final int decompressedSize;
  _CbvFileEntry(this.filename, this.compressedSize, this.decompressedSize);
}

/// Extracts every companion file from a .cbv archive, keyed by lowercase
/// extension (without the dot), e.g. `{'cbh': ..., 'cbg': ..., 'cba': ...}`.
Map<String, Uint8List> extractCbvArchive(Uint8List bytes) {
  if (bytes.length < 8 || bytes[0] != 0x08 || bytes[1] != 0x00) {
    throw CbvFormatException(
      "Ce fichier ne ressemble pas à une archive .cbv non chiffrée "
      "(en-tête inattendu ; les archives .cbz chiffrées ne sont pas prises en charge).",
    );
  }
  final fileCount = _readUint16LE(bytes, 2);
  final recordSize = bytes[4];

  final entries = <_CbvFileEntry>[];
  var recordOffset = 8;
  for (var i = 0; i < fileCount; i++) {
    final record = bytes.sublist(recordOffset, recordOffset + recordSize);
    var nameEnd = 0;
    while (nameEnd < 132 && record[nameEnd] != 0) {
      nameEnd++;
    }
    final filename = String.fromCharCodes(record.sublist(0, nameEnd));
    final compressedSize = _readUint32LE(record, 132);
    final decompressedSize = _readUint32LE(record, 136);
    entries.add(_CbvFileEntry(filename, compressedSize, decompressedSize));
    recordOffset += recordSize;
  }

  final result = <String, Uint8List>{};
  var fileOffset = recordOffset;
  for (final entry in entries) {
    final fileBytes = bytes.sublist(fileOffset, fileOffset + entry.compressedSize);
    final decoded = _extractFile(fileBytes, entry.decompressedSize);
    final dot = entry.filename.lastIndexOf('.');
    if (dot != -1) {
      final ext = entry.filename.substring(dot + 1).toLowerCase();
      result[ext] = decoded;
    }
    fileOffset += entry.compressedSize;
  }
  return result;
}

Uint8List _extractFile(Uint8List fileBytes, int decompressedSize) {
  final output = BytesBuilder(copy: false);
  var pos = 0;
  while (pos < fileBytes.length) {
    final blockSize = _readUint16LE(fileBytes, pos);
    pos += 4; // block size + 2 unknown bytes
    final block = fileBytes.sublist(pos, pos + blockSize);
    pos += blockSize;
    output.add(_decodeBlock(block));
  }
  return output.toBytes();
}

Uint8List _decodeBlock(Uint8List block) {
  final flag = block[0];
  final huffmanEncoded = (flag & 0x02) != 0;
  final lzCompressed = (flag & 0x01) != 0;
  final rest = block.sublist(1);
  final intermediate = huffmanEncoded ? _huffmanDecode(rest) : rest;
  return lzCompressed ? _lzDecompress(intermediate) : intermediate;
}

class _HuffmanNode {
  _HuffmanNode? left;
  _HuffmanNode? right;
  int? value;
}

class _BitReader {
  final Uint8List bytes;
  int bitPos = 0;
  _BitReader(this.bytes);

  int readBits(int n) {
    var result = 0;
    for (var i = 0; i < n; i++) {
      final byteIndex = bitPos >> 3;
      final bitIndexInByte = 7 - (bitPos & 7);
      final bit = (bytes[byteIndex] >> bitIndexInByte) & 1;
      result = (result << 1) | bit;
      bitPos++;
    }
    return result;
  }
}

/// Decodes a Huffman-coded block: a big-endian output length, a 256-entry
/// code table (one variable-length code per possible byte value, each
/// prefixed by its 4-bit bit-length), then the bit-packed data itself.
Uint8List _huffmanDecode(Uint8List data) {
  final decompressedSize = (data[0] << 8) | data[1];
  final reader = _BitReader(data.sublist(2));

  final root = _HuffmanNode();
  for (var value = 0; value < 256; value++) {
    final length = reader.readBits(4);
    if (length == 0) continue;
    final code = reader.readBits(length);
    var node = root;
    for (var i = length - 1; i >= 0; i--) {
      final bit = (code >> i) & 1;
      if (bit == 0) {
        node = node.left ??= _HuffmanNode();
      } else {
        node = node.right ??= _HuffmanNode();
      }
    }
    node.value = value;
  }

  final output = Uint8List(decompressedSize);
  var written = 0;
  var node = root;
  while (written < decompressedSize) {
    final bit = reader.readBits(1);
    node = bit == 0 ? node.left! : node.right!;
    final value = node.value;
    if (value != null) {
      output[written++] = value;
      node = root;
    }
  }
  return output;
}

/// Decodes an LZ-style block: a stream of 16-bit "which of the next 16
/// tokens is a code vs. a literal byte" masks, where a code is either a
/// run of a repeated byte or a backward reference into the output so far.
Uint8List _lzDecompress(Uint8List input) {
  final result = <int>[];
  var pos = 0;
  outer:
  while (pos < input.length) {
    var codeBytes = _readUint16LE(input, pos);
    pos += 2;
    for (var bit = 0; bit < 16; bit++) {
      final coded = (codeBytes & 0x8000) != 0;
      if (coded) {
        final currentByte = input[pos];
        final high = currentByte >> 4;
        final low = currentByte & 0xF;
        if (high == 0) {
          final size = low + 3;
          final fillByte = input[pos + 1];
          result.addAll(List.filled(size, fillByte));
          pos += 2;
        } else if (high == 1) {
          final size = low + (input[pos + 1] << 4) + 0x13;
          final fillByte = input[pos + 2];
          result.addAll(List.filled(size, fillByte));
          pos += 3;
        } else {
          final offset = (input[pos + 1] << 4) + low + 3;
          int size;
          if (high == 2) {
            size = input[pos + 2] + 0x10;
            pos += 3;
          } else {
            size = high;
            pos += 2;
          }
          final start = result.length - offset;
          final backward = result.sublist(start, start + size);
          result.addAll(backward);
        }
      } else {
        result.add(input[pos]);
        pos += 1;
      }
      if (pos >= input.length) break outer;
      codeBytes = (codeBytes << 1) & 0xFFFF;
    }
  }
  return Uint8List.fromList(result);
}
