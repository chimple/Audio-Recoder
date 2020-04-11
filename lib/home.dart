import 'dart:async';
import 'dart:io';
import 'package:audiorecorder/savedList.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toast/toast.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int seconds = 00;
  int minutes = 00;
  int hours = 00;
  double width;
  double height;
  bool stopTimer = false;
  String saveName = DateTime.now().toString();
  bool storage;
  bool mic;

  FlutterAudioRecorder recorder;
  Recording recording;
  var _currentStatus = RecordingStatus.Unset;
  String appStorage;
  Recording result;
  String newName;
  @override
  void initState() {
    checkPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Recorder"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: <Widget>[
            recordingAnimation(),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  recordButton(),
                  stopButton(),
                ],
              ),
            ),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                      "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"),
                ],
              ),
            ),
            ListTile(
              contentPadding:
                  EdgeInsets.only(left: width * .35, top: height * .02),
              leading: Icon(Icons.save),
              title: Text("Saved List"),
              onTap: () async {
                appStorage ?? getAppStorage();
                if (appStorage != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return SavedList(
                      appFolder: appStorage,
                    );
                  }));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  recordButton() {
    if (_currentStatus == RecordingStatus.Unset ||
        _currentStatus == RecordingStatus.Stopped) {
      return Container(
        child: FlatButton(
            child: Icon(
              Icons.mic,
              size: height * .15,
            ),
            onPressed: () async {
              appStorage = await getAppStorage();
              if (appStorage != null) {
                recorder = FlutterAudioRecorder(
                  "$appStorage/${DateTime.now().toLocal()}",
                ); // .wav .aac .m4a

                await recorder.initialized;
                await recorder.start();
                recording = await recorder.current(channel: 0);
                _currentStatus = recording.status;
                print("recodring duration ${recording.duration}");
                setState(() {
                  _currentStatus = RecordingStatus.Recording;
                  seconds = 0;
                  minutes = 0;
                  hours = 0;
                });
                Timer.periodic(Duration(seconds: 1), (Timer t) {
                  if (_currentStatus == RecordingStatus.Recording) {
                    setState(() {
                      seconds++;
                      if (seconds == 60) {
                        minutes++;
                        seconds = 0;
                      }
                      if (minutes == 60) {
                        hours++;
                        minutes = 0;
                      }
                    });
                  }
                });
              }
            }),
      );
    } else if (_currentStatus == RecordingStatus.Recording) {
      return Container(
          child: FlatButton(
        child: Icon(
          Icons.pause,
          size: height * .15,
        ),
        onPressed: () async {
          await recorder.pause();
          setState(() {
            stopTimer = true;
            _currentStatus = RecordingStatus.Paused;
          });
        },
      ));
    } else if (_currentStatus == RecordingStatus.Paused) {
      return Container(
          child: FlatButton(
        child: Icon(
          Icons.play_arrow,
          size: height * .15,
        ),
        onPressed: () async {
          await recorder.resume();
          setState(() {
            stopTimer = false;
            _currentStatus = RecordingStatus.Recording;
          });
        },
      ));
    }
  }

  stopButton() {
    if (_currentStatus != RecordingStatus.Unset) {
      return Container(
        child: FlatButton(
          child: Icon(
            Icons.stop,
            size: height * .15,
          ),
          onPressed: () async {
            result = await recorder.stop();
            setState(() {
              seconds = 0;
              minutes = 0;
              hours = 0;
              _currentStatus = RecordingStatus.Unset;
            });
            rename();
          },
        ),
      );
    } else {
      return Container(
        child: FlatButton(
          child: Icon(
            Icons.stop,
            size: height * .15,
          ),
        ),
      );
    }
  }

  rename() {
    newName = recording.path;
    final TextEditingController _controller = TextEditingController();
    _controller.text = saveName;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: 0));
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Do you want to save"),
            actions: <Widget>[
              Container(
                width: width * .9,
                child: TextField(
                  enableInteractiveSelection: true,
                  controller: _controller,
                  onChanged: (name) {
                    newName = "$appStorage/$name.m4a";
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                      child: FlatButton(
                    child: Text("Cancel"),
                    onPressed: () async {
                      Navigator.pop(context);
                      await File(result.path).delete();

                      Toast.show("Not Saved", context, duration: 2);
                    },
                  )),
                  Container(
                      child: FlatButton(
                    child: Text("Ok"),
                    onPressed: () async {
                      if (newName != null) {
                        var x = await File(result.path).rename(newName);
                        Toast.show("saved to ${x.path}", context, duration: 2);
                      }
                      Navigator.pop(context);
                    },
                  )),
                ],
              )
            ],
          );
        });
  }

  Future<String> getAppStorage() async {
    if (storage == null || mic == null) {}
    bool isPermission = await checkPermission();
    if (isPermission) {
      Directory x = await getExternalStorageDirectory();
      String externalStorage =
          x.path.toString().substring(0, x.path.indexOf("/Android/"));
      appStorage = "$externalStorage/AudioRecorder";
      await Directory(appStorage).create();
      return appStorage;
    } else {
      return null;
    }
  }

  Future<bool> checkPermission() async {
    if (storage == null || mic == null) {
      storage = await Permission.storage.isGranted;
      mic = await Permission.microphone.isGranted;
      return storage && mic;
    } else {
      if (storage && mic) {
        return true;
      } else {
        if (!storage) {
          await Permission.storage.request();
        }
        if (!mic) {
          await Permission.microphone.request();
        }
        storage = await Permission.storage.isGranted;
        mic = await Permission.microphone.isGranted;
        return storage && mic;
      }
    }
  }

  recordingAnimation() {
    if (_currentStatus == RecordingStatus.Recording) {
      return Container(
        child: Stack(
          children: <Widget>[
            Center(
                child: Icon(
              Icons.mic,
              size: height * .1,
            )),
            SpinKitRipple(
              duration: Duration(seconds: 5),
              color: Colors.redAccent,
              size: height,
              borderWidth: 50,
            ),
          ],
        ),
        height: height * .6,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
      );
    } else if (_currentStatus == RecordingStatus.Paused) {
      return Center(
          child: Container(
        height: height * .6,
        child: Icon(
          Icons.mic,
          size: height * .1,
        ),
      ));
    } else {
      return Container(
        child: Center(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SpinKitDoubleBounce(
              size: height * .081,
              color: Colors.red[900],
            ),
            Text(
              "Record",
              style: TextStyle(
                  color: Colors.red,
                  fontSize: height * .1,
                  fontWeight: FontWeight.w900),
            ),
          ],
        )),
        height: height * .6,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30)),
      );
    }
  } 
}

