import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:bioliminal/core/theme.dart';

// Live stream inspector for a single notify characteristic. Pushed from the
// BLE debug view once the hardware dev has identified which characteristic
// carries the sEMG payload.

enum _Format { uint8, int8, uint16le, uint16be, int16le, int16be, float32le }

extension on _Format {
  int get byteWidth => switch (this) {
        _Format.uint8 || _Format.int8 => 1,
        _Format.uint16le ||
        _Format.uint16be ||
        _Format.int16le ||
        _Format.int16be =>
          2,
        _Format.float32le => 4,
      };

  String get label => switch (this) {
        _Format.uint8 => 'uint8',
        _Format.int8 => 'int8',
        _Format.uint16le => 'u16 LE',
        _Format.uint16be => 'u16 BE',
        _Format.int16le => 'i16 LE',
        _Format.int16be => 'i16 BE',
        _Format.float32le => 'f32 LE',
      };
}

class BleLiveView extends StatefulWidget {
  const BleLiveView({
    super.key,
    required this.device,
    required this.characteristic,
  });

  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  @override
  State<BleLiveView> createState() => _BleLiveViewState();
}

class _BleLiveViewState extends State<BleLiveView> {
  static const int _historyLen = 240; // samples retained for the trace
  static const int _maxChannels = 16;

  StreamSubscription<List<int>>? _valueSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _rateTimer;

  final List<Queue<double>> _history =
      List.generate(_maxChannels, (_) => Queue<double>());
  List<int> _lastRaw = const [];
  int _packetCount = 0;
  int _byteCount = 0;
  int _packetRate = 0;
  int _byteRate = 0;
  int _lastPktTick = 0;
  int _lastByteTick = 0;
  BluetoothConnectionState _state = BluetoothConnectionState.connected;

  _Format _format = _Format.uint8;
  int _channels = 10;
  bool _paused = false;
  bool _recording = false;
  final List<List<double>> _recorded = [];

