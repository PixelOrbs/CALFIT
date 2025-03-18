import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/backend/User_Data.dart'; 
import 'package:fitness/view/main_tab/main_tab_view.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key, required this.emailController});
  final TextEditingController
      emailController; 

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  Map<String, dynamic>? userData; 

  @override
  void initState() {
    super.initState();
    getUserData(); 
  }

  Future<void> getUserData() async {
    String email = widget.emailController.text; 
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('UserData')
        .doc(email)
        .get();

    if (snapshot.exists) {
      setState(() {
        userData =
            snapshot.data() as Map<String, dynamic>; 
      });
    } else {
      print('No user data found for this email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: SafeArea(
        child: Container(
          width: media.width,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: media.width * 0.1,
              ),
              Image.asset(
                "assets/img/welcome.png",
                width: media.width * 0.75,
                fit: BoxFit.fitWidth,
              ),
              SizedBox(
                height: media.width * 0.1,
              ),
              
              Text(
                userData != null
                    ? "Welcome, ${userData!['FirstName']}"
                    : "Welcome!",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "You are all set now, let’s reach your\ngoals together with us",
                textAlign: TextAlign.center,
                style: TextStyle(color: TColor.gray, fontSize: 12),
              ),
              const Spacer(),
              RoundButton(
                title: "Go To Home",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainTabView(emailController: widget.emailController),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
