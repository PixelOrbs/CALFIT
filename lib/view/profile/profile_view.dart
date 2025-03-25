import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/view/login/complete_profile_view.dart';
import 'package:fitness/view/on_boarding/on_boarding_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/title_subtitle_cell.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.emailController});

  final TextEditingController emailController;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leadingWidth: 0,
        title: Text(
          "Profile",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      "assets/img/u2.png",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData != null
                              ? "${userData!['FirstName']} ${userData!['LastName']}"
                              : "Loading...",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "Lose a Fat Program",
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    height: 25,
                    child: RoundButton(
                      title: "Logout",
                      onPressed: () {
                        FirebaseAuth.instance.signOut().then((value) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const OnBoardingView()),
                            (Route<dynamic> route) => false,
                          );
                        }).catchError((error) {
                          print("Logout Error: ${error.toString()}");
                        });
                      },
                      type: RoundButtonType.bgGradient,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TitleSubtitleCell(
                      title: userData?['Height'] != null
                          ? "${userData!['Height']} cm"
                          : "N/A",
                      subtitle: "Height",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TitleSubtitleCell(
                      title: userData?['Weight'] != null
                          ? "${userData!['Weight']} kg"
                          : "N/A",
                      subtitle: "Weight",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TitleSubtitleCell(
                      title: userData?['DateOfBirth'] != null
                          ? "${userData!['DateOfBirth']} yo"
                          : "N/A",
                      subtitle: "Age",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: RoundButton(
                  title: "Change Profile",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CompleteProfileView(
                                emailController: widget.emailController,
                              )),
                    );
                  },
                  type: RoundButtonType.bgGradient,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
