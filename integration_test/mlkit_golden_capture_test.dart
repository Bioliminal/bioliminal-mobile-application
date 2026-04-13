/// Runs reference images through MLKit's real PoseDetector on-device
/// and saves the landmark output as golden JSON fixtures.
///
/// Run on a real device or emulator:
///   flutter test integration_test/mlkit_golden_capture_test.dart
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:bioliminal/domain/models.dart' as models;

/// Reference images bundled as assets.
const _images = {
  'overhead_squat': 'assets/reference_images/overhead_squat.jpg',
  'single_leg_squat': 'assets/reference_images/single_leg_balance.jpg',
  'rollup': 'assets/reference_images/forward_fold.jpg',
  'push_up': 'assets/reference_images/overhead_reach.jpg',
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late PoseDetector detector;
  late Directory outputDir;
  late Directory tempImageDir;

  setUpAll(() async {
    detector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.single),
    );

    final appDir = await getApplicationDocumentsDirectory();
    outputDir = Directory('${appDir.path}/golden_landmarks');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    tempImageDir = Directory('${appDir.path}/temp_ref_images');
    if (!tempImageDir.existsSync()) {
      tempImageDir.createSync(recursive: true);
    }
  });

  tearDownAll(() async {
    detector.close();
    if (tempImageDir.existsSync()) {
      tempImageDir.deleteSync(recursive: true);
    }
  });

  for (final entry in _images.entries) {
    final movementName = entry.key;
    final assetPath = entry.value;

    testWidgets('capture golden landmarks: $movementName', (tester) async {
      // Copy asset to a real file path MLKit can read.
      final bytes = await rootBundle.load(assetPath);
      final tempFile = File('${tempImageDir.path}/$movementName.jpg');
      await tempFile.writeAsBytes(bytes.buffer.asUint8List());

      // Decode the image to get dimensions for normalization.
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final imgWidth = frame.image.width.toDouble();
      final imgHeight = frame.image.height.toDouble();
      frame.image.dispose();

      // Run MLKit pose detection.
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final poses = await detector.processImage(inputImage);

      expect(
        poses,
        isNotEmpty,
        reason: 'MLKit found no poses in $movementName',
      );
      expect(
        poses.length,
        1,
        reason:
            '$movementName: expected 1 pose, got ${poses.length}. '
            'Image may contain multiple people.',
      );

      final pose = poses.first;

      // Convert to normalized [0,1] Landmark format — same as
      // MlKitPoseEstimationService does for camera frames.
      final landmarks = PoseLandmarkType.values.map((type) {
        final lm = pose.landmarks[type];
        if (lm == null) {
          return const models.PoseLandmark(
            x: 0,
            y: 0,
            z: 0,
            visibility: 0,
            presence: 0,
          );
        }
        return models.PoseLandmark(
          x: lm.x / imgWidth,
          y: lm.y / imgHeight,
          z: lm.z,
          visibility: lm.likelihood,
          presence: lm.likelihood, // MLKit likelihood maps to visibility/presence
        );
      }).toList();

      // Verify we got meaningful landmarks (not all zeros).
      final visibleCount = landmarks.where((lm) => lm.visibility > 0.5).length;
      expect(
        visibleCount,
        greaterThan(10),
        reason:
            '$movementName: expected >10 visible landmarks, got $visibleCount',
      );

      // Save as JSON matching server ingestion schema so the same
      // fixtures test both the Flutter capture path and the server
      // pipeline (MotionBERT, HSMR, DTW).
      final output = {
        'metadata': {
          'movement': movementName,
          'source_image': assetPath,
          'image_width': imgWidth,
          'image_height': imgHeight,
          'model': 'mlkit_pose_detection',
          'captured_at': DateTime.now().toUtc().toIso8601String(),
        },
        'frames': [
          {
            'timestamp_ms': 0,
            'landmarks': landmarks.map((lm) => lm.toJson()).toList(),
          },
        ],
      };

      final file = File('${outputDir.path}/$movementName.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(output),
      );

      // ignore: avoid_print
      print(
        '[$movementName] ${imgWidth.toInt()}x${imgHeight.toInt()}, '
        '${landmarks.length} landmarks, $visibleCount visible, '
        'saved to ${file.path}',
      );
    });
  }

  testWidgets('verify all golden fixtures saved', (tester) async {
    final files = outputDir.listSync().whereType<File>().toList();
    expect(files.length, 4, reason: 'Expected 4 golden fixture files');

    for (final f in files) {
      // ignore: avoid_print
      print('Golden fixture: ${f.path}');
    }

    // ignore: avoid_print
    print(
      '\nTo pull fixtures off device:\n'
      '  adb pull ${outputDir.path}/ test/fixtures/golden_landmarks/\n'
      'Or for iOS, check the app container in Xcode.',
    );
  });
}
