import 'package:flutter/material.dart';
import 'package:miracle/AudioAppPage.dart';
import 'package:miracle/login.dart';
import 'package:splashscreen/splashscreen.dart';
import 'package:miracle/main.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      seconds: 2,
      navigateAfterSeconds: RouteScreenPage(),
      image: Image.asset("assets/images/digrooveLogo.png"),
      photoSize: 130,
      backgroundColor: Color(0xff192028),
      // imageBackground: AssetImage("assets/images/digrooveLogo.png"),
      loaderColor: Colors.grey,
    );
  }
}
