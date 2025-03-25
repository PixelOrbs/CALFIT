import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterIntakeTracker extends StatefulWidget {
  @override
  _WaterIntakeTrackerState createState() => _WaterIntakeTrackerState();
}

class _WaterIntakeTrackerState extends State<WaterIntakeTracker> {
  int waterIntake = 0;
  final int dailyGoal = 3000; 

  @override
  void initState() {
    super.initState();
    _loadWaterIntake();
  }

  _loadWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      waterIntake = prefs.getInt('waterIntake') ?? 0;
    });
  }

  _addWater() async {
    if (waterIntake < dailyGoal) {
      setState(() {
        waterIntake += 250; // Adds 250ml per click
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('waterIntake', waterIntake);
    }
  }

  _resetWaterIntake() async {
    setState(() {
      waterIntake = 0;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('waterIntake', 0);
  }

  @override
  Widget build(BuildContext context) {
    double progress = (waterIntake / dailyGoal).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff9DCEFF), 
            Color(0xff92A3FD), 
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 8,
                ),
              ),
              Text(
                "${(waterIntake / 1000).toStringAsFixed(1)}L / 3L",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // +250ml Button with Purple Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE69DD5), Color(0xFFCB90EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: _addWater,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("+250ml",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              SizedBox(width: 10),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: _resetWaterIntake,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Reset",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
