import 'dart:async';
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:marquee/marquee.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miracle/data/userData.dart';
import 'package:miracle/marquee.dart';
import 'package:miracle/utils/firebase_auth.dart';
import 'package:provider/provider.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class AudioAppPage extends StatefulWidget {
  AudioAppPage({Key key}) : super(key: key);
  @override
  _AudioAppPageState createState() => _AudioAppPageState();
}

class _AudioAppPageState extends State<AudioAppPage> {
  var kUrl;

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;

  bool loopPlay = false;
  Color themeColor = Color(0xff313842);
  String userName = "";

  int pageIndex;

  String musicState = "테마";

  bool homeButtonState;
  bool musicButtonState;
  bool listButtonState;
  bool moreButtonState;

  String playTitle = "";
  String playSinger = "";
  String playAvatar = "";
  String playImg = "";
  String playRunningtime = "";

  //컬렉션 명
  final String colName = "FirstDemo";

  //필드 명
  final String fnTitle = "title";
  final String fnWriter = "writer";
  final String fnAvatarImage = "avatarimage";
  final String fnCoverImage = "coverimage";
  final String fnRunningTime = "runningtime";

  @override
  void initState() {
    super.initState();
    pageIndex = 0;
    homeButtonState = true;
    musicButtonState = false;
    listButtonState = false;
    moreButtonState = false;
  }

  UserData userData;

  AudioPlayer audioPlayer = new AudioPlayer();
  Duration duration = new Duration();
  Duration position = new Duration();

  bool playing = false;

