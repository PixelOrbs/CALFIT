import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/common_widget/round_button.dart';
import 'package:fitness/view/home/water_intake_tracker.dart';
import 'package:fitness/view/meal_planner/meal_planner_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.emailController});

  final TextEditingController emailController;
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Map<String, dynamic>? userData;

  Future<void> getUserData() async {
    String email = widget.emailController.text;
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('UserData')
        .doc(email)
        .get();

    if (snapshot.exists) {
      setState(() {
        userData = snapshot.data() as Map<String, dynamic>;
      });
    } else {
      print('No user data found for this email.');
    }
  }

  double calculateBMI() {
    if (userData == null ||
        userData!['Weight'] == null ||
        userData!['Height'] == null) {
      return 0.0;
    }
    double weight = double.parse(userData!['Weight'].toString());
    double heightCm = double.parse(userData!['Height'].toString());
    double heightMeters = heightCm / 100;
    return weight / (heightMeters * heightMeters);
  }

  double calculateBMR() {
    if (userData == null ||
        userData!['Weight'] == null ||
        userData!['Height'] == null ||
        userData!['DateOfBirth'] == null) {
      print("Error: Missing user data.");
      return 0.0;
    }

    try {
      double weight = double.parse(userData!['Weight'].toString()) ?? 0.0;
      double heightCm = double.parse(userData!['Height'].toString()) ?? 0.0;
      int age = int.parse(userData!['DateOfBirth'].toString()) ?? 0;

      if (weight <= 0 || heightCm <= 0 || age <= 0) {
        print("Error: Invalid numerical data.");
        return 0.0;
      }

      double bmr = 10 * weight + 6.25 * heightCm - 5 * age + 5;
      print("Calculated BMR: $bmr");
      return bmr;
    } catch (e) {
      print("Error while calculating BMR: $e");
      return 0.0;
    }
  }

  List<int> showingTooltipOnSpots = [21];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: TextStyle(color: TColor.gray, fontSize: 12),
                        ),
                        Text(
                          userData != null ? "${userData!['FirstName']}" : "",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Container(
                  height: media.width * 0.4,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      borderRadius: BorderRadius.circular(media.width * 0.075)),
                  child: Stack(alignment: Alignment.center, children: [
                    Image.asset(
                      "assets/img/bg_dots.png",
                      height: media.width * 0.4,
                      width: double.maxFinite,
                      fit: BoxFit.fitHeight,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 25, horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "BMI (Body Mass Index)",
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                "",
                                style: TextStyle(
                                    color: TColor.white.withOpacity(0.7),
                                    fontSize: 12),
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                            ],
                          ),
                          AspectRatio(
                            aspectRatio: 1,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {},
                                ),
                                startDegreeOffset: 250,
                                borderData: FlBorderData(
                                  show: false,
                                ),
                                sectionsSpace: 1,
                                centerSpaceRadius: 0,
                                sections: showingSections(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ]),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  decoration: BoxDecoration(
                    color: TColor.primaryColor2.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today Target",
                        style: TextStyle(
                            color: TColor.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        width: 70,
                        height: 25,
                        child: RoundButton(
                          title: "Check",
                          type: RoundButtonType.bgGradient,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MealPlanner(),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Text(
                  "BMR Status",
                  style: TextStyle(
                      color: TColor.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(
                  height: media.width * 0.02,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    height: media.width * 0.4,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: TColor.primaryColor2.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Calories To Be Consumed",
                                style: TextStyle(
                                    color: TColor.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                          colors: TColor.primaryG,
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight)
                                      .createShader(Rect.fromLTRB(
                                          0, 0, bounds.width, bounds.height));
                                },
                                child: Text(
                                  "${calculateBMR().toStringAsFixed(2)} kcal/day",
                                  style: TextStyle(
                                      color: TColor.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.05),
                Text(
                  "Water Intake Tracker",
                  style: TextStyle(
                      color: TColor.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: media.width * 0.02),
                WaterIntakeTracker(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                SizedBox(
                  height: media.width * 0.1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(
      2,
      (i) {
        var color0 = TColor.secondaryColor1;
        double bmi = calculateBMI();
        double bmr = calculateBMR();
        switch (i) {
          case 0:
            return PieChartSectionData(
                color: color0,
                value: 33,
                title: '',
                radius: 55,
                titlePositionPercentageOffset: 0.55,
                badgeWidget: Text(
                  bmi != 0.0 ? bmi.toStringAsFixed(1) : "N/A",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ));
          case 1:
            return PieChartSectionData(
              color: Colors.white,
              value: 75,
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
            );

          default:
            throw Error();
        }
      },
    );
  }
}
