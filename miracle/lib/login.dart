import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:miracle/utils/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff192028),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  "지금 이 순간",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
                SizedBox(
                  height: 5,
                ),
                Image.asset(
                  "assets/images/digrooveLogo.png",
                  width: 270,
                ),
              ],
            ),
            Column(
              children: [
                FlatButton(
                  onPressed: () async {
                    bool res = await AuthProvider().loginWithGoogle();
                    if (!res) {
                      print("Error Login whit Google");
                    }
                  },
                  child: Container(
                      width: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Google Login",
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      )),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(color: Colors.red)),
                ),
                FlatButton(
                  onPressed: () {},
                  child: Container(
                      width: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Kakao Login",
                            style: TextStyle(color: Colors.yellow[600]),
                          ),
                        ],
                      )),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(color: Colors.yellow[600])),
                ),
                FlatButton(
                  onPressed: () {},
                  child: Container(
                      width: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Facebook Login",
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      )),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(color: Colors.blue[700])),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
