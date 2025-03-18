import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'detector_view.dart';
import 'package:video_player/video_player.dart';
import 'painters/pose_painter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;

  // Counter for curls
  int _curlCount = 0;
  String _stage = 'down'; // Track the stage of the curl: 'up' or 'down'
  String _feedback = 'Start Curling!'; // Feedback text for debugging

  // Stabilization variables
  double? _previousAngle;
  double? _previousWristY;
  List<double> _angleHistory = [];
  List<double> _wristYHistory = [];
  List<Offset> _shoulderHistory = [];
  DateTime? _lastStableTime;

  // Configuration
  static const int _historySize = 5; // Number of frames for averaging
  static const double _verticalThreshold = 15.0; // Minimum wrist movement
  static const double _angleThreshold = 15.0; // Minimum angle change
  static const int _stabilityDuration = 200; // Stability duration in ms
  static const double _shoulderMovementThreshold =
      5.0; // Max allowed shoulder displacement
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
        title: const Text('Pose Detector'),
      ),
      body: Stack(
        children: [
          DetectorView(
            title: 'Pose Detector',
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
                  'Curls: $_curlCount',
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

      // Check for dumbbell curl
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
          if (leftShoulder.likelihood > 0.75 &&
              leftElbow.likelihood > 0.75 &&
              leftWrist.likelihood > 0.75) {
            final angle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
            final wristY = leftWrist.y;

            // Add values to history
            _addToHistory(_angleHistory, angle);
            _addToHistory(_wristYHistory, wristY);
            _addToHistory(
                _shoulderHistory, Offset(leftShoulder.x, leftShoulder.y));

            // Validate shoulder stability
            if (!_isShoulderStable()) {
              _feedback = 'Keep your shoulder stable!';
              debugPrint('Feedback: Shoulder movement exceeds threshold.');
              _isBusy = false;
              setState(() {});
              return;
            }

            // Validate motion and stability
            if (_isStable(_getSmoothedValue(_angleHistory),
                _getSmoothedValue(_wristYHistory), DateTime.now())) {
              // Count rep based on smoothed angle
              if (angle > 150 && _stage == 'up') {
                _stage = 'down';
                _feedback = 'Lower the weights!';
                debugPrint('Stage: Down | Feedback: Lower the weights!');
              } else if (angle < 50 && _stage == 'down') {
                _stage = 'up';
                _curlCount++;
                _feedback = 'Good form! Rep counted!';
                debugPrint('Stage: Up | Feedback: Good form! Rep counted!');
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

  bool _isShoulderStable() {
    if (_shoulderHistory.length < _historySize) {
      return true; // Not enough data to assess stability
    }

    final recentShoulders =
        _shoulderHistory.sublist(_shoulderHistory.length - _historySize);
    final avgX = recentShoulders.map((s) => s.dx).reduce((a, b) => a + b) /
        recentShoulders.length;
    final avgY = recentShoulders.map((s) => s.dy).reduce((a, b) => a + b) /
        recentShoulders.length;

    final lastShoulder = recentShoulders.last;

    final xDiff = (lastShoulder.dx - avgX).abs();
    final yDiff = (lastShoulder.dy - avgY).abs();

    debugPrint('Shoulder Stability -> X Diff: $xDiff, Y Diff: $yDiff');

    return xDiff < _shoulderMovementThreshold &&
        yDiff < _shoulderMovementThreshold;
  }

  bool _isStable(double smoothedAngle, double smoothedWristY, DateTime now) {
    // Validate wrist vertical movement
    if (_previousWristY != null &&
        (smoothedWristY - _previousWristY!).abs() < _verticalThreshold) {
      debugPrint(
          'Vertical motion too small: ${(_previousWristY! - smoothedWristY).abs()}');
      return false;
    }

    // Validate angle change
    if (_previousAngle != null &&
        (smoothedAngle - _previousAngle!).abs() < _angleThreshold) {
      debugPrint(
          'Angle change too small: ${(_previousAngle! - smoothedAngle).abs()}');
      return false;
    }

    // Validate stability duration
    if (_lastStableTime != null &&
        now.difference(_lastStableTime!).inMilliseconds < _stabilityDuration) {
      debugPrint(
          'Movement not stable enough. Time since last stable: ${now.difference(_lastStableTime!).inMilliseconds}ms');
      return false;
    }

    // Update last stable time and previous values
    _lastStableTime = now;
    _previousAngle = smoothedAngle;
    _previousWristY = smoothedWristY;

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
