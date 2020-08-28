import 'package:flutter/cupertino.dart';

class PlayInfo extends ChangeNotifier {
  String title;
  String singer;
  String avatar;

  void setPlayInfo(String _title, String _singer, String _avatar) {
    title = _title;
    singer = _singer;
    avatar = _avatar;
    notifyListeners();
  }
}
