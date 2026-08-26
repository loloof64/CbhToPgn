import 'dart:convert';
import 'dart:typed_data';

import 'package:cbh_to_pgn/cbh/cbv_archive.dart';
import 'package:flutter_test/flutter_test.dart';

const int _recordSize = 140; // minimum: 132-byte name + 2 x 4-byte sizes.

Uint8List _buildStoredBlock(List<int> content) {
  final payload = <int>[0x00, ...content]; // flag: not compressed, not huffman.
  final block = BytesBuilder();
  block.add([payload.length & 0xFF, (payload.length >> 8) & 0xFF]); // block size, LE.
  block.add([0, 0]); // unknown bytes.
  block.add(payload);
  return block.toBytes();
}

Uint8List _buildCbv(List<(String, List<int>)> files) {
  final toc = BytesBuilder();
  final data = BytesBuilder();
  for (final (name, content) in files) {
    final record = Uint8List(_recordSize);
    record.setRange(0, name.length, utf8.encode(name));
    final blocks = _buildStoredBlock(content);
    final view = ByteData.sublistView(record);
    view.setInt32(132, blocks.length, Endian.little);
    view.setInt32(136, content.length, Endian.little);
    toc.add(record);
    data.add(blocks);
  }

  final header = BytesBuilder();
  header.add([0x08, 0x00]);
  header.add([files.length & 0xFF, (files.length >> 8) & 0xFF]);
  header.add([_recordSize]);
  header.add([0, 0, 0]);

  final archive = BytesBuilder();
  archive.add(header.toBytes());
  archive.add(toc.toBytes());
  archive.add(data.toBytes());
  return archive.toBytes();
}

void main() {
  test('extracts stored (uncompressed) entries keyed by extension', () {
    final cbh = List.generate(20, (i) => i);
    final cbg = utf8.encode('pretend game data');
    final archive = _buildCbv([
      ('Study.cbh', cbh),
      ('Study.ini', utf8.encode('Title=Study\r\n')),
      ('Study.cbg', cbg),
    ]);

    final extracted = extractCbvArchive(archive);

    expect(extracted['cbh'], cbh);
    expect(extracted['cbg'], cbg);
    expect(extracted['ini'], utf8.encode('Title=Study\r\n'));
  });

  test('splits a single file across multiple blocks', () {
    final part1 = List.generate(10, (i) => i);
    final part2 = List.generate(10, (i) => 100 + i);
    final block1 = _buildStoredBlock(part1);
    final block2 = _buildStoredBlock(part2);

    final record = Uint8List(_recordSize);
    record.setRange(0, 'Study.cbp'.length, utf8.encode('Study.cbp'));
    final view = ByteData.sublistView(record);
    view.setInt32(132, block1.length + block2.length, Endian.little);
    view.setInt32(136, part1.length + part2.length, Endian.little);

    final header = BytesBuilder();
    header.add([0x08, 0x00, 1, 0, _recordSize, 0, 0, 0]);

    final archive = BytesBuilder();
    archive.add(header.toBytes());
    archive.add(record);
    archive.add(block1);
    archive.add(block2);

    final extracted = extractCbvArchive(archive.toBytes());

    expect(extracted['cbp'], [...part1, ...part2]);
  });

  test('rejects a file without the CBV magic header', () {
    expect(
      () => extractCbvArchive(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8])),
      throwsA(isA<CbvFormatException>()),
    );
  });
}