  bool starState = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    userData = Provider.of<UserData>(context);
    userName = userData.getLoginName;
    print(userName);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Image.asset(
          "assets/images/digrooveLogo.png",
          scale: 35,
        ),
        centerTitle: true,
        backgroundColor: Color(0xff192028),
        elevation: 0.0,
      ),
      backgroundColor: Color(0xff192028),
      body: Column(
        children: [
          // Container(
          //   margin: EdgeInsets.symmetric(vertical: 0.0),
          //   height: 60.0,
          //   child: ListView(
          //     scrollDirection: Axis.horizontal,
          //     children: <Widget>[
          //       _buildTile(color: Colors.white, width: 60),
          //       _buildTile(color: Colors.white, width: 60),
          //       _buildTile(color: Colors.white, width: 60),
          //       _buildTile(color: Colors.white, width: 60),
          //       _buildTile(color: Colors.white, width: 60),
          //       _buildTile(color: Colors.white, width: 60),
          //       _buildTile(color: Colors.white, width: 60),
          //     ],
          //   ),
          // ),
          Expanded(
            child: Container(
              child: Center(
                child: Center(
                  child: pageIndex == 0
                      ? _buildMainPage()
                      : pageIndex == 1
                          ? _buildViewPage()
                          : pageIndex == 2
                              ? _buildListPage()
                              : pageIndex == 3 ? _buildMorePage() : null,
                ),
              ),
            ),
          ),
          pageIndex != 0 ? _buildBottomPlayer() : SizedBox(),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer() {
    return Container(
      height: 75,
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 0.1,
              spreadRadius: 0.0,
              offset: Offset(0.0, -1.0)),
        ],
      ),
      child: Column(
        children: [
          slider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(
                  width: 10,
                ),
                Card(
                    elevation: 4.0,
                    shape: CircleBorder(),
                    child: playAvatar != ""
                        ? CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            backgroundImage: NetworkImage(playAvatar),
                            radius: 20,
                          )
                        : Container()),
                SizedBox(
                  width: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 180,
                          child: Text(
                            playSinger,
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 180,
                          child: MarqueeWidget(
                            direction: Axis.horizontal,
                            child: Text(
                              playTitle,
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                IconButton(
                  icon: Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    getAudio();
                  },
                ),
                IconButton(
                    icon: Icon(
                      Icons.add_to_photos,
                      color: Colors.white,
                    ),
                    onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget slider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.red,
        inactiveTrackColor: Colors.white,
        trackHeight: 1.0,
        thumbColor: Colors.yellow,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0.0),
        overlayColor: Colors.purple.withAlpha(0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 0.0),
      ),
      child: Slider.adaptive(
        min: 0.0,
        value: position.inSeconds.toDouble(),
        max: duration.inSeconds.toDouble(),
        onChanged: (double value) {
          setState(() {
            audioPlayer.seek(new Duration(seconds: value.toInt()));
          });
        },
      ),
    );
  }

  Future<void> getAudio() async {
    var url =
        "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/Maroon%205%20-%20%20Girls%20Like%20You.mp3?alt=media&token=aa305306-267b-45e5-9e72-859eb24902fd";

    // playing is false by default
    if (playing) {
      //pause song
      var res = await audioPlayer.pause();
      if (res == 1) {
        setState(() {
          playing = false;
        });
      }
    } else {
      //play song
      var res = await audioPlayer.play(url, isLocal: true);
      if (res == 1) {
        setState(() {
          playing = true;
        });
      }
    }

    audioPlayer.onDurationChanged.listen((Duration dd) {
      setState(() {
        duration = dd;
      });
    });
    audioPlayer.onAudioPositionChanged.listen((Duration dd) {
      setState(() {
        position = dd;
      });
    });
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 50,
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: themeColor,
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 0.1,
                spreadRadius: 0.0,
                offset: Offset(0.0, -1.0)),
          ]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
              splashRadius: 0.1,
              icon: Icon(
                Icons.home,
                color: homeButtonState ? Colors.white : Colors.black,
              ),
              onPressed: () {
                setState(() {
                  homeButtonState = true;
                  musicButtonState = false;
                  listButtonState = false;
                  moreButtonState = false;
                  pageIndex = 0;
                });
              }),
          IconButton(
              splashRadius: 0.1,
              icon: Icon(Icons.queue_music,
                  color: musicButtonState ? Colors.white : Colors.black),
              onPressed: () {
                setState(() {
                  homeButtonState = false;
                  musicButtonState = true;
                  listButtonState = false;
                  moreButtonState = false;
                  pageIndex = 1;
                });
              }),
          IconButton(
              splashRadius: 0.1,
              icon: Icon(Icons.view_list,
                  color: listButtonState ? Colors.white : Colors.black),
              onPressed: () {
                setState(() {
                  homeButtonState = false;
                  musicButtonState = false;
                  listButtonState = true;
                  moreButtonState = false;
                  pageIndex = 2;
                });
              }),
          IconButton(
              splashRadius: 0.1,
              icon: Icon(Icons.person,
                  color: moreButtonState ? Colors.white : Colors.black),
              onPressed: () {
                setState(() {
                  homeButtonState = false;
                  musicButtonState = false;
                  listButtonState = false;
                  moreButtonState = true;
                  pageIndex = 3;
                });
              }),
        ],
      ),
    );
  }

  Widget _buildRowButton(
      {double option,
      bool defaultColor,
      Color colorFirst,
      Color colorSecond,
      Color textColor,
      String text}) {
    return Row(
      children: [
        SizedBox(
          width: option,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            height: 40.0,
            child: RaisedButton(
              onPressed: () {},
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11.0)),
              padding: EdgeInsets.all(0.0),
              child: Ink(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: defaultColor == true
                          ? [Color(0xff313842), Color(0xff313842)]
                          : [colorFirst, colorSecond],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10.0)),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 100.0, minHeight: 40.0),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile({Color color, double height, double width}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      child: Container(
        width: width,
        height: height,
        color: color,
      ),
    );
  }

  Widget _buildMainPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: BorderSide(color: Colors.black45)),
              onPressed: () {
                setState(() {
                  if (musicState == "장르") {
                    musicState = "테마";
                  } else {
                    musicState = "장르";
                  }
                });
              },
              color: Color(0xff192028),
              textColor: Colors.white,
              child: Text(musicState == "장르" ? "테마별로 볼래요." : "장르별로 볼래요.",
                  style: TextStyle(fontSize: 14)),
            ),
            SizedBox(
              width: 10,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${userName}님이 자주 찾는 ${musicState}로 구성해봤어요.",
              style: TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: Icon(
                Icons.help,
                color: Colors.grey[100],
                size: 20,
              ),
              onPressed: () {},
            )
          ],
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 0.0),
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      _buildRowButton(
                        defaultColor: false,
                        text: "R&B / Soul",
                        option: 30,
                        colorFirst: Colors.red,
                        colorSecond: Colors.blue,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "Indie",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "Ballade",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: false,
                        text: "Dance",
                        colorFirst: Colors.lime,
                        colorSecond: Colors.red,
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "I-dol",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "Electronica ",
                        option: 0,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildRowButton(
                        defaultColor: false,
                        text: "POP",
                        option: 30,
                        colorFirst: Colors.pink,
                        colorSecond: Colors.purple,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: false,
                        colorFirst: themeColor,
                        colorSecond: Colors.red,
                        text: "Rock/Metal",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: false,
                        text: "Electronica",
                        colorFirst: Colors.grey,
                        colorSecond: Colors.indigo,
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "EDM",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: false,
                        colorFirst: themeColor,
                        colorSecond: Colors.red,
                        text: "R&B / Soul",
                        option: 0,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildRowButton(
                        defaultColor: true,
                        text: "Rap/Hip Hop",
                        option: 30,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "Folk/Blues",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "OST",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: false,
                        text: "CCM",
                        option: 0,
                        colorFirst: Colors.green,
                        colorSecond: Colors.orangeAccent,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildRowButton(
                        defaultColor: true,
                        text: "Classic",
                        option: 50,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: false,
                        colorFirst: Colors.brown,
                        colorSecond: Colors.amberAccent,
                        text: "Jazz",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: false,
                        colorFirst: Colors.red,
                        colorSecond: Colors.white,
                        text: "J-pop",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "Musical",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "Traditional",
                        option: 0,
                        textColor: Colors.white,
                      ),
                      _buildRowButton(
                        defaultColor: true,
                        text: "New Age",
                        option: 0,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewPage() {
    return Container(
      height: 500,
      child: playing
          ? Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "지금 재생중인 청춘은 ♬",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  SizedBox(
                    height: 7,
                  ),
                  Card(
                    elevation: 4.0,
                    child: Container(
                      height: 200,
                      width: 200,
                      color: Colors.white,
                      child:
                          Image(fit: BoxFit.fill, image: NetworkImage(playImg)),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                          child: Icon(
                            starState ? Icons.star : Icons.star_border,
                            size: 20,
                            color: Colors.yellow[600],
                          ),
                          onPressed: () {
                            setState(() {
                              starState = !starState;
                            });
                          }),
                      Text(
                        playSinger,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    playTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection(colName).snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Text("Loading");
                  default:
                    return ListView(
                      children: snapshot.data.documents
                          .map((DocumentSnapshot document) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                          child: Container(
                            color: themeColor,
                            child: InkWell(
                              onTap: () {
                                // showDocument(document.documentID);
                                print(kUrl);
                                setState(() {
                                  kUrl = document["musicurl"];
                                  print(kUrl);
                                  playImg = document["coverimage"];
                                  playTitle = document["title"];
                                  playSinger = document["writer"];
                                  playAvatar = document["avatarimage"];
                                  homeButtonState = false;
                                  musicButtonState = false;
                                  listButtonState = true;
                                  moreButtonState = false;
                                  pageIndex = 2;
                                });
                              },
                              onLongPress: () {},
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        height: 200,
                                        child: Image(
                                            fit: BoxFit.fill,
                                            image: NetworkImage(
                                                document["coverimage"])),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 10,
                                        ),
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              document["avatarimage"]),
                                          backgroundColor: Colors.white,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              document["title"],
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                document["writer"] +
                                                    " / " +
                                                    document["runningtime"],
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                }
              },
            ),
    );
  }

  void showDocument(String documentID) {
    print("showDocument");
    Firestore.instance
        .collection(colName)
        .document(documentID)
        .get()
        .then((doc) {
      showDocDialog(doc);
    });
  }

  void showDocDialog(DocumentSnapshot doc) {
    print("showDialog");

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.grey[500],
            content: Container(
              height: 400,
              color: Colors.green,
              child: Column(
                children: <Widget>[
                  Container(
                    height: 200,
                    color: Colors.white,
                    child: Image(
                      fit: BoxFit.fill,
                      image: NetworkImage(doc[fnCoverImage]),
                    ),
                  ),
                  Text(
                    doc[fnTitle],
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoButton(
                  child: Text(
                    "재생",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  })
            ],
          );
        });
  }

  Widget _buildMusicList(
      {String name,
      String profileUrl,
      String imageUrl,
      String title,
      String time}) {
    return Card(
      color: themeColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              height: 200,
              child: Image(fit: BoxFit.fill, image: NetworkImage(imageUrl)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(imageUrl),
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Text(
                      "${name} · ${time}",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildListPage() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
        child: Column(
          children: [
            playImg != ""
                ? Container(
                    color: themeColor,
                    child: InkWell(
                      onTap: () {
                        // showDocument(document.documentID);
                      },
                      onLongPress: () {},
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Container(
                              child: Text(
                                "현재 플레이리스트의 수록곡 정보입니다.",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Container(
                                height: 200,
                                child: Image(
                                    fit: BoxFit.fill,
                                    image: NetworkImage(playImg)),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 10,
                                ),
                                CircleAvatar(
                                  backgroundImage: NetworkImage(playAvatar),
                                  backgroundColor: Colors.white,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playTitle,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        playSinger + " / " + playRunningtime,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Container(
                    child: Text(
                      "선택된 앨범이 없습니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            SizedBox(
              height: 5,
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 0.0),
              height: 130.0,
              child: ListView(
                scrollDirection: Axis.vertical,
                children: <Widget>[
                  _buildListTile(
                    index: 1,
                    title: "Girls Like You",
                    singer: "Maroon 5",
                    imageUrl:
                        "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FMaroon%205%20-%20%20Girls%20Like%20You.png?alt=media&token=c0915d6e-2cf6-44df-9bfc-fbccb93b2348",
                  ),
                  _buildListTile(
                    index: 2,
                    title: "I Do",
                    singer: "John Legend",
                    imageUrl:
                        "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FJohn%20Legend%20-%20I%20Do.jpg?alt=media&token=b67e1f3a-c256-4b6e-b4e7-60080d34a266",
                  ),
                  _buildListTile(
                    index: 3,
                    title: "Forgive Myself",
                    singer: "Griff",
                    imageUrl:
                        "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FGriff%20-%20Forgive%20Myself.jpg?alt=media&token=81005c7e-47b8-4038-a952-3e3e5b4f67c4",
                  ),
                  _buildListTile(
                    index: 4,
                    title: "Rain On Me",
                    singer: "Lady Gaga, Ariana Grande",
                    imageUrl:
                        "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FLady%20Gaga%2C%20Ariana%20Grande%20-%20Rain%20On%20Me.png?alt=media&token=79799d23-a897-46ae-b51e-fe7173e42426",
                  ),
                  _buildListTile(
                    index: 5,
                    title: "Feel",
                    singer: "Lindsey Lomis",
                    imageUrl:
                        "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FLindsey%20Lomis%20-%20Feel.jpg?alt=media&token=a7ab02e1-d041-499d-93b1-6a74e536bcec",
                  ),
                  // _buildListTile(index: 2),
                  // _buildListTile(index: 3),
                  // _buildListTile(index: 4),
                  // _buildListTile(index: 5),
                  // _buildListTile(index: 6),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
      {int index, String title, String imageUrl, String singer}) {
    return Card(
      color: themeColor,
      elevation: 0.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(imageUrl),
            backgroundColor: Colors.transparent,
          ),
          trailing: Icon(Icons.playlist_add, color: Colors.white),
          title: Text(
            "${index}. ${title}",
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(singer, style: TextStyle(color: Colors.white)),
          onTap: () {
            SnackbarManager.showSnackBar(scaffoldKey, "선택한 음원이 리스트에 담겼습니다.");
          },
        ),
      ),
    );
  }

  Widget _buildMorePage() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.0),
      height: MediaQuery.of(context).size.height,
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      height: 150,
                      child: Row(children: [
                        MarqueeWidget(
                          direction: Axis.horizontal,
                          child: Text(
                            "내가 만드는 순간",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        CupertinoButton(
                            child: Icon(
                              Icons.add_box,
                              size: 100,
                              color: Colors.white,
                            ),
                            onPressed: () {})
                      ]),
                    ),
                  ],
                ),
                SizedBox(
                  width: 5,
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    height: 200,
                    child:
                        Image(fit: BoxFit.fill, image: NetworkImage(playImg)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 10,
                    ),
                    CircleAvatar(
                      backgroundImage: NetworkImage(playAvatar),
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playTitle,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            playSinger + " / " + playRunningtime,
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildListTile(
            index: 1,
            title: "Girls Like You",
            singer: "Maroon 5",
            imageUrl:
                "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FMaroon%205%20-%20%20Girls%20Like%20You.png?alt=media&token=c0915d6e-2cf6-44df-9bfc-fbccb93b2348",
          ),
          _buildListTile(
            index: 2,
            title: "I Do",
            singer: "John Legend",
            imageUrl:
                "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FJohn%20Legend%20-%20I%20Do.jpg?alt=media&token=b67e1f3a-c256-4b6e-b4e7-60080d34a266",
          ),
          _buildListTile(
            index: 3,
            title: "Forgive Myself",
            singer: "Griff",
            imageUrl:
                "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FGriff%20-%20Forgive%20Myself.jpg?alt=media&token=81005c7e-47b8-4038-a952-3e3e5b4f67c4",
          ),
          _buildListTile(
            index: 4,
            title: "Rain On Me",
            singer: "Lady Gaga, Ariana Grande",
            imageUrl:
                "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FLady%20Gaga%2C%20Ariana%20Grande%20-%20Rain%20On%20Me.png?alt=media&token=79799d23-a897-46ae-b51e-fe7173e42426",
          ),
          _buildListTile(
            index: 5,
            title: "Feel",
            singer: "Lindsey Lomis",
            imageUrl:
                "https://firebasestorage.googleapis.com/v0/b/digroove-f7a64.appspot.com/o/image%2FLindsey%20Lomis%20-%20Feel.jpg?alt=media&token=a7ab02e1-d041-499d-93b1-6a74e536bcec",
          ),
        ],
      ),
      // RaisedButton(
      //   onPressed: () {
      //     AuthProvider().logOut();
      //   },
      //   child: Text("Logout"),
      // ),
    );
  }
}

class SnackbarManager {
  static void showSnackBar(
      GlobalKey<ScaffoldState> scaffoldKey, String message) {
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))),
      backgroundColor: Colors.black,
      elevation: 6.0,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
