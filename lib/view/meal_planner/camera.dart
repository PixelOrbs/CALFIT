import 'dart:io';
import 'dart:typed_data';
import 'package:fitness/common/colo_extension.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; 
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late Interpreter _interpreter;
  late ImagePicker _imagePicker;
  File? _selectedImage;
  String _classificationResult = "No result yet";
  bool _isLoading = false;
  bool _isInterpreterInitialized = false;

  final Map<String, double> _caloriesPerGram = {
    'apple_6': 0.53,
    'apple_braeburn_1': 0.53,
    'apple_crimson_snow_1': 0.53,
    'apple_golden_1': 0.53,
    'apple_golden_2': 0.53,
    'apple_golden_3': 0.53,
    'apple_granny_smith_1': 0.53,
    'apple_hit_1': 0.53,
    'apple_pink_lady_1': 0.53,
    'apple_red_1': 0.53,
    'apple_red_2': 0.53,
    'apple_red_3': 0.53,
    'apple_red_delicious_1': 0.53,
    'apple_red_yellow_1': 0.53,
    'apple_rotten_1': 0.0,
    'cabbage_white_1': 0.25,
    'carrot_1': 0.41,
    'cucumber_1': 0.15,
    'cucumber_3': 0.15,
    'eggplant_long_1': 0.25,
    'pear_1': 0.57,
    'pear_3': 0.57,
    'zucchini_1': 0.17,
    'zucchini_dark_1': 0.17,
  };
  final Map<String, double> _proteinPerGram = {
    'apple_6': 0.002,
    'apple_braeburn_1': 0.002,
    'apple_crimson_snow_1': 0.002,
    'apple_golden_1': 0.002,
    'apple_golden_2': 0.002,
    'apple_golden_3': 0.002,
    'apple_granny_smith_1': 0.002,
    'apple_hit_1': 0.002,
    'apple_pink_lady_1': 0.002,
    'apple_red_1': 0.002,
    'apple_red_2': 0.002,
    'apple_red_3': 0.002,
    'apple_red_delicious_1': 0.002,
    'apple_red_yellow_1': 0.002,
    'apple_rotten_1': 0.0,
    'cabbage_white_1': 0.01,
    'carrot_1': 0.009,
    'cucumber_1': 0.008,
    'cucumber_3': 0.008,
    'eggplant_long_1': 0.01,
    'pear_1': 0.002,
    'pear_3': 0.002,
    'zucchini_1': 0.007,
    'zucchini_dark_1': 0.007,
  };

  final Map<String, double> _fatsPerGram = {
    'apple_6': 0.003,
    'apple_braeburn_1': 0.003,
    'apple_crimson_snow_1': 0.003,
    'apple_golden_1': 0.003,
    'apple_golden_2': 0.003,
    'apple_golden_3': 0.003,
    'apple_granny_smith_1': 0.003,
    'apple_hit_1': 0.003,
    'apple_pink_lady_1': 0.003,
    'apple_red_1': 0.003,
    'apple_red_2': 0.003,
    'apple_red_3': 0.003,
    'apple_red_delicious_1': 0.003,
    'apple_red_yellow_1': 0.003,
    'apple_rotten_1': 0.0,
    'cabbage_white_1': 0.002,
    'carrot_1': 0.002,
    'cucumber_1': 0.001,
    'cucumber_3': 0.001,
    'eggplant_long_1': 0.002,
    'pear_1': 0.003,
    'pear_3': 0.003,
    'zucchini_1': 0.001,
    'zucchini_dark_1': 0.001,
  };

  final Map<String, double> _carbsPerGram = {
    'apple_6': 0.14,
    'apple_braeburn_1': 0.14,
    'apple_crimson_snow_1': 0.14,
    'apple_golden_1': 0.14,
    'apple_golden_2': 0.14,
    'apple_golden_3': 0.14,
    'apple_granny_smith_1': 0.14,
    'apple_hit_1': 0.14,
    'apple_pink_lady_1': 0.14,
    'apple_red_1': 0.14,
    'apple_red_2': 0.14,
    'apple_red_3': 0.14,
    'apple_red_delicious_1': 0.14,
    'apple_red_yellow_1': 0.14,
    'apple_rotten_1': 0.0,
    'cabbage_white_1': 0.06,
    'carrot_1': 0.1,
    'cucumber_1': 0.036,
    'cucumber_3': 0.036,
    'eggplant_long_1': 0.06,
    'pear_1': 0.15,
    'pear_3': 0.15,
    'zucchini_1': 0.035,
    'zucchini_dark_1': 0.035,
  };

  @override
  void initState() {
    super.initState();
    _initializeInterpreter();
    _imagePicker = ImagePicker();
  }

  Future<void> _initializeInterpreter() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print("Model loaded successfully!");
      setState(() {
        _isInterpreterInitialized = true;
      });
    } catch (e) {
      print("Error loading model: $e");
      setState(() {
        _classificationResult = "Error loading model: $e";
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!_isInterpreterInitialized) {
      setState(() {
        _classificationResult = "Interpreter is not initialized.";
      });
      return;
    }

    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isLoading = true;
        });
        await _classifyImage(_selectedImage!);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _takePictureWithCamera() async {
    if (!_isInterpreterInitialized) {
      setState(() {
        _classificationResult = "Interpreter is not initialized.";
      });
      return;
    }

    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isLoading = true;
        });
        await _classifyImage(_selectedImage!);
      }
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Future<Uint8List> _preprocessImage(File image, int inputSize) async {
    final imageBytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception("Failed to decode image");
    }

    final resizedImage =
        img.copyResize(decodedImage, width: inputSize, height: inputSize);

    final normalizedPixels = resizedImage.data
        .map((pixel) {
          final r = (pixel >> 16) & 0xFF;
          final g = (pixel >> 8) & 0xFF;
          final b = pixel & 0xFF;
          return [r / 255.0, g / 255.0, b / 255.0];
        })
        .expand((x) => x)
        .toList();

    return Float32List.fromList(normalizedPixels).buffer.asUint8List();
  }

  Future<void> _classifyImage(File image) async {
    try {
      final inputShape = _interpreter.getInputTensor(0).shape;
      final inputSize = inputShape[1];
      final preprocessedImage = await _preprocessImage(image, inputSize);

      final output = List.generate(
          1, (_) => List.filled(_caloriesPerGram.keys.length, 0.0));
      _interpreter.run(preprocessedImage, output);

      double maxConfidence = 0.0;
      String maxLabel = "Unknown";
      for (int i = 0; i < _caloriesPerGram.keys.length; i++) {
        if (output[0][i] > maxConfidence) {
          maxConfidence = output[0][i];
          maxLabel = _caloriesPerGram.keys.elementAt(i);
        }
      }

      if (maxConfidence > 0) {
        _showPopup(maxLabel);
      } else {
        setState(() {
          _classificationResult = "Unable to classify the image.";
        });
      }
    } catch (e) {
      print("Error during classification: $e");
      setState(() {
        _classificationResult = "Error during classification: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPopup(String label) {
    final TextEditingController weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Item Detected: $label"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: "Enter weight (grams)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final double weight =
                    double.tryParse(weightController.text) ?? 0.0;
                final double calories =
                    weight * (_caloriesPerGram[label] ?? 0.0);
                final double protein = weight * (_proteinPerGram[label] ?? 0.0);
                final double fats = weight * (_fatsPerGram[label] ?? 0.0);
                final double carbs = weight * (_carbsPerGram[label] ?? 0.0);

                setState(() {
                  _classificationResult =
                      "$label\nWeight: ${weight.toStringAsFixed(2)} g\nCalories: ${calories.toStringAsFixed(2)} kcal\n Protein: ${protein.toStringAsFixed(2)} g\n Fats: ${fats.toStringAsFixed(2)} g\n Carbs: ${carbs.toStringAsFixed(2)} g";
                });
                Navigator.of(context).pop();
              },
              child: Text("Calculate"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: TColor.primaryG,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'Food Calorie Estimator',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.file(
                    _selectedImage!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Center(
                    child: Text(
                      'No Image Selected',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: TColor.gray,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: TColor.primaryColor1),
              ),
            if (!_isLoading && _classificationResult.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _classificationResult,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: TColor.black,
                      ),
                    ),
                  ),
                ),
              ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _takePictureWithCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text(
                      'Camera',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primaryColor1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo),
                    label: Text(
                      'Gallery',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primaryColor2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}