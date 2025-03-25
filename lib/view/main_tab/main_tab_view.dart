import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/backend/User_Data.dart';
import 'package:fitness/common_widget/tab_button.dart';
import 'package:fitness/view/meal_planner/camera.dart';
import 'package:fitness/view/home/home_view.dart';
import 'package:fitness/view/main_tab/select_view.dart';
import 'package:fitness/view/profile/profile_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key, required this.emailController});
  final TextEditingController emailController;

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  Map<String, dynamic>? userData;
  int selectTab = 0;
  final PageStorageBucket pageBucket = PageStorageBucket();
  late Widget currentTab;

  @override
  void initState() {
    super.initState();
    getUserData();
    currentTab = HomeView(emailController: widget.emailController);
  }

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
      backgroundColor: TColor.white,
      body: PageStorage(bucket: pageBucket, child: currentTab),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: InkWell(
          onTap: () {},
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: TColor.white,
        child: Container(
          decoration: BoxDecoration(color: TColor.white, boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 2, offset: Offset(0, -2))
          ]),
          height: kToolbarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TabButton(
                  icon: "assets/img/home_tab.png",
                  selectIcon: "assets/img/home_tab_select.png",
                  isActive: selectTab == 0,
                  onTap: () {
                    setState(() {
                      selectTab = 0;
                      currentTab =
                          HomeView(emailController: widget.emailController);
                    });
                  }),
              TabButton(
                  icon: "assets/img/activity_tab.png",
                  selectIcon: "assets/img/activity_tab_select.png",
                  isActive: selectTab == 1,
                  onTap: () {
                    setState(() {
                      currentTab = const SelectView();
                      selectTab = 1;
                    });
                  }),
              const SizedBox(
                width: 40,
              ),
              TabButton(
                  icon: "assets/img/camera_tab.png",
                  selectIcon: "assets/img/camera_tab_select.png",
                  isActive: selectTab == 2,
                  onTap: () {
                    setState(() {
                      currentTab = CameraScreen();
                      selectTab = 2;
                    });
                  }),
              TabButton(
                  icon: "assets/img/profile_tab.png",
                  selectIcon: "assets/img/profile_tab_select.png",
                  isActive: selectTab == 3,
                  onTap: () {
                    setState(() {
                      selectTab = 3;
                      currentTab =
                          ProfileView(emailController: widget.emailController);
                    });
                  })
            ],
          ),
        ),
      ),
    );
  }
}
