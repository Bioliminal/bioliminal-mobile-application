import 'dart:typed_data';

/// One BLE notify packet from the ESP32 firmware (sketch `bicep_realtime`).
///
/// Wire format (308 bytes total) per
/// `docs/hardware_integration/data-capture-handshake.md`:
///
/// ```
/// byte 0:        seq_num            (u8, wraps at 256)
/// bytes 1-4:     t_us_start         (u32 LE, microseconds since boot)
/// byte 5:        channel_count      (u8, == 3 in v0)
/// byte 6:        samples_per_channel(u8, == 50 in v0)
/// byte 7:        flags              (bit0 RAW clip, bit1 RECT clip, bit2 ENV clip)
/// bytes 8-107:   raw   samples      (50 * u16 LE, range 0-4095)
/// bytes 108-207: rect  samples      (50 * u16 LE, range 0-4095)
/// bytes 208-307: env   samples      (50 * u16 LE, range 0-4095)
/// ```
///
/// Sample rate is fixed at 2 kHz, so per-sample t_us = `tUsStart + i * 500`.
class SampleBatch {
  SampleBatch({
    required this.seqNum,
    required this.tUsStart,
    required this.channelCount,
    required this.samplesPerChannel,
    required this.flags,
    required this.raw,
    required this.rect,
    required this.env,
  });

  final int seqNum;
  final int tUsStart;
  final int channelCount;
  final int samplesPerChannel;
  final int flags;
  final Uint16List raw;
  final Uint16List rect;
  final Uint16List env;

  bool get clipRaw => (flags & 0x1) != 0;
  bool get clipRect => (flags & 0x2) != 0;
  bool get clipEnv => (flags & 0x4) != 0;
  bool get clippedAny => flags != 0;

  /// Microsecond timestamp of sample `i` within the batch, fixed 2 kHz.
  int tUsAt(int i) => tUsStart + i * 500;

  /// Decode a 308-byte BLE notification into a [SampleBatch], or null if the
  /// payload doesn't match the v0 wire format. Caller should log + count on
  /// null returns rather than half-process a malformed packet.
  static SampleBatch? decode(List<int> bytes) {
    if (bytes.length != packetSize) return null;
    final buffer = Uint8List.fromList(bytes).buffer;
    final view = ByteData.view(buffer);

    final channelCount = view.getUint8(5);
    final samplesPerChannel = view.getUint8(6);
    if (channelCount != 3 || samplesPerChannel != 50) return null;

    Uint16List slice(int byteOffset) {
      final out = Uint16List(samplesPerChannel);
      for (var i = 0; i < samplesPerChannel; i++) {
        out[i] = view.getUint16(byteOffset + i * 2, Endian.little);
      }
      return out;
    }

    return SampleBatch(
      seqNum: view.getUint8(0),
      tUsStart: view.getUint32(1, Endian.little),
      channelCount: channelCount,
      samplesPerChannel: samplesPerChannel,
      flags: view.getUint8(7),
      raw: slice(8),
      rect: slice(108),
      env: slice(208),
    );
  }

  static const int packetSize = 308;
}
