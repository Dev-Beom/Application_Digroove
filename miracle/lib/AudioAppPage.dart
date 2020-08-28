import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:marquee/marquee.dart';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:miracle/data/userData.dart';
import 'package:miracle/marquee.dart';
import 'package:miracle/utils/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

typedef void OnError(Exception exception);

var kUrl =
    "https://www.mediacollege.com/downloads/sound-effects/nature/forest/rainforest-ambient.mp3";

enum PlayerState { stopped, playing, paused }

class AudioAppPage extends StatefulWidget {
  AudioAppPage({Key key}) : super(key: key);
  @override
  _AudioAppPageState createState() => _AudioAppPageState();
}

class _AudioAppPageState extends State<AudioAppPage> {
  Duration duration;
  Duration position;

  AudioPlayer audioPlayer;

  String localFilePath;

  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

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
    initAudioPlayer();
    pageIndex = 0;
    homeButtonState = true;
    musicButtonState = false;
    listButtonState = false;
    moreButtonState = false;
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _audioPlayerStateSubscription.cancel();
    audioPlayer.stop();
    super.dispose();
  }

  void initAudioPlayer() {
    audioPlayer = AudioPlayer();
    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => setState(() => position = p));
    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        setState(() => duration = audioPlayer.duration);
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
        setState(() {
          position = duration;
        });
      }
    }, onError: (msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });
  }

  Future play() async {
    await audioPlayer.play(kUrl);
    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future _playLocal() async {
    await audioPlayer.play(localFilePath, isLocal: true);
    setState(() => playerState = PlayerState.playing);
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() => playerState = PlayerState.paused);
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = Duration();
    });
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    setState(() {
      isMuted = muted;
    });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  Future<Uint8List> _loadFileBytes(String url, {OnError onError}) async {
    Uint8List bytes;
    try {
      bytes = await readBytes(url);
    } on ClientException {
      rethrow;
    }
    return bytes;
  }

  Future _loadFile() async {
    final bytes = await _loadFileBytes(kUrl,
        onError: (Exception exception) =>
            print('_loadFile => exception $exception'));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/audio.mp3');

    await file.writeAsBytes(bytes);
    if (await file.exists())
      setState(() {
        localFilePath = file.path;
      });
  }

  UserData userData;

  @override
  Widget build(BuildContext context) {
    userData = Provider.of<UserData>(context);
    userName = userData.getLoginName;
    print(userName);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "DIGROOVE",
          style: TextStyle(fontSize: 30),
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
          _buildBottomPlayer(),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer() {
    return Container(
      height: 60,
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
      child: Padding(
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
              child: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: NetworkImage(playAvatar == ""
                    ? "https://d1csarkz8obe9u.cloudfront.net/posterpreviews/artistic-album-cover-design-template-d12ef0296af80b58363dc0deef077ecc_screen.jpg?ts=1561488440"
                    : playAvatar),
                radius: 20,
              ),
            ),
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
                  Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {}),
            IconButton(
                icon: Icon(
                  Icons.add_to_photos,
                  color: Colors.white,
                ),
                onPressed: () {}),
          ],
        ),
      ),
    );
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
              icon: Icon(Icons.more_horiz,
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

  Widget _buildPlayer() => Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                onPressed: isPlaying ? null : () => play(),
                iconSize: 50.0,
                icon: Icon(Icons.play_arrow),
                color: Colors.cyan,
              ),
              IconButton(
                onPressed: isPlaying ? () => pause() : null,
                iconSize: 50.0,
                icon: Icon(Icons.pause),
                color: Colors.cyan,
              ),
              IconButton(
                onPressed: isPlaying || isPaused ? () => stop() : null,
                iconSize: 50.0,
                icon: Icon(Icons.stop),
                color: Colors.cyan,
              ),
            ]),
            if (duration != null)
              Slider(
                value: position?.inMilliseconds?.toDouble() ?? 0.0,
                onChanged: (double value) {
                  return audioPlayer.seek((value / 1000).roundToDouble());
                },
                min: 0.0,
                max: duration.inMilliseconds.toDouble(),
              ),
            // if (position != null) _buildMuteButtons(),
            // if (position != null) _buildProgressView()
          ],
        ),
      );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(
            value: position != null && position.inMilliseconds > 0
                ? (position?.inMilliseconds?.toDouble() ?? 0.0) /
                    (duration?.inMilliseconds?.toDouble() ?? 0.0)
                : 0.0,
            valueColor: AlwaysStoppedAnimation(Colors.cyan),
            backgroundColor: Colors.grey.shade400,
          ),
        ),
        Text(
          position != null
              ? "${positionText ?? ''} / ${durationText ?? ''}"
              : duration != null ? durationText : '',
          style: TextStyle(fontSize: 10.0),
        )
      ]);

  Row _buildMuteButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        if (!isMuted)
          FlatButton.icon(
            onPressed: () => mute(true),
            icon: Icon(
              Icons.headset_off,
              color: Colors.cyan,
            ),
            label: Text('Mute', style: TextStyle(color: Colors.cyan)),
          ),
        if (isMuted)
          FlatButton.icon(
            onPressed: () => mute(false),
            icon: Icon(Icons.headset, color: Colors.cyan),
            label: Text('Unmute', style: TextStyle(color: Colors.cyan)),
          ),
      ],
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
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection(colName).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Text("Loading");
            default:
              return ListView(
                children:
                    snapshot.data.documents.map((DocumentSnapshot document) {
                  return Card(
                    color: themeColor,
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        // showDocument(document.documentID);
                        kUrl = document["musicurl"];
                        print(kUrl);
                        setState(() {
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
                                    image:
                                        NetworkImage(document["coverimage"])),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 10,
                                ),
                                CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(document["avatarimage"]),
                                  backgroundColor: Colors.white,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
    return pageIndex == 2
        ? Container(
            child: Text("data"),
          )
        : Container();
  }

  Widget _buildMorePage() {
    return Container(
      child: RaisedButton(
        onPressed: () {
          AuthProvider().logOut();
        },
        child: Text("Logout"),
      ),
    );
  }
}
