import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fitness/common/colo_extension.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealPlanner extends StatefulWidget {
  @override
  _MealPlannerState createState() => _MealPlannerState();
}

class _MealPlannerState extends State<MealPlanner> {
  
  int totalCalories = 2000;
  int remainingCalories = 2000;


  Map<String, List<Map<String, dynamic>>> meals = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
  };


  late Interpreter _interpreter;
  late ImagePicker _imagePicker;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isInterpreterInitialized = false;
  String _classificationResult = "No result yet";

  
final Map<String, double> _caloriesPerGram = {
  "burger": 5.7,
  "sliced cake": 4.1,
  "chicken chop": 4.0,
  "spring roll": 3.8,
  "patty": 2.0,
  "samosa": 3.6,
  "sandwich": 3.5,
  "uncle chips": 5.5,  
};


  @override
  void initState() {
    super.initState();
    _initializeInterpreter();
    _imagePicker = ImagePicker();
    _loadSavedData();
  }

  Future<void> _initializeInterpreter() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/food_model.tflite');
      print("Model loaded successfully!");
      setState(() {
        _isInterpreterInitialized = true;
      });
    } catch (e) {
      print("Error loading model: $e");
      setState(() {
        _isInterpreterInitialized = false;
      });
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      remainingCalories = prefs.getInt('remainingCalories') ?? totalCalories;

      String? savedMeals = prefs.getString('meals');
      if (savedMeals != null) {
        
        Map<String, dynamic> decodedMeals = json.decode(savedMeals);
        meals = decodedMeals.map(
          (key, value) => MapEntry(
            key,
            List<Map<String, dynamic>>.from(
              value.map((item) => Map<String, dynamic>.from(item)),
            ),
          ),
        );
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remainingCalories', remainingCalories);
    await prefs.setString('meals', json.encode(meals));
  }

  Future<void> _resetData() async {
    setState(() {
      remainingCalories = totalCalories;
      meals = {
        'Breakfast': [],
        'Lunch': [],
        'Dinner': [],
      };
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remainingCalories');
    await prefs.remove('meals');
  }

  Future<void> _takePicture(String mealType) async {
    if (!_isInterpreterInitialized) {
      _showError("Model is not initialized!");
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
        await _classifyImage(_selectedImage!, mealType);
      }
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Future<void> _takePictureForAnyMeal() async {
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
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _classifyImage(File image, String mealType) async {
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
        _showPopup(maxLabel, mealType);
      } else {
        _showError("Unable to classify the image.");
      }
    } catch (e) {
      print("Error during classification: $e");
      _showError("Error during classification.");
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _showPopup(String label, String mealType) {
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

                addMealItem(mealType, label, calories.toInt());
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void addMealItem(String mealType, String foodName, int calories) {
    setState(() {
      meals[mealType]?.add({'name': foodName, 'calories': calories});
      remainingCalories -= calories;
    });
    _saveData();
  }

  void removeMealItem(String mealType, int index) {
    setState(() {
      int removedCalories = meals[mealType]?[index]['calories'] ?? 0;
      meals[mealType]?.removeAt(index);
      remainingCalories += removedCalories;
    });
    _saveData();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meal Planner',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: TColor.white,
          ),
        ),
        backgroundColor: TColor.primaryColor1,
        elevation: 0,
      ),
      body: Column(
        children: [
          
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: TColor.primaryG,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Calories Left',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: TColor.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '$remainingCalories kcal',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: TColor.white,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.secondaryColor1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                  ),
                  child: Text(
                    'Reset for the Day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TColor.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          
          Expanded(
            child: ListView(
              children: meals.keys.map((mealType) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      mealType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TColor.black,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: TColor.primaryColor1,
                      ),
                      onPressed: () => _takePicture(mealType),
                    ),
                    children: meals[mealType]!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final meal = entry.value;
                      return ListTile(
                        leading: Icon(
                          Icons.food_bank,
                          color: TColor.secondaryColor1,
                        ),
                        title: Text(
                          '${meal['name']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TColor.black,
                          ),
                        ),
                        subtitle: Text(
                          '${meal['calories']} kcal',
                          style: TextStyle(color: TColor.gray),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () => removeMealItem(mealType, index),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),

        
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePictureForAnyMeal,
                  icon: Icon(Icons.camera_alt),
                  label: Text(
                    'Add Meal',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetData,
                  icon: Icon(Icons.refresh),
                  label: Text(
                    'Reset',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.secondaryColor2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
