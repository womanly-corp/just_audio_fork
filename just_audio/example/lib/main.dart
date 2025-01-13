// This is a minimal example demonstrating a play/pause button and a seek bar.
// More advanced examples demonstrating other features can be found in the same
// directory as this example in the GitHub repository.

import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_example/common.dart';
import 'package:rxdart/rxdart.dart';

class LogItem {
  final String message;
  final Color color;
  final String timestamp;

  LogItem(this.message, this.color)
      : timestamp =
            DateTime.now().toIso8601String().split('T').last.substring(0, 8);
}

void main() => runApp(const MyApp());

final List<dynamic> jsonData = json.decode(
    '''[{"id":1001,"audio":"1.mp4","title":"Opening Сredits","duration":18.514},{"id":1002,"audio":"2.mp4","title":"Prologue","duration":173.277},{"id":2001,"audio":"3.mp4","title":"Chapter 1","duration":1220.322},{"id":2002,"audio":"4.mp4","title":"Chapter 2","duration":1190.143},{"id":2003,"audio":"5.mp4","title":"Chapter 3","duration":1058.006},{"id":2004,"audio":"6.mp4","title":"Chapter 4","duration":1360.562},{"id":2005,"audio":"7.mp4","title":"Chapter 5","duration":945.097},{"id":2006,"audio":"8.mp4","title":"Chapter 6","duration":1229.788},{"id":2007,"audio":"9.mp4","title":"Chapter 7","duration":3341.163},{"id":2008,"audio":"10.mp4","title":"Chapter 8","duration":2129.973},{"id":2009,"audio":"11.mp4","title":"Chapter 9","duration":769.638},{"id":2010,"audio":"12.mp4","title":"Chapter 10","duration":643.712},{"id":2011,"audio":"13.mp4","title":"Chapter 11","duration":961.687},{"id":2012,"audio":"14.mp4","title":"Chapter 12","duration":827.52},{"id":2013,"audio":"15.mp4","title":"Chapter 13","duration":2001.83},{"id":2014,"audio":"16.mp4","title":"Chapter 14","duration":1145.287},{"id":2015,"audio":"17.mp4","title":"Chapter 15","duration":466.332},{"id":2016,"audio":"18.mp4","title":"Chapter 16","duration":214.301},{"id":2017,"audio":"19.mp4","title":"Chapter 17","duration":645.702},{"id":2018,"audio":"20.mp4","title":"Chapter 18","duration":1072.179},{"id":2019,"audio":"21.mp4","title":"Chapter 19","duration":1013.464},{"id":2020,"audio":"22.mp4","title":"Chapter 20","duration":481.883},{"id":2021,"audio":"23.mp4","title":"Chapter 21","duration":924.12},{"id":2022,"audio":"24.mp4","title":"Chapter 22","duration":1959.791},{"id":2023,"audio":"25.mp4","title":"Chapter 23","duration":864.144},{"id":2024,"audio":"26.mp4","title":"Chapter 24","duration":610.844},{"id":2025,"audio":"27.mp4","title":"Chapter 25","duration":1204.136},{"id":2026,"audio":"28.mp4","title":"Chapter 26","duration":861.872},{"id":2027,"audio":"29.mp4","title":"Chapter 27","duration":1789.687},{"id":2028,"audio":"30.mp4","title":"Chapter 28","duration":1080.673},{"id":2029,"audio":"31.mp4","title":"Chapter 29","duration":912.708},{"id":2030,"audio":"32.mp4","title":"Chapter 30","duration":534.5},{"id":2031,"audio":"33.mp4","title":"Chapter 31","duration":77.887},{"id":2032,"audio":"34.mp4","title":"Chapter 32","duration":564.495},{"id":2033,"audio":"35.mp4","title":"Chapter 33","duration":673.418},{"id":2034,"audio":"36.mp4","title":"Chapter 34","duration":581.954},{"id":2035,"audio":"37.mp4","title":"Chapter 35","duration":857.103},{"id":2036,"audio":"38.mp4","title":"Chapter 36","duration":589.71},{"id":2037,"audio":"39.mp4","title":"Chapter 37","duration":535.423},{"id":3001,"audio":"40.mp4","title":"Epilogue","duration":322.736},{"id":3002,"audio":"41.mp4","title":"Closing Credits","duration":38.709}]''');

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _player = AudioPlayer();

  // Константы для минимальной и максимальной высоты лога
  static const double _minLogHeightPercentage = 0.1; // 10% от высоты экрана
  static const double _maxLogHeightPercentage = 0.9; // 50% от высоты экрана

  final List<LogItem> _logMessages = []; // Лог сообщений
  double _logHeight; // Высота области лога

  MyAppState() : _logHeight = 400; // Начальная высота области лога

  // Метод для добавления сообщений в лог
  void addLog(String message, Color color) {
    setState(() {
      _logMessages
          .add(LogItem(message, color)); // Использование нового класса LogItem
    });
  }

  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
    _player.playerStateStream.listen(onPlayerStateChanged);
    _player.positionDiscontinuityStream.listen(onPositionDiscontinuity);
  }

  void onPositionDiscontinuity(PositionDiscontinuity event) {
    addLog("${event.reason.name} :: ${event.previousEvent} -> ${event.event}",
        Colors.red);
  }

  void onPlayerStateChanged(PlayerState state) {
    addLog(
        "${state.playing ? "Playing" : "Pause"}"
        "[${_player.currentIndex}]"
        ": ${state.processingState.name}",
        Colors.green);
  }

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    // Try to load audio from a source and catch any errors.
    try {
      final playlist = preparePlaylist();

      // AAC example: https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.aac
      await _player.setAudioSource(playlist, initialIndex: 0);
    } on PlayerException catch (e) {
      print("Error loading audio source: $e");
    }
  }

  AudioSource preparePlaylist() {
    // Парсинг JSON

    final result = ConcatenatingAudioSource(
      children: [
        ...jsonData.map((item) {
          return ProgressiveAudioSource(
            Uri.parse("https://static.wromance.com/6/" + item['audio']),
          );
        }).toList(),
        // ... существующий код для добавления глав книги
      ],
    );

    return result;
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    // Release decoders and buffers back to the operating system making them
    // available for other apps to use.
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      _player.stop();
    }
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest4<Duration, Duration, Duration?, int?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          _player.currentIndexStream,
          (position, bufferedPosition, duration, currentIndex) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  Stream get _chaptersStream => _player.sequenceStream;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final minLogHeight = screenHeight * _minLogHeightPercentage;
    final maxLogHeight = screenHeight * _maxLogHeightPercentage;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<PositionData>(
                stream: _positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data;
                  final currentTrackNumber = (_player.currentIndex ?? -1) + 1;
                  final String currentTrackTitle = (_player.currentIndex !=
                              null &&
                          _player.currentIndex! >= 0 &&
                          _player.currentIndex! < jsonData.length)
                      ? jsonData[_player.currentIndex!]['title']
                      : "Current track title"; // Получаем название текущего трека из jsonData
                  return Column(
                    children: [
                      Text(
                        currentTrackTitle,
                        style: const TextStyle(fontSize: 20),
                      ),
                      ControlButtons(_player),
                    ],
                  );
                },
              ),
              // Display play/pause button and volume/speed sliders.
              // Display seek bar. Using StreamBuilder, this widget rebuilds
              // each time the position, buffered position or duration changes.
              StreamBuilder<PositionData>(
                stream: _positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data;
                  return Column(
                    children: [
                      SeekBar(
                        duration: positionData?.duration ?? Duration.zero,
                        position: positionData?.position ?? Duration.zero,
                        bufferedPosition:
                            positionData?.bufferedPosition ?? Duration.zero,
                        onChangeEnd: _player.seek,
                      ),
                      Text(
                        'Buffered: ${((positionData?.bufferedPosition ?? Duration.zero) - (positionData?.position ?? Duration.zero)).inMinutes} мин ${((positionData?.bufferedPosition ?? Duration.zero) - (positionData?.position ?? Duration.zero)).inSeconds.remainder(60)} сек',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                },
              ),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final PlayerState? data = snapshot.data;
                  return Column(
                    children: [
                      Text(
                        data?.playing ?? false ? "Playing" : "Pause",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${data?.processingState.toString()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  );
                },
              ),
              // Разделитель
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _logHeight -= details.delta.dy;
                    if (_logHeight < minLogHeight) _logHeight = minLogHeight;
                    if (_logHeight > maxLogHeight) _logHeight = maxLogHeight;
                  });
                },
                child: Container(
                  color: Colors.grey,
                  width: double.infinity,
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                ),
              ),
              Stack(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    height: _logHeight,
                    child: ListView.builder(
                      itemCount: _logMessages.length,
                      itemBuilder: (context, indexOriginal) {
                        final int index =
                            _logMessages.length - 1 - indexOriginal;
                        final LogItem logItem = _logMessages[index];
                        final String message = logItem.message;
                        final Color messageColor = logItem.color;
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: logItem.timestamp,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: " $message",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: messageColor,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _logMessages.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the play/pause button and volume/speed sliders.
class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Opens volume slider dialog
        if (false)
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Adjust volume",
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: player.volume,
                stream: player.volumeStream,
                onChanged: player.setVolume,
              );
            },
          ),

        /// This StreamBuilder rebuilds whenever the player state changes, which
        /// includes the playing/paused state and also the
        /// loading/buffering/ready state. Depending on the state we show the
        /// appropriate button or loading indicator.
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 48.0,
                height: 48.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 48.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 48.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 48.0,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 48.0,
              onPressed: player.hasPrevious ? player.seekToPrevious : null,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 48.0,
              onPressed: player.hasNext ? player.seekToNext : null,
            ),
            IconButton(
              icon: const Icon(Icons.forward_10),
              iconSize: 48.0,
              onPressed: () {
                player.seek(player.position + const Duration(seconds: 10));
              },
            ),
          ],
        ),
        // Opens speed slider dialog
        if (false)
          StreamBuilder<double>(
            stream: player.speedStream,
            builder: (context, snapshot) => IconButton(
              icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                showSliderDialog(
                  context: context,
                  title: "Adjust speed",
                  divisions: 10,
                  min: 0.5,
                  max: 1.5,
                  value: player.speed,
                  stream: player.speedStream,
                  onChanged: player.setSpeed,
                );
              },
            ),
          ),
      ],
    );
  }
}
