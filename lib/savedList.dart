import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class SavedList extends StatefulWidget {
  final String appFolder;

  const SavedList({Key key, @required this.appFolder}) : super(key: key);
  @override
  _SavedListState createState() => _SavedListState();
}

class _SavedListState extends State<SavedList> {
  List files;
  int seconds = 0;
  int minutes = 0;
  int hours = 0;
  AudioPlayer audioPlayer = AudioPlayer();

  Duration position = Duration(seconds: 0);

  Duration duration = Duration(seconds: 0);
  int isPlaying;

  var playerStatus;
  @override
  void initState() {
    super.initState();
    files = Directory(widget.appFolder).listSync().toList();
    //print("audioPlayer Status: ${audioPlayer.state}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved List"),
        centerTitle: true,
      ),
      body: showList(),
    );
  }

  play({@required String song, @required int playingNumber}) async {
    if (isPlaying != playingNumber) {
      playerStatus = AudioPlayerState.PLAYING;
      await audioPlayer.play(song, isLocal: true);
      // print("status in playing $playerStatus");

      audioPlayer.onAudioPositionChanged.listen((d) {
        //print("player Stutus: ${audioPlayer.state}");
        //print("on duration canged $d");
        setState(() {
          position = d;
          // print("total duration ${position.inSeconds / duration.inSeconds}");
        });
      });
      audioPlayer.onPlayerCompletion.listen((d) {
        setState(() {
          isPlaying = null;
        });
      });
      audioPlayer.onDurationChanged.listen((Duration d) {
        //print('Max duration: $d');
        setState(() => duration = d);
      });
    } else {
      print("in pause");
      await audioPlayer.pause();
      setState(() {
        isPlaying = null;
      });
    }
  }

  showIcon({@required int plyingNumber}) {
    if (isPlaying == plyingNumber) {
      return Icon(Icons.pause);
    } else {
      return Icon(Icons.play_arrow);
      setState(() {
        isPlaying = null;
      });
    }
  }

  onDelete(String file) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Do you want do delete"),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton(
                    child: Text("cancel"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  FlatButton(
                    child: Text("Ok"),
                    onPressed: () async {
                      Navigator.pop(context);
                      var del = await File(file).delete();
                      Toast.show("Deleted ${del.path}", context, duration: 2);
                      setState(() {
                        files = Directory(widget.appFolder).listSync().toList();
                      });
                    },
                  ),
                ],
              ),
            ],
          );
        });
  }

  showPosition({@required int index}) {
    if (isPlaying == index) {
      double value = (position.inSeconds / duration.inSeconds).toDouble();
      print("value $value");
      if (value.isNaN) {
        value = 0;
      }
      seconds = position.inSeconds;
      if (seconds >= 60) {
        minutes++;
        seconds = 0;
      }
      if (minutes >= 60) {
        hours++;
        minutes = 0;
      }

      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(position
                .toString()
                .substring(0, position.toString().indexOf('.'))),
            Container(
              width: MediaQuery.of(context).size.width * .5,
              child: CupertinoSlider(
                value: value,
                onChanged: (d) {
                  audioPlayer.seek(
                      Duration(seconds: (duration.inSeconds * d).toInt()));
                },
              ),
            ),
            Text(duration
                .toString()
                .substring(0, duration.toString().indexOf('.'))),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  showList() {
    int count = 0;
    for (var i in files) {
      if (i.path.endsWith("m4a")) {
        count++;
      }
    }

    if (count == 0) {
      return Center(
        child: Text("Your SavedList is empty..."),
      );
    } else {
      return Container(
        child: ListView.builder(
          itemCount: files == null ? 0 : files.length,
          itemBuilder: (context, index) {
            if (files[index].path.endsWith("m4a")) {
              String path = files[index].path;
              String name =
                  path.substring((path.indexOf('der/') + 4), path.length - 4);
              return Container(
                  child: Column(
                children: <Widget>[
                  ListTile(
                    leading: showIcon(plyingNumber: index),
                    title: Text(name),
                    onTap: () {
                      play(song: files[index].path, playingNumber: index);
                      setState(() {
                        isPlaying = index;
                      });
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        onDelete(files[index].path);
                      },
                    ),
                  ),
                  showPosition(index: index)
                ],
              ));
            } else {
              return Container();
            }
          },
        ),
      );
    }
  }
}