  @override
  void initState() {
    super.initState();
    _connSub = widget.device.connectionState.listen((s) {
      setState(() => _state = s);
    });
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _packetRate = _packetCount - _lastPktTick;
        _byteRate = _byteCount - _lastByteTick;
        _lastPktTick = _packetCount;
        _lastByteTick = _byteCount;
      });
    });
    _subscribe();
  }

  @override
  void dispose() {
    _valueSub?.cancel();
    _connSub?.cancel();
    _rateTimer?.cancel();
    widget.characteristic.setNotifyValue(false).catchError((_) => false);
    super.dispose();
  }

  Future<void> _subscribe() async {
    try {
      await widget.characteristic.setNotifyValue(true);
      _valueSub = widget.characteristic.lastValueStream.listen(_onPacket);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscribe failed: $e')),
        );
      }
    }
  }

  void _onPacket(List<int> bytes) {
    if (_paused) return;
    _packetCount++;
    _byteCount += bytes.length;
    _lastRaw = bytes;

    final decoded = _decode(bytes, _format, _channels);
    for (var i = 0; i < _maxChannels; i++) {
      final q = _history[i];
      q.addLast(i < decoded.length ? decoded[i] : 0.0);
      while (q.length > _historyLen) {
        q.removeFirst();
      }
    }
    if (_recording) _recorded.add(decoded);

    if (mounted) setState(() {});
  }

  void _clear() {
    setState(() {
      for (final q in _history) {
        q.clear();
      }
      _packetCount = 0;
      _byteCount = 0;
      _lastPktTick = 0;
      _lastByteTick = 0;
      _recorded.clear();
    });
  }

  Future<void> _copyCsv() async {
    final header = List.generate(_channels, (i) => 'ch$i').join(',');
    final rows = _recorded
        .map((r) => r.take(_channels).map((v) => v.toStringAsFixed(4)).join(','))
        .join('\n');
    await Clipboard.setData(ClipboardData(text: '$header\n$rows'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied ${_recorded.length} rows')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _state == BluetoothConnectionState.connected;
    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: const Text('LIVE STREAM'),
        actions: [
          IconButton(
            tooltip: _paused ? 'Resume' : 'Pause',
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _paused = !_paused),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.refresh),
            onPressed: _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          _header(connected),
          _metrics(),
          _decoderBar(),
          Expanded(child: _chart()),
          _channelTable(),
          _rawPanel(),
        ],
      ),
    );
  }

  Widget _header(bool connected) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: BioliminalTheme.surface,
      child: Row(
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: connected
                ? BioliminalTheme.confidenceHigh
                : BioliminalTheme.confidenceLow,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.platformName.isEmpty
                      ? widget.device.remoteId.str
                      : widget.device.platformName,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  widget.characteristic.uuid.str128,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black.withValues(alpha: 0.2),
      child: Row(
        children: [
          _metric('Hz', '$_packetRate'),
          _metric('B/s', '$_byteRate'),
          _metric('pkts', '$_packetCount'),
          _metric('bytes', '$_byteCount'),
          _metric(
            'last',
            _lastRaw.isEmpty ? '—' : '${_lastRaw.length}B',
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: BioliminalTheme.accent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _decoderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: BioliminalTheme.surface.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Text(
            'fmt',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(width: 6),
          DropdownButton<_Format>(
            value: _format,
            dropdownColor: BioliminalTheme.surface,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            underline: const SizedBox.shrink(),
            items: _Format.values
                .map(
                  (f) => DropdownMenuItem(value: f, child: Text(f.label)),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _format = v);
            },
          ),
          const SizedBox(width: 16),
          const Text(
            'ch',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(width: 6),
          DropdownButton<int>(
            value: _channels,
            dropdownColor: BioliminalTheme.surface,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            underline: const SizedBox.shrink(),
            items: List.generate(_maxChannels, (i) => i + 1)
                .map(
                  (n) => DropdownMenuItem(value: n, child: Text('$n')),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _channels = v);
            },
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _recording = !_recording),
            icon: Icon(
              _recording ? Icons.fiber_manual_record : Icons.radio_button_off,
              color: _recording
                  ? BioliminalTheme.confidenceLow
                  : Colors.white54,
              size: 16,
            ),
            label: Text(
              _recording ? 'Recording (${_recorded.length})' : 'Record',
            ),
          ),
          TextButton.icon(
            onPressed: _recorded.isEmpty ? null : _copyCsv,
            icon: const Icon(Icons.copy_all_outlined, size: 16),
            label: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  Widget _chart() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: CustomPaint(
        painter: _MultiTracePainter(
          traces: _history.take(_channels).map((q) => q.toList()).toList(),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _channelTable() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 5,
        childAspectRatio: 2.4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: List.generate(_channels, (i) {
          final q = _history[i];
          final current = q.isEmpty ? 0.0 : q.last;
          final minV = q.isEmpty ? 0.0 : q.reduce((a, b) => a < b ? a : b);
          final maxV = q.isEmpty ? 0.0 : q.reduce((a, b) => a > b ? a : b);
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: BioliminalTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border(
                left: BorderSide(color: _traceColor(i), width: 2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ch$i',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                  ),
                ),
                Text(
                  current.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${minV.toStringAsFixed(0)}/${maxV.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _rawPanel() {
    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.all(8),
      color: Colors.black.withValues(alpha: 0.5),
      child: SingleChildScrollView(
        child: Text(
          _lastRaw.isEmpty ? '(no packets)' : _hex(_lastRaw),
          style: const TextStyle(
            color: BioliminalTheme.accent,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

List<double> _decode(List<int> bytes, _Format fmt, int channels) {
  final width = fmt.byteWidth;
  final maxSamples = bytes.length ~/ width;
  final n = channels < maxSamples ? channels : maxSamples;
  final data = Uint8List.fromList(bytes).buffer.asByteData();
  final out = List<double>.filled(channels, 0);
  for (var i = 0; i < n; i++) {
    final off = i * width;
    out[i] = switch (fmt) {
      _Format.uint8 => data.getUint8(off).toDouble(),
      _Format.int8 => data.getInt8(off).toDouble(),
      _Format.uint16le => data.getUint16(off, Endian.little).toDouble(),
      _Format.uint16be => data.getUint16(off, Endian.big).toDouble(),
      _Format.int16le => data.getInt16(off, Endian.little).toDouble(),
      _Format.int16be => data.getInt16(off, Endian.big).toDouble(),
      _Format.float32le => data.getFloat32(off, Endian.little),
    };
  }
  return out;
}

Color _traceColor(int i) {
  const palette = [
    Color(0xFF38BDF8), // sky
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFFA78BFA), // violet
    Color(0xFFF472B6), // pink
    Color(0xFF22D3EE), // cyan
    Color(0xFFFACC15), // yellow
    Color(0xFF84CC16), // lime
    Color(0xFFFB923C), // orange
    Color(0xFF64B5F6),
    Color(0xFFE879F9),
    Color(0xFF4ADE80),
    Color(0xFFFBBF24),
    Color(0xFF2DD4BF),
    Color(0xFFF87171),
  ];
  return palette[i % palette.length];
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

class _MultiTracePainter extends CustomPainter {
  _MultiTracePainter({required this.traces});

  final List<List<double>> traces;

  @override
  void paint(Canvas canvas, Size size) {
    if (traces.isEmpty) return;

    double minV = double.infinity;
    double maxV = double.negativeInfinity;
    for (final t in traces) {
      for (final v in t) {
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
    }
    if (minV == double.infinity) return;
    if ((maxV - minV).abs() < 1e-6) {
      maxV = minV + 1;
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var ch = 0; ch < traces.length; ch++) {
      final data = traces[ch];
      if (data.length < 2) continue;
      final path = Path();
      for (var i = 0; i < data.length; i++) {
        final x = size.width * (i / (data.length - 1));
        final norm = (data[i] - minV) / (maxV - minV);
        final y = size.height * (1.0 - norm);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = _traceColor(ch).withValues(alpha: 0.9)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }

    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 9,
      fontFamily: 'monospace',
    );
    _drawText(canvas, maxV.toStringAsFixed(0), const Offset(4, 4), labelStyle);
    _drawText(
      canvas,
      minV.toStringAsFixed(0),
      Offset(4, size.height - 14),
      labelStyle,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MultiTracePainter old) => true;
}
