import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PredictionService {
  late Interpreter _interpreter;
  late List<String> _labels;
  bool isInitialized = false; // Publicly accessible initialization status

  PredictionService() {
    _initialize();
  }

  // Initialize the TensorFlow Lite model and labels
  Future<void> _initialize() async {
    try {
      print("Loading TensorFlow Lite model...");
      _interpreter = await Interpreter.fromAsset('mobilenet_fruits360_model.tflite');
      print("Model loaded successfully!");

      print("Loading labels...");
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').where((label) => label.isNotEmpty).toList(); // Remove empty lines
      print("Labels loaded successfully: $_labels");

      isInitialized = true; // Indicate that initialization is complete
    } catch (e) {
      print("Error loading model or labels: $e");
      isInitialized = false; // Ensure the state reflects initialization failure
    }
  }

  // Predict the class of an image
  Future<String> predict(Uint8List imageBytes) async {
    if (!isInitialized) {
      return "Model and labels not initialized!";
    }

    try {
      // Decode the image
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) throw Exception("Error decoding image!");

      // Resize the image to the input size of the model (300x300)
      img.Image resizedImage = img.copyResize(decodedImage, width: 300, height: 300);

      // Normalize the image to [0, 1]
      List<List<List<double>>> input = List.generate(
        300,
        (y) => List.generate(
          300,
          (x) => [
            ((resizedImage.getPixel(x, y) >> 16) & 0xFF) / 255.0, // Red
            ((resizedImage.getPixel(x, y) >> 8) & 0xFF) / 255.0,  // Green
            (resizedImage.getPixel(x, y) & 0xFF) / 255.0,         // Blue
          ],
        ),
      );

      // Prepare input tensor
      var inputTensor = [input];

      // Prepare output tensor
      var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

      // Perform inference
      _interpreter.run(inputTensor, output);

      // Get the predicted label
      int predictedIndex = output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));
      print("Prediction successful: ${_labels[predictedIndex]}");
      return _labels[predictedIndex];
    } catch (e) {
      print("Error during prediction: $e");
      return "Prediction error!";
    }
  }

  // Close the interpreter
  void closeInterpreter() {
    _interpreter.close();
    print("Interpreter closed.");
  }
}
