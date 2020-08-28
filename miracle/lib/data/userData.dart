import 'package:flutter/foundation.dart';

class UserData with ChangeNotifier {
  UserData(this.loginName);
  String loginEmail;
  String loginName;

  String get getLoginEmail => loginEmail;
  String get getLoginName => loginName;

  void setLoginEmail(String email, String name) {
    loginEmail = email;
    loginName = name;
  }
}
