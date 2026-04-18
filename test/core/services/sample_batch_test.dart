import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/core/services/sample_batch.dart';

void main() {
  group('SampleBatch.decode', () {
    test('decodes a well-formed 308-byte packet', () {
      final bytes = _buildPacket(
        seqNum: 42,
        tUsStart: 1234567,
        flags: 0x05, // raw + env clip
        rawFill: 1000,
        rectFill: 2000,
        envFill: 3000,
      );

      final batch = SampleBatch.decode(bytes)!;

      expect(batch.seqNum, 42);
      expect(batch.tUsStart, 1234567);
      expect(batch.channelCount, 3);
      expect(batch.samplesPerChannel, 50);
      expect(batch.flags, 0x05);
      expect(batch.clipRaw, isTrue);
      expect(batch.clipRect, isFalse);
      expect(batch.clipEnv, isTrue);
      expect(batch.clippedAny, isTrue);
      expect(batch.raw.length, 50);
      expect(batch.raw.first, 1000);
      expect(batch.rect.first, 2000);
      expect(batch.env.first, 3000);
      expect(batch.tUsAt(0), 1234567);
      expect(batch.tUsAt(49), 1234567 + 49 * 500);
    });

    test('returns null on wrong length', () {
      expect(SampleBatch.decode(List<int>.filled(307, 0)), isNull);
      expect(SampleBatch.decode(List<int>.filled(309, 0)), isNull);
      expect(SampleBatch.decode(<int>[]), isNull);
    });

    test('returns null on unsupported channel layout', () {
      final bytes = _buildPacket(
        seqNum: 0,
        tUsStart: 0,
        flags: 0,
        channelCount: 6,
      );
      expect(SampleBatch.decode(bytes), isNull);
    });

    test('reads samples little-endian', () {
      final bytes = _buildPacket(seqNum: 0, tUsStart: 0, flags: 0);
      // Overwrite the first RAW sample with 0x0102 little-endian = bytes 0x02, 0x01.
      bytes[8] = 0x02;
      bytes[9] = 0x01;
      final batch = SampleBatch.decode(bytes)!;
      expect(batch.raw[0], 0x0102);
    });
  });
}

List<int> _buildPacket({
  required int seqNum,
  required int tUsStart,
  required int flags,
  int channelCount = 3,
  int samplesPerChannel = 50,
  int rawFill = 0,
  int rectFill = 0,
  int envFill = 0,
}) {
  final out = Uint8List(SampleBatch.packetSize);
  final view = ByteData.view(out.buffer);
  view.setUint8(0, seqNum);
  view.setUint32(1, tUsStart, Endian.little);
  view.setUint8(5, channelCount);
  view.setUint8(6, samplesPerChannel);
  view.setUint8(7, flags);

  void fill(int byteOffset, int value) {
    for (var i = 0; i < samplesPerChannel; i++) {
      view.setUint16(byteOffset + i * 2, value, Endian.little);
    }
  }

  fill(8, rawFill);
  fill(108, rectFill);
  fill(208, envFill);

  return out;
}
