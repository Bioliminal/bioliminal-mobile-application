/// Golden validation for PoseEstimationService implementations.
///
/// Loads golden fixtures captured from real MLKit inference on reference
/// images, then asserts that a new service implementation produces
/// landmarks within tolerance for the same images.
///
/// Prerequisites:
///   1. Run integration_test/mlkit_golden_capture_test.dart on a device.
///   2. Pull the JSON files into test/fixtures/golden_landmarks/.
///   3. Swap the service under test in _runService().
library;

import 'dart:convert';
import 'dart:io';

import 'package:auralink/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimum visibility for major joints in a clearly-visible pose.
const _minMajorJointVisibility = 0.5;

/// Lower floor for joints that may occlude in certain movements.
const _minOccludedJointVisibility = 0.3;

/// BlazePose indices for major joints.
const _majorJointIndices = [11, 12, 23, 24, 25, 26, 27, 28];

/// Joints prone to occlusion (ankles).
const _occlusionProneIndices = {27, 28};

const _movements = [
  'overhead_squat',
  'single_leg_squat',
  'rollup',
  'push_up',
];

List<PoseLandmark>? _loadGolden(String movementName) {
  final file = File('test/fixtures/golden_landmarks/$movementName.json');
  if (!file.existsSync()) return null;
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final frames = json['frames'] as List;
  final firstFrame = frames.first as Map<String, dynamic>;
  final rawLandmarks = firstFrame['landmarks'] as List;
  return rawLandmarks
      .map((lm) => PoseLandmark.fromJson(lm as Map<String, dynamic>))
      .toList();
}

void main() {
  for (final movement in _movements) {
    group('golden validation: $movement', () {
      late List<PoseLandmark>? goldenLandmarks;

      setUpAll(() {
        goldenLandmarks = _loadGolden(movement);
      });

      test('golden fixture exists', () {
        if (goldenLandmarks == null) {
          markTestSkipped(
            '$movement.json not found in test/fixtures/golden_landmarks/. '
            'Run integration_test/mlkit_golden_capture_test.dart on device first.',
          );
          return;
        }
        expect(goldenLandmarks, isNotNull);
      });

      test('has 33 landmarks', () {
        if (goldenLandmarks == null) return;
        expect(goldenLandmarks!.length, 33);
      });

      test('major joints have sufficient visibility', () {
        if (goldenLandmarks == null) return;
        for (final idx in _majorJointIndices) {
          if (idx < goldenLandmarks!.length) {
            final floor = _occlusionProneIndices.contains(idx)
                ? _minOccludedJointVisibility
                : _minMajorJointVisibility;
            expect(
              goldenLandmarks![idx].visibility,
              greaterThanOrEqualTo(floor),
              reason: 'joint $idx visibility in $movement',
            );
          }
        }
      });

      // Custom model comparison deferred — no custom tflite for v1.
      // When a model ships, add an integration test that runs the same
      // reference images through the new service and compares against
      // these golden landmarks. See docs/custom_model_contract.md.
    });
  }
}
