import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'detector_view.dart';
import 'painters/pose_painter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class ShoulderPressDetectorView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ShoulderPressDetectorViewState();
}

class _ShoulderPressDetectorViewState extends State<ShoulderPressDetectorView> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  // Counter for shoulder presses
  int _pressCount = 0;
  String _stage = 'down'; // Track the stage of the press: 'up' or 'down'
  String _feedback = 'Start Pressing!'; // Feedback text for debugging

  // Stabilization variables
  double? _previousAngle;
  List<double> _angleHistory = [];
  static const int _historySize = 5; // Number of frames for averaging
  static const double _angleThreshold = 15.0; // Minimum angle change

  late VideoPlayerController _videoController;
  bool _isVideoPlaying = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/bicep_curl.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {}); // Ensures UI updates
          _videoController.setLooping(true);
          _videoController.play();
        }
      });
  }

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoulder Press Detector'),
      ),
      body: Stack(
        children: [
          DetectorView(
            title: 'Shoulder Press Detector',
            customPaint: _customPaint,
            text: _text,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) =>
                _cameraLensDirection = value,
          ),
          if (_isVideoPlaying && _videoController.value.isInitialized)
            Positioned.fill(
              child: Stack(
                children: [
                  VideoPlayer(_videoController),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: Icon(Icons.close, size: 32, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isVideoPlaying = false;
                          _videoController.pause();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shoulder Presses: $_pressCount',
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

      // Check for shoulder presses
      if (poses.isNotEmpty) {
        final pose = poses.first;
        if (pose.landmarks.containsKey(PoseLandmarkType.leftShoulder) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftElbow) &&
            pose.landmarks.containsKey(PoseLandmarkType.leftWrist)) {
          final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
          final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow]!;
          final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]!;

          // Log confidence levels
          debugPrint(
              'Confidence Levels -> Shoulder: ${leftShoulder.likelihood}, Elbow: ${leftElbow.likelihood}, Wrist: ${leftWrist.likelihood}');

          // Ensure confidence is above threshold
          if (leftShoulder.likelihood > 0.8 &&
              leftElbow.likelihood > 0.8 &&
              leftWrist.likelihood > 0.8) {
            final angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);

            // Add values to history
            _addToHistory(_angleHistory, angle);

            // Count shoulder press based on smoothed angle
            if (_isStable(_getSmoothedValue(_angleHistory))) {
              if (angle > 160 && _stage == 'down') {
                _stage = 'up';
                _feedback = 'Press up!';
                debugPrint('Stage: Up | Feedback: Press up!');
              } else if (angle < 90 && _stage == 'up') {
                _stage = 'down';
                _pressCount++;
                _feedback = 'Good press!';
                debugPrint('Stage: Down | Feedback: Good press!');
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
      PoseLandmark shoulder, PoseLandmark elbow, PoseLandmark wrist) {
    final a = Offset(shoulder.x, shoulder.y);
    final b = Offset(elbow.x, elbow.y);
    final c = Offset(wrist.x, wrist.y);

    final radians =
        (atan2(c.dy - b.dy, c.dx - b.dx) - atan2(a.dy - b.dy, a.dx - b.dx))
            .abs();
    var angle = radians * 180 / pi;
    if (angle > 180) angle = 360 - angle;

    debugPrint('Calculated Elbow Angle: $angle');
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
