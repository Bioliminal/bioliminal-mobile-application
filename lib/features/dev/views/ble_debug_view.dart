import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:bioliminal/core/services/sample_batch.dart';
import 'package:bioliminal/core/theme.dart';
import 'package:bioliminal/features/dev/views/ble_live_view.dart';

// Hardware-dev-facing BLE bring-up tool. Not wired to HardwareController —
// lets the dev inspect any service/characteristic since the Bioliminal
// GATT mapping isn't finalized.

class BleDebugView extends StatefulWidget {
  const BleDebugView({super.key});

  @override
  State<BleDebugView> createState() => _BleDebugViewState();
}

class _BleDebugViewState extends State<BleDebugView> {
  final List<ScanResult> _results = [];
  final List<_LogEntry> _log = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _isScanning = false;
  bool _filterNamedOnly = true;
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _adapterSub = FlutterBluePlus.adapterState.listen((s) {
      if (!mounted) return;
      setState(() => _adapterState = s);
      _logLine('adapter', s.name);
    });
    _isScanningSub = FlutterBluePlus.isScanning.listen((s) {
      if (!mounted) return;
      setState(() => _isScanning = s);
    });
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _results
          ..clear()
          ..addAll(results);
      });
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    _adapterSub?.cancel();
    FlutterBluePlus.stopScan();
    _selectedDevice?.disconnect();
    super.dispose();
  }

  Future<void> _startScan() async {
    _logLine('scan', 'start');
    if (mounted) setState(_results.clear);
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      _logLine('error', 'startScan: $e');
    }
  }

  Future<void> _stopScan() async {
    _logLine('scan', 'stop');
    await FlutterBluePlus.stopScan();
  }

  Future<void> _connect(BluetoothDevice device) async {
    _logLine('connect', '${device.platformName} (${device.remoteId})');
    await FlutterBluePlus.stopScan();
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _selectedDevice = device);
      _logLine('connect', 'OK');
    } catch (e) {
      _logLine('error', 'connect: $e');
    }
  }

  Future<void> _disconnect() async {
    final d = _selectedDevice;
    if (d == null) return;
    _logLine('disconnect', d.remoteId.str);
    try {
      await d.disconnect();
    } catch (e) {
      _logLine('error', 'disconnect: $e');
    }
    if (!mounted) return;
    setState(() => _selectedDevice = null);
  }

  void _logLine(String tag, String msg) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, _LogEntry(DateTime.now(), tag, msg));
      if (_log.length > 500) _log.removeLast();
    });
  }

  Future<void> _copyLog() async {
    final text = _log.reversed
        .map((e) => '${e.time.toIso8601String()} [${e.tag}] ${e.message}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioliminalTheme.screenBackground,
      appBar: AppBar(
        title: Text(_selectedDevice == null ? 'BLE DEBUG' : 'DEVICE'),
        leading: _selectedDevice != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _disconnect,
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Copy log',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyLog,
          ),
          IconButton(
            tooltip: 'Clear log',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(_log.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          if (kIsWeb) _webBanner(),
          _adapterBar(),
          Expanded(
            child: _selectedDevice == null
                ? _scanList()
                : _DeviceDetail(
                    device: _selectedDevice!,
                    onLog: _logLine,
                  ),
          ),
          _logPanel(),
        ],
      ),
    );
  }

  Widget _webBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: BioliminalTheme.confidenceMedium.withValues(alpha: 0.15),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: BioliminalTheme.confidenceMedium,
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Web Bluetooth: Chrome/Edge only, HTTPS or localhost. '
              'Scan opens Chrome\u2019s device picker — the list below, RSSI, '
              'and manufacturer data won\u2019t populate. MTU negotiation is '
              'unsupported. For full bring-up, run on a physical Android device.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adapterBar() {
    final on = _adapterState == BluetoothAdapterState.on;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: BioliminalTheme.surface,
      child: Row(
        children: [
          Icon(
            on ? Icons.bluetooth : Icons.bluetooth_disabled,
            color: on ? BioliminalTheme.accent : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Adapter: ${_adapterState.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          if (_selectedDevice == null) ...[
            Text(
              '${_results.length} found',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _isScanning ? _stopScan : _startScan,
              icon: Icon(
                _isScanning ? Icons.stop : Icons.search,
                size: 16,
              ),
              label: Text(_isScanning ? 'Stop' : 'Scan'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scanList() {
    final filtered = _filterNamedOnly
        ? _results.where((r) => r.device.platformName.isNotEmpty).toList()
        : _results;
    filtered.sort((a, b) => b.rssi.compareTo(a.rssi));

    return Column(
      children: [
        SwitchListTile(
          title: const Text(
            'Named devices only',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          dense: true,
          value: _filterNamedOnly,
          onChanged: (v) => setState(() => _filterNamedOnly = v),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _isScanning ? 'Scanning…' : 'Tap Scan to discover devices',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, i) => _scanTile(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _scanTile(ScanResult r) {
    final name = r.device.platformName.isEmpty ? '(no name)' : r.device.platformName;
    final adv = r.advertisementData;
    final services = adv.serviceUuids.map((u) => u.str128).join(', ');
    final mfg = adv.manufacturerData.entries
        .map((e) => '0x${e.key.toRadixString(16)}:${_hex(e.value)}')
        .join(' ');

    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          _rssiBadge(r.rssi),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.device.remoteId.str,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          if (services.isNotEmpty)
            Text(
              'svcs: $services',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          if (mfg.isNotEmpty)
            Text(
              'mfg: $mfg',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          Text(
            'connectable: ${adv.connectable}  •  txPower: ${adv.txPowerLevel ?? "—"}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: adv.connectable ? () => _connect(r.device) : null,
        child: const Text('Connect'),
      ),
    );
  }

  Widget _rssiBadge(int rssi) {
    final color = rssi > -60
        ? BioliminalTheme.confidenceHigh
        : rssi > -80
            ? BioliminalTheme.confidenceMedium
            : BioliminalTheme.confidenceLow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$rssi dBm',
        style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }

  Widget _logPanel() {
    return Container(
      height: 140,
      color: Colors.black.withValues(alpha: 0.4),
      child: ListView.builder(
        reverse: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _log.length,
        itemBuilder: (context, i) {
          final e = _log[i];
          return Text(
            '${_fmtTime(e.time)} [${e.tag}] ${e.message}',
            style: TextStyle(
              color: e.tag == 'error' ? Colors.redAccent : Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          );
        },
      ),
    );
  }
}

class _DeviceDetail extends StatefulWidget {
  const _DeviceDetail({required this.device, required this.onLog});

  final BluetoothDevice device;
  final void Function(String tag, String message) onLog;

  @override
  State<_DeviceDetail> createState() => _DeviceDetailState();
}

class _DeviceDetailState extends State<_DeviceDetail> {
  List<BluetoothService> _services = [];
  int _mtu = 23;
  BluetoothConnectionState _connState = BluetoothConnectionState.disconnected;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<int>? _mtuSub;
  bool _discovering = false;

  @override
  void initState() {
    super.initState();
    _connSub = widget.device.connectionState.listen((s) {
      setState(() => _connState = s);
      widget.onLog('state', s.name);
    });
    _mtuSub = widget.device.mtu.listen((m) {
      setState(() => _mtu = m);
    });
    _discover();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _mtuSub?.cancel();
    super.dispose();
  }

  Future<void> _discover() async {
    setState(() => _discovering = true);
    try {
      final s = await widget.device.discoverServices();
      setState(() => _services = s);
      widget.onLog('discover', '${s.length} services');
    } catch (e) {
      widget.onLog('error', 'discover: $e');
    } finally {
      setState(() => _discovering = false);
    }
  }

  Future<void> _requestMtu() async {
    try {
      final m = await widget.device.requestMtu(247);
      widget.onLog('mtu', 'negotiated $m');
    } catch (e) {
      widget.onLog('error', 'mtu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: BioliminalTheme.surface.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.platformName.isEmpty ? '(no name)' : d.platformName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d.remoteId.str,
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _chip('state', _connState.name),
                  _chip('mtu', '$_mtu'),
                  TextButton(
                    onPressed: _requestMtu,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Request 247'),
                  ),
                  TextButton.icon(
                    onPressed: _discover,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Re-discover'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_discovering)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_services.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No services discovered',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          ..._services.map(
            (s) => _ServiceTile(
              service: s,
              device: widget.device,
              onLog: widget.onLog,
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BioliminalTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.device,
    required this.onLog,
  });

  final BluetoothService service;
  final BluetoothDevice device;
  final void Function(String tag, String message) onLog;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'Service  ${service.uuid.str128}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Text(
          service.isPrimary ? 'primary' : 'secondary',
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        children: service.characteristics
            .map(
              (c) =>
                  _CharTile(characteristic: c, device: device, onLog: onLog),
            )
            .toList(),
      ),
    );
  }
}

class _CharTile extends StatefulWidget {
  const _CharTile({
    required this.characteristic,
    required this.device,
    required this.onLog,
  });

  final BluetoothCharacteristic characteristic;
  final BluetoothDevice device;
  final void Function(String tag, String message) onLog;

  @override
  State<_CharTile> createState() => _CharTileState();
}

class _CharTileState extends State<_CharTile> {
  StreamSubscription<List<int>>? _valueSub;
  List<int>? _lastValue;
  int _packetCount = 0;
  DateTime? _firstPacketAt;
  bool _subscribed = false;
  final _writeCtrl = TextEditingController();

  @override
  void dispose() {
    _valueSub?.cancel();
    _writeCtrl.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    try {
      final v = await widget.characteristic.read();
      if (!mounted) return;
      setState(() => _lastValue = v);
      widget.onLog('read', '${widget.characteristic.uuid.str} → ${_hex(v)}');
    } catch (e) {
      widget.onLog('error', 'read: $e');
    }
  }

  Future<void> _toggleSubscribe() async {
    if (_subscribed) {
      await widget.characteristic.setNotifyValue(false);
      await _valueSub?.cancel();
      if (!mounted) return;
      setState(() {
        _subscribed = false;
        _valueSub = null;
      });
      widget.onLog('notify', 'off ${widget.characteristic.uuid.str}');
      return;
    }
    try {
      await widget.characteristic.setNotifyValue(true);
      _valueSub = widget.characteristic.lastValueStream.listen((v) {
        if (!mounted) return;
        setState(() {
          _lastValue = v;
          _packetCount++;
          _firstPacketAt ??= DateTime.now();
        });
      });
      if (!mounted) return;
      setState(() => _subscribed = true);
      widget.onLog('notify', 'on ${widget.characteristic.uuid.str}');
    } catch (e) {
      widget.onLog('error', 'subscribe: $e');
    }
  }

  Future<void> _write() async {
    final bytes = _parseHex(_writeCtrl.text);
    if (bytes == null) {
      widget.onLog('error', 'invalid hex');
      return;
    }
    try {
      final withResponse = widget.characteristic.properties.write;
      await widget.characteristic.write(bytes, withoutResponse: !withResponse);
      widget.onLog(
        'write',
        '${widget.characteristic.uuid.str} ← ${_hex(bytes)}',
      );
    } catch (e) {
      widget.onLog('error', 'write: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.characteristic.properties;
    final flags = [
      if (p.read) 'R',
      if (p.write) 'W',
      if (p.writeWithoutResponse) 'Wn',
      if (p.notify) 'N',
      if (p.indicate) 'I',
    ].join(' ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BioliminalTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.characteristic.uuid.str128,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: BioliminalTheme.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  flags.isEmpty ? '—' : flags,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_lastValue != null) ...[
            Text(
              'hex  ${_hex(_lastValue!)}',
              style: const TextStyle(
                color: BioliminalTheme.accent,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'ascii  ${_ascii(_lastValue!)}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            if (_subscribed)
              Text(
                _firstPacketAt != null
                    ? 'packets  $_packetCount   (~${_throughputHz(_packetCount, _firstPacketAt!).toStringAsFixed(1)} Hz)'
                    : 'packets  $_packetCount',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            if (_lastValue!.length == SampleBatch.packetSize) ...[
              const SizedBox(height: 6),
              _SampleBatchPreview(bytes: _lastValue!),
            ],
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (p.read)
                OutlinedButton(onPressed: _read, child: const Text('Read')),
              if (p.notify || p.indicate)
                OutlinedButton(
                  onPressed: _toggleSubscribe,
                  child: Text(_subscribed ? 'Unsubscribe' : 'Subscribe'),
                ),
              if (p.notify || p.indicate)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BleLiveView(
                          device: widget.device,
                          characteristic: widget.characteristic,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.show_chart, size: 14),
                  label: const Text('Live'),
                ),
              if (p.write || p.writeWithoutResponse)
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _writeCtrl,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'hex (e.g. 01 ff a0)',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 11),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              if (p.write || p.writeWithoutResponse)
                OutlinedButton(onPressed: _write, child: const Text('Write')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decoded view of a 308-byte FF02 packet. Lights up only when the payload
/// matches the v0 wire format — useful for verifying real firmware output
/// against the spec without leaving the app.
class _SampleBatchPreview extends StatelessWidget {
  const _SampleBatchPreview({required this.bytes});

  final List<int> bytes;

  @override
  Widget build(BuildContext context) {
    final batch = SampleBatch.decode(bytes);
    if (batch == null) {
      return const Text(
        'decoded  — (308 B but layout mismatch)',
        style: TextStyle(
          color: Colors.orangeAccent,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      );
    }
    String head(List<int> ch) => ch.take(4).join(', ');
    final clipFlags = [
      if (batch.clipRaw) 'RAW',
      if (batch.clipRect) 'RECT',
      if (batch.clipEnv) 'ENV',
    ].join('+');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SampleBatch  seq=${batch.seqNum}  t_us=${batch.tUsStart}  '
            '${batch.channelCount}ch×${batch.samplesPerChannel}',
            style: const TextStyle(
              color: BioliminalTheme.accent,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'raw[0..3]   ${head(batch.raw)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'rect[0..3]  ${head(batch.rect)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'env[0..3]   ${head(batch.env)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          if (batch.clippedAny)
            Text(
              'CLIP  $clipFlags',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }
}

class _LogEntry {
  _LogEntry(this.time, this.tag, this.message);
  final DateTime time;
  final String tag;
  final String message;
}

double _throughputHz(int count, DateTime since) {
  final elapsed = DateTime.now().difference(since).inMilliseconds / 1000.0;
  if (elapsed < 0.1 || count < 2) return 0;
  return (count - 1) / elapsed;
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

String _ascii(List<int> bytes) {
  try {
    return ascii.decode(
      bytes.map((b) => (b >= 32 && b < 127) ? b : 0x2E).toList(),
    );
  } catch (_) {
    return '';
  }
}

List<int>? _parseHex(String s) {
  final cleaned = s.replaceAll(RegExp(r'[\s,]'), '').toLowerCase();
  if (cleaned.isEmpty || cleaned.length.isOdd) return null;
  final out = <int>[];
  for (var i = 0; i < cleaned.length; i += 2) {
    final byte = int.tryParse(cleaned.substring(i, i + 2), radix: 16);
    if (byte == null) return null;
    out.add(byte);
  }
  return out;
}

String _fmtTime(DateTime t) {
  two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
}
