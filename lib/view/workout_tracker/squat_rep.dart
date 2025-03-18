import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'detector_view.dart';
import 'painters/pose_painter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SquatDetectorView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SquatDetectorViewState();
}

class _SquatDetectorViewState extends State<SquatDetectorView> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;

  // Counter for squats
  int _squatCount = 0;
  String _stage = 'up'; // Track the stage of the squat: 'up' or 'down'
  String _feedback = 'Start Squatting!'; // Feedback text for debugging

  // Stabilization variables
  double? _previousAngle;
  List<double> _angleHistory = [];
  static const int _historySize = 5; // Number of frames for averaging
  static const double _angleThreshold = 15.0; // Minimum angle change

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Squat Detector'),
      ),
      body: Stack(
        children: [
          DetectorView(
            title: 'Squat Detector',
            customPaint: _customPaint,
            text: _text,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) =>
                _cameraLensDirection = value,
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Squats: $_squatCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Feedback: $_feedback',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    final poses = await _poseDetector.processImage(inputImage);

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = PosePainter(
        poses,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);

      // Check for squats
      if (poses.isNotEmpty) {
        final pose = poses.first;
        if (pose.landmarks.containsKey(PoseLandmarkType.leftHip) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftKnee) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftAnkle)) {
          final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
          final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee]!;
          final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;

          // Log confidence levels
          debugPrint(
              'Confidence Levels -> Hip: ${leftHip.likelihood}, Knee: ${leftKnee.likelihood}, Ankle: ${leftAnkle.likelihood}');

          // Ensure confidence is above threshold
          if (leftHip.likelihood > 0.8 &&
              leftKnee.likelihood > 0.8 &&
              leftAnkle.likelihood > 0.8) {
            final angle = _calculateAngle(leftHip, leftKnee, leftAnkle);

            // Add values to history
            _addToHistory(_angleHistory, angle);

            // Count squat based on smoothed angle
            if (_isStable(_getSmoothedValue(_angleHistory))) {
              if (angle > 160 && _stage == 'down') {
                _stage = 'up';
                _feedback = 'Stand up!';
                debugPrint('Stage: Up | Feedback: Stand up!');
              } else if (angle < 90 && _stage == 'up') {
                _stage = 'down';
                _squatCount++;
                _feedback = 'Good squat!';
                debugPrint('Stage: Down | Feedback: Good squat!');
              }
            } else {
              _feedback = 'Unstable or insufficient movement.';
              debugPrint('Feedback: Unstable or insufficient movement.');
            }
          } else {
            _feedback = 'Landmarks confidence is too low!';
            debugPrint('Feedback: Landmarks confidence is too low!');
          }
        } else {
          _feedback = 'Position yourself properly!';
          debugPrint('Feedback: Position yourself properly!');
        }
      }
    } else {
      _text = 'Poses found: ${poses.length}\n\n';
      _customPaint = null;
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  bool _isStable(double smoothedAngle) {
    // Validate angle change
    if (_previousAngle != null &&
        (smoothedAngle - _previousAngle!).abs() < _angleThreshold) {
      debugPrint(
          'Angle change too small: ${(_previousAngle! - smoothedAngle).abs()}');
      return false;
    }

    // Update previous angle
    _previousAngle = smoothedAngle;

    return true;
  }

  double _calculateAngle(
      PoseLandmark hip, PoseLandmark knee, PoseLandmark ankle) {
    final a = Offset(hip.x, hip.y);
    final b = Offset(knee.x, knee.y);
    final c = Offset(ankle.x, ankle.y);

    final radians =
        (atan2(c.dy - b.dy, c.dx - b.dx) - atan2(a.dy - b.dy, a.dx - b.dx))
            .abs();
    var angle = radians * 180 / pi;
    if (angle > 180) angle = 360 - angle;

    debugPrint('Calculated Knee Angle: $angle');
    return angle;
  }

  void _addToHistory(List history, dynamic value) {
    history.add(value);
    if (history.length > _historySize) {
      history.removeAt(0);
    }
  }

  double _getSmoothedValue(List<double> history) {
    return history.reduce((a, b) => a + b) / history.length;
  }
}
