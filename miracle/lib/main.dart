import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miracle/AudioAppPage.dart';
import 'package:miracle/data/userData.dart';
import 'package:miracle/login.dart';

import 'package:miracle/splashscreen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(cardColor: Colors.white, accentColor: Colors.black),
      routes: {
        '/': (context) => SplashScreenPage(),
        '/loginpage': (context) => LoginPage(),
      },
    );
  }
}

class RouteScreenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (context, AsyncSnapshot<FirebaseUser> snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return SplashScreenPage();
        // }
        if (!snapshot.hasData || snapshot.data == null) {
          return LoginPage();
        }
        return ChangeNotifierProvider<UserData>(
          create: (context) => UserData(snapshot.data.displayName.toString()),
          child: AudioAppPage(),
        );
      },
    );
  }
}
