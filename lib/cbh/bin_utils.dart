// Shared big-endian integer readers used across the .cbh/.cbg parsers.

import 'dart:typed_data';

int readUint16BE(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

int readUint24BE(Uint8List bytes, int offset) {
  return (bytes[offset] << 16) | (bytes[offset + 1] << 8) | bytes[offset + 2];
}

int readUint32BE(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
