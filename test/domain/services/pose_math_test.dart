import 'package:flutter_test/flutter_test.dart';

import 'package:bioliminal/domain/services/pose_math.dart';

void main() {
  group('rotationDegreesForSensor', () {
    test('back camera returns sensor orientation unchanged', () {
      expect(rotationDegreesForSensor(0, isFrontCamera: false), 0);
      expect(rotationDegreesForSensor(90, isFrontCamera: false), 90);
      expect(rotationDegreesForSensor(180, isFrontCamera: false), 180);
      expect(rotationDegreesForSensor(270, isFrontCamera: false), 270);
    });

    test('front camera mirrors the rotation', () {
      // (360 - orientation) % 360
      expect(rotationDegreesForSensor(0, isFrontCamera: true), 0);
      expect(rotationDegreesForSensor(90, isFrontCamera: true), 270);
      expect(rotationDegreesForSensor(180, isFrontCamera: true), 180);
      expect(rotationDegreesForSensor(270, isFrontCamera: true), 90);
    });

    test('front camera with 360 wraps to 0', () {
      expect(rotationDegreesForSensor(360, isFrontCamera: true), 0);
    });
  });

  group('normalizeLandmark', () {
    test('normalizes x and y to [0,1] range', () {
      final lm = normalizeLandmark(
        x: 320,
        y: 240,
        z: 1.5,
        visibility: 0.95,
        presence: 0.99,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(lm.x, closeTo(0.5, 1e-10));
      expect(lm.y, closeTo(0.5, 1e-10));
      expect(lm.z, closeTo(1.5 / 640, 1e-10));
      expect(lm.visibility, closeTo(0.95, 1e-10));
      expect(lm.presence, closeTo(0.99, 1e-10));
    });

    test('origin landmark normalizes to (0, 0)', () {
      final lm = normalizeLandmark(
        x: 0,
        y: 0,
        z: 0,
        visibility: 1.0,
        presence: 1.0,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(lm.x, closeTo(0.0, 1e-10));
      expect(lm.y, closeTo(0.0, 1e-10));
    });

    test('bottom-right corner normalizes to (1, 1)', () {
      final lm = normalizeLandmark(
        x: 640,
        y: 480,
        z: 0,
        visibility: 1.0,
        presence: 1.0,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(lm.x, closeTo(1.0, 1e-10));
      expect(lm.y, closeTo(1.0, 1e-10));
    });

    test('null x/y produces zero-visibility landmark', () {
      final lm = normalizeLandmark(
        x: null,
        y: null,
        z: null,
        visibility: null,
        presence: null,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(lm.x, 0.0);
      expect(lm.y, 0.0);
      expect(lm.z, 0.0);
      expect(lm.visibility, 0.0);
      expect(lm.presence, 0.0);
    });

    test('null x alone produces zero landmark', () {
      final lm = normalizeLandmark(
        x: null,
        y: 240,
        z: 1.0,
        visibility: 0.9,
        presence: 0.9,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(lm.x, 0.0);
      expect(lm.y, 0.0);
      expect(lm.visibility, 0.0);
      expect(lm.presence, 0.0);
    });

    test('null z defaults to 0', () {
      final lm = normalizeLandmark(
        x: 320,
        y: 240,
        z: null,
        visibility: 0.8,
        presence: 0.8,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(lm.z, 0.0);
      expect(lm.x, closeTo(0.5, 1e-10));
    });

    test('null visibility defaults to 0', () {
      final lm = normalizeLandmark(
        x: 320,
        y: 240,
        z: 1.0,
        visibility: null,
        presence: 0.8,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(lm.visibility, 0.0);
      expect(lm.x, closeTo(0.5, 1e-10));
    });
  });

  group('normalizeRawLandmarks', () {
    test('normalizes a batch of landmarks', () {
      final landmarks = normalizeRawLandmarks(
        raw: [
          (x: 0.0, y: 0.0, z: 0.0, visibility: 0.9, presence: 0.9),
          (x: 640.0, y: 480.0, z: 1.0, visibility: 0.8, presence: 0.8),
          (x: 320.0, y: 240.0, z: 0.5, visibility: 0.95, presence: 0.95),
        ],
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(landmarks.length, 3);
      expect(landmarks[0].x, closeTo(0.0, 1e-10));
      expect(landmarks[0].y, closeTo(0.0, 1e-10));
      expect(landmarks[1].x, closeTo(1.0, 1e-10));
      expect(landmarks[1].y, closeTo(1.0, 1e-10));
      expect(landmarks[2].x, closeTo(0.5, 1e-10));
      expect(landmarks[2].y, closeTo(0.5, 1e-10));
    });

    test('handles missing landmarks in batch', () {
      final landmarks = normalizeRawLandmarks(
        raw: [
          (x: 320.0, y: 240.0, z: 0.0, visibility: 0.9, presence: 0.9),
          (x: null, y: null, z: null, visibility: null, presence: null),
          (x: 160.0, y: 120.0, z: 0.0, visibility: 0.7, presence: 0.7),
        ],
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(landmarks.length, 3);
      expect(landmarks[0].x, closeTo(0.5, 1e-10));
      // Null entry → zero landmark.
      expect(landmarks[1].x, 0.0);
      expect(landmarks[1].visibility, 0.0);
      expect(landmarks[2].x, closeTo(0.25, 1e-10));
    });

    test('empty input produces empty output', () {
      final landmarks = normalizeRawLandmarks(
        raw: [],
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(landmarks, isEmpty);
    });

    test('33 landmarks (BlazePose count) normalizes correctly', () {
      final raw = List.generate(
        33,
        (i) => (x: i * 20.0, y: i * 15.0, z: 0.0, visibility: 0.9, presence: 0.9),
      );

      final landmarks = normalizeRawLandmarks(
        raw: raw,
        imageWidth: 640,
        imageHeight: 480,
      );

      expect(landmarks.length, 33);
      // Spot check: landmark 16 → x = 320/640 = 0.5, y = 240/480 = 0.5
      expect(landmarks[16].x, closeTo(320 / 640, 1e-10));
      expect(landmarks[16].y, closeTo(240 / 480, 1e-10));
    });
  });
}
