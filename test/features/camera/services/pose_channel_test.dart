import 'package:bioliminal/features/camera/services/pose_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel channel;
  late PoseChannel poseChannel;
  late List<MethodCall> calls;
  late dynamic Function(MethodCall call) handler;

  setUp(() {
    channel = const MethodChannel(PoseChannel.channelName);
    poseChannel = PoseChannel(channel: channel);
    calls = <MethodCall>[];
    handler = (_) async => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('initialize', () {
    test('initialize sends {assetPath, delegate} to native', () async {
      final captured = <dynamic>[];
      const mock = MethodChannel('bioliminal.app/pose');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(mock, (call) async {
        captured.add(call.arguments);
        return true;
      });
      final channel = PoseChannel(channel: mock);
      final ok = await channel.initialize(
        assetPath: 'assets/models/pose_landmarker_full.task',
        delegate: 'coreml',
      );
      expect(ok, isTrue);
      expect(captured.single, {
        'assetPath': 'assets/models/pose_landmarker_full.task',
        'delegate': 'coreml',
      });
    });

    test('returns false when native returns null', () async {
      handler = (_) async => null;
      final ok = await poseChannel.initialize(
        assetPath: 'irrelevant',
        delegate: 'cpu',
      );
      expect(ok, isFalse);
    });
  });

  group('processFrame', () {
    test('forwards payload and parses 33-landmark response', () async {
      final landmarks = List.generate(
        33,
        (i) => {
          'x': i * 0.01,
          'y': i * 0.02,
          'z': i * 0.03,
          'visibility': 0.9,
          'presence': 0.8,
        },
      );
      handler = (_) async => landmarks;

      final bytes = Uint8List.fromList(List.filled(640 * 480, 128));
      final result = await poseChannel.processFrame(
        bytes: bytes,
        width: 640,
        height: 480,
        bytesPerRow: 640,
        rotationDegrees: 90,
        timestampMs: 1234567890,
      );

      expect(result, hasLength(33));
      expect(result.first['x'], 0.0);
      expect(result.last['y'], closeTo(32 * 0.02, 1e-9));
      expect(result.first['visibility'], 0.9);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'processFrame');
      final args = calls.single.arguments as Map;
      expect(args['width'], 640);
      expect(args['height'], 480);
      expect(args['bytesPerRow'], 640);
      expect(args['rotationDegrees'], 90);
      expect(args['timestampMs'], 1234567890);
      expect(args['bytes'], isA<Uint8List>());
      expect((args['bytes'] as Uint8List).length, bytes.length);
    });

    test('returns empty list when native returns null (no pose detected)',
        () async {
      handler = (_) async => null;
      final bytes = Uint8List(0);
      final result = await poseChannel.processFrame(
        bytes: bytes,
        width: 1,
        height: 1,
        bytesPerRow: 1,
        rotationDegrees: 0,
        timestampMs: 0,
      );
      expect(result, isEmpty);
    });

    test('coerces ints in landmark response to doubles', () async {
      // Native channels can serialize 0.0 as int 0 — must not throw.
      handler = (_) async => List.generate(
        33,
        (_) => {'x': 0, 'y': 1, 'z': 0, 'visibility': 1, 'presence': 1},
      );
      final result = await poseChannel.processFrame(
        bytes: Uint8List(0),
        width: 1,
        height: 1,
        bytesPerRow: 1,
        rotationDegrees: 0,
        timestampMs: 0,
      );
      expect(result.first['x'], 0.0);
      expect(result.first['y'], 1.0);
      expect(result.first['x'], isA<double>());
    });
  });

  test('dispose forwards to native', () async {
    await poseChannel.dispose();
    expect(calls.single.method, 'dispose');
    expect(calls.single.arguments, isNull);
  });
}
