import 'dart:async';

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:my_audio_player_project/screens/music_visualizer_main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart' show DateFormat;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterSoundPlayer _mPlayer;
  FlutterSoundRecorder _mRecorder;
  StreamSubscription _recorderSubscription;
  StreamSubscription _playerSubscription;

  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _isRecording = false;
  bool _isPlaying;

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  double _dbLevel;
  double _duration;

  String path;
  @override
  void initState() {
    _mPlayer = FlutterSoundPlayer();
    _mRecorder = FlutterSoundRecorder();
    _mPlayer.openAudioSession().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    _mRecorder.openAudioSession().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    _isPlaying = _mPlayer.isPlaying;
    init();

    super.initState();
  }

  init() async {
    await _mRecorder.setSubscriptionDuration(Duration(milliseconds: 10));
    await _mPlayer.setSubscriptionDuration(Duration(milliseconds: 10));
    await initializeDateFormatting();
  }

  @override
  void dispose() {
    _mPlayer.closeAudioSession();
    _mPlayer = null;
    _mRecorder.closeAudioSession();
    cancelRecorderSubscription();
    cancelPlayerSubscriptions();
    _mRecorder = null;
    super.dispose();
  }

  //* RESET RECORDER SUBSCRIPTION
  void cancelRecorderSubscription() {
    if (_recorderSubscription != null) {
      _recorderSubscription.cancel();
      _recorderSubscription = null;
    }
  }

  Future<Directory> tempDir() async {
    return await getTemporaryDirectory();
  }

  void play() async {
    await _mPlayer.startPlayer(
        fromURI: path,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });

    _addListeners();
    print('<--- start player');
    setState(() {
      sliderCurrentPosition = 0.0;
    });
  }

  Future<void> stopPlayer() async {
    try {
      if (_mPlayer != null) {
        await _mPlayer.stopPlayer();
      }
      if (_playerSubscription != null) {
        await _playerSubscription.cancel();
        _playerSubscription = null;
      }
      sliderCurrentPosition = 0.0;
    } on Exception catch (err) {
      print('error: $err');
    }
    setState(() {});
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }
  }

  void _addListeners() {
    cancelPlayerSubscriptions();
    _playerSubscription = _mPlayer.onProgress.listen((event) {
      maxDuration = event.duration.inMilliseconds.toDouble();
      if (maxDuration <= 0) maxDuration = 0.0;

      sliderCurrentPosition =
          min(event.position.inMilliseconds.toDouble(), maxDuration);
      if (sliderCurrentPosition < 0.0) {
        sliderCurrentPosition = 0.0;
      }

      var date = DateTime.fromMillisecondsSinceEpoch(
          event.position.inMilliseconds,
          isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _playerTxt = txt.substring(0, 8);
      });
    });
  }

  void pauseResumePlayer() async {
    try {
      if (_mPlayer.isPlaying) {
        await _mPlayer.pausePlayer();
      } else {
        await _mPlayer.resumePlayer();
      }
    } on Exception catch (err) {
      print('error: $err');
    }
  }

  Future<void> seekToPlayer(int milliSecs) async {
    try {
      if (_mPlayer.isPlaying) {
        await _mPlayer.seekToPlayer(Duration(milliseconds: milliSecs));
      }
    } on Exception catch (err) {
      print('error: $err');
    }
    setState(() {});
  }

//* RECORDING SOUND
  Future<void> record() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    Directory tempDir = await getTemporaryDirectory();
    path = '${tempDir.path}/flutter_sound.mp4';
    await _mRecorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
    );
    print('Recording has started!');

    _recorderSubscription = _mRecorder.onProgress.listen((event) {
      var date = DateTime.fromMillisecondsSinceEpoch(
        event.duration.inMilliseconds,
        isUtc: true,
      );
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _recorderTxt = txt.substring(0, 8);
        _dbLevel = event.decibels;
      });
    });
  }

  Future<void> stopRecorder() async {
    await _mRecorder.stopRecorder();
    cancelRecorderSubscription();
    getDuration();
  }

  Future<void> getDuration() async {
    var d = path != null ? await flutterSoundHelper.duration(path) : null;
    setState(() {
      _duration = d != null ? d.inMilliseconds / 1000.0 : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final _width = MediaQuery.of(context).size.width;
    final _height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('congenial octo eureka'),
        elevation: 0,
      ),
      backgroundColor: primaryColor,
      body: Column(
        children: [
          RichText(
            text: TextSpan(
              text: _recorderTxt,
              style: _theme.textTheme.headline3.copyWith(
                fontSize: _width * 0.1,
                color: Colors.white,
              ),
            ),
          ),
          Spacer(),
          Center(
            child: AvatarGlow(
              animate: _isRecording,
              glowColor: Theme.of(context).accentColor,
              endRadius: _width * 0.3,
              repeat: true,
              duration: const Duration(milliseconds: 2000),
              repeatPauseDuration: const Duration(milliseconds: 100),
              child: GestureDetector(
                onTap: () {
                  print('Mic pressed');
                },
                child: Container(
                  height: _width * 0.2,
                  width: _width * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      print('Mic button pressed');
                      if (_isRecording) {
                        stopRecorder();
                      } else {
                        record();
                      }
                      setState(() {
                        _isRecording = !_isRecording;
                      });
                    },
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: primaryColor,
                      size: _width * 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
          Slider(
              value: min(sliderCurrentPosition, maxDuration),
              min: 0.0,
              max: maxDuration,
              divisions: maxDuration == 0.0 ? 1 : maxDuration.toInt(),
              onChanged: (value) async {
                await seekToPlayer(value.toInt());
              }),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: _width * 0.2,
            ),
            onPressed: () {
              if (_isPlaying) {
              } else {
                play();
              }
            },
          ),
          Spacer(),
          RichText(
            text: TextSpan(
              text: _duration.toString(),
              style: _theme.textTheme.headline3.copyWith(
                fontSize: _width * 0.1,
                color: Colors.white,
              ),
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Musicvisualizer()),
              );
            },
            child: Text('Move'),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
