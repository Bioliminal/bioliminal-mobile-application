import 'package:bioliminal/core/services/capability_tier.dart';
import 'package:bioliminal/features/camera/services/pose_channel.dart';
import 'package:bioliminal/features/camera/services/pose_detector.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: deprecated_member_use
CameraImage _fakeCameraImage() => CameraImage.fromPlatformData({
      'format': 35, // YUV_420_888
      'height': 480,
      'width': 640,
      'planes': [
        {
          'bytes': Uint8List(640 * 480),
          'bytesPerRow': 640,
          'bytesPerPixel': 1,
        },
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MediaPipePoseDetector exposes the configured assetPath and delegate', () {
    final d = MediaPipePoseDetector(
      config: const PoseConfig(
        modelAssetPath: 'assets/models/pose_landmarker_heavy.task',
        delegate: PoseDelegate.coreml,
      ),
    );
    expect(d.assetPath, 'assets/models/pose_landmarker_heavy.task');
    expect(d.delegate, PoseDelegate.coreml);
  });

  test('initFailed=true and no retry when channel init returns false', () async {
    var initCalls = 0;
    final mockChannel = const MethodChannel(PoseChannel.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mockChannel, (call) async {
      if (call.method == 'initialize') {
        initCalls++;
        return false; // simulate missing asset / license not accepted
      }
      return null;
    });

    final detector = MediaPipePoseDetector(
      config: const PoseConfig(
        modelAssetPath: 'assets/models/does_not_exist.task',
        delegate: PoseDelegate.cpu,
      ),
      channel: PoseChannel(channel: mockChannel),
    );

    // First call — triggers init, gets false, returns empty.
    final result = await detector.processFrame(
      _fakeCameraImage(),
      rotationDegrees: 0,
    );
    expect(result, isEmpty);
    expect(detector.initFailed, isTrue);
    expect(initCalls, 1); // initialized exactly once

    // Second call — must fast-return without retrying init.
    await detector.processFrame(_fakeCameraImage(), rotationDegrees: 0);
    expect(initCalls, 1); // still no retry

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mockChannel, null);
  });
}
