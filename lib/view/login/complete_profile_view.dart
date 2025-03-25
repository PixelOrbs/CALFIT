import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/view/login/welcome_view.dart';
import 'package:flutter/material.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class CompleteProfileView extends StatefulWidget {
  final TextEditingController emailController;

  const CompleteProfileView({super.key, required this.emailController});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  TextEditingController txtDate = TextEditingController();
  TextEditingController txtWeight = TextEditingController();
  TextEditingController txtHeight = TextEditingController();

  String? selectedGender;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // If validation passes, update Firebase
      FirebaseFirestore.instance.collection('UserData').doc(widget.emailController.text).update({
        "DateOfBirth": txtDate.text,
        "Weight": txtWeight.text,
        "Height": txtHeight.text,
        "Gender": selectedGender
      }).then((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeView(emailController: widget.emailController),
          ),
        );
      }).catchError((error) {
        print("Error adding user data: $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey, // Assign form key
              child: Column(
                children: [
                  Image.asset(
                    "assets/img/complete_profile.png",
                    width: media.width,
                    fit: BoxFit.fitWidth,
                  ),
                  SizedBox(height: media.width * 0.05),
                  Text(
                    "Let’s complete your profile",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "It will help us to know more about you!",
                    style: TextStyle(color: TColor.gray, fontSize: 12),
                  ),
                  SizedBox(height: media.width * 0.05),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: TColor.lightGray,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: Image.asset(
                                  "assets/img/gender.png",
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  color: TColor.gray,
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedGender,
                                    items: ["Male", "Female"]
                                        .map((name) => DropdownMenuItem(
                                              value: name,
                                              child: Text(
                                                name,
                                                style: TextStyle(color: TColor.gray, fontSize: 14),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedGender = value;
                                      });
                                    },
                                    isExpanded: true,
                                    hint: Text(
                                      "Choose Gender",
                                      style: TextStyle(color: TColor.gray, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        if (selectedGender == null) // Show error if gender is not selected
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              "Please select a gender",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        SizedBox(height: media.width * 0.04),
                        RoundTextField(
                          controller: txtDate,
                          hitText: "Date of Birth",
                          icon: "assets/img/date.png",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return "Date of Birth is required";
                            return null;
                          },
                        ),
                        SizedBox(height: media.width * 0.04),
                        Row(
                          children: [
                            Expanded(
                              child: RoundTextField(
                                controller: txtWeight,
                                hitText: "Your Weight",
                                icon: "assets/img/weight.png",
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return "Weight is required";
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: TColor.secondaryG,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "KG",
                                style: TextStyle(color: TColor.white, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: media.width * 0.04),
                        Row(
                          children: [
                            Expanded(
                              child: RoundTextField(
                                controller: txtHeight,
                                hitText: "Your Height",
                                icon: "assets/img/hight.png",
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return "Height is required";
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: TColor.secondaryG,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                "CM",
                                style: TextStyle(color: TColor.white, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: media.width * 0.07),
                        RoundButton(
                          title: "Next >",
                          onPressed: _submitForm, // Calls the function to validate & submit
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
