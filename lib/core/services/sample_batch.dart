import 'dart:typed_data';

/// One BLE notify packet from the ESP32 firmware.
///
/// **v1 wire format (310 bytes total)** for the hardware-led sketch
/// `bicep_autonomous`. Header grew by 2 bytes to carry `rep_count` and
/// `cue_event` — drives the rep counter and cue-flash overlay without
/// any on-device inference.
///
/// ```
/// byte 0:        seq_num            (u8, wraps at 256)
/// bytes 1-4:     t_us_start         (u32 LE, microseconds since boot)
/// byte 5:        channel_count      (u8, == 3)
/// byte 6:        samples_per_channel(u8, == 50)
/// byte 7:        flags              (bit0 RAW clip, bit1 RECT clip, bit2 ENV clip)
/// byte 8:        rep_count          (u8, monotonic per session, firmware-driven)
/// byte 9:        cue_event          (u8, bit0 = cue fired since last packet)
/// bytes 10-109:  raw   samples      (50 * u16 LE, range 0-4095)
/// bytes 110-209: rect  samples      (50 * u16 LE, range 0-4095)
/// bytes 210-309: env   samples      (50 * u16 LE, range 0-4095)
/// ```
///
/// Legacy 308-byte packets (from `bicep_realtime`) are rejected by this
/// decoder — the hardware-led branch of the app only talks to the 310-byte
/// firmware. Sample rate is fixed at 2 kHz, so per-sample `t_us =
/// tUsStart + i * 500`.
class SampleBatch {
  SampleBatch({
    required this.seqNum,
    required this.tUsStart,
    required this.channelCount,
    required this.samplesPerChannel,
    required this.flags,
    required this.repCount,
    required this.cueEvent,
    required this.raw,
    required this.rect,
    required this.env,
  });

  final int seqNum;
  final int tUsStart;
  final int channelCount;
  final int samplesPerChannel;
  final int flags;
  final int repCount;
  final int cueEvent;
  final Uint16List raw;
  final Uint16List rect;
  final Uint16List env;

  bool get clipRaw => (flags & 0x1) != 0;
  bool get clipRect => (flags & 0x2) != 0;
  bool get clipEnv => (flags & 0x4) != 0;
  bool get clippedAny => flags != 0;

  /// True when the firmware fired a haptic cue in the 25 ms window
  /// immediately preceding this packet. Drives the mobile cue-flash overlay.
  bool get cueFired => (cueEvent & 0x1) != 0;

  /// Microsecond timestamp of sample `i` within the batch, fixed 2 kHz.
  int tUsAt(int i) => tUsStart + i * 500;

  /// Decode a 310-byte BLE notification into a [SampleBatch], or null if the
  /// payload doesn't match the wire format.
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
      repCount: view.getUint8(8),
      cueEvent: view.getUint8(9),
      raw: slice(10),
      rect: slice(110),
      env: slice(210),
    );
  }

  static const int packetSize = 310;
}
