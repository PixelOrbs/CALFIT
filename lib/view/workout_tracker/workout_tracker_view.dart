import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/view/workout_tracker/shoulder_press.dart';
import 'package:fitness/view/workout_tracker/tricep_extension.dart';
import 'package:flutter/material.dart';
import 'package:fitness/view/workout_tracker/squat_rep.dart';
import 'bicep_curl.dart';

class ExerciseSelectorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: TColor.primaryG,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Top Padding
              Text(
                "Choose Your Exercise",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TColor.white,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    ExerciseCard(
                      label: "Bicep Curls",
                      icon: Icons.fitness_center,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PoseDetectorView(),
                          ),
                        );
                      },
                    ),
                    ExerciseCard(
                      label: "Squats",
                      icon: Icons.accessibility_new,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SquatDetectorView(),
                          ),
                        );
                      },
                    ),
                    ExerciseCard(
                      label: "Shoulder Press",
                      icon: Icons.accessibility_new,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShoulderPressDetectorView(),
                          ),
                        );
                      },
                    ),
                    ExerciseCard(
                      label: "Tricep Extension",
                      icon: Icons.accessibility_new,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TricepExtensionDetectorView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const ExerciseCard({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: TColor.secondaryG,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: TColor.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: TColor.white,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TColor.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
