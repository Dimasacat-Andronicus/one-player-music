import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Player Music',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
        ).copyWith(primary: Color(0xFF355C7D), secondary: Color(0xFFF8B195)),
      ),
      home: Scaffold(body: const MusicPage()),
    );
  }
}

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final AudioPlayer musicPlayer = AudioPlayer();
  double _volume = 1.0;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  int _currentTrackIndex = 0;
  String _currentTrackName = '';

  final List<String> _audioTracks = [
    'assets/music/Byahe - Jroa.wav',
    'assets/music/I want it that way - Backstreet Boys.wav',
    'assets/music/Super Shy - NewJeans.wav',
  ];

  final List<String> _audioImages = [
    'assets/image/byahe.jpg',
    'assets/image/iwantitthatway.jpg',
    'assets/image/supershy.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadVolumeAndPosition().then((_) {
      _initMusic();
    });
    _listenToPositionChanges();
    _listenToPlayerStateChanges();
  }

  Future<void> _loadVolumeAndPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('volume') ?? 1.0;
      musicPlayer.setVolume(_volume);

      _currentTrackIndex = prefs.getInt('trackIndex') ?? 0;
      final int? savedPositionMillis = prefs.getInt('position');
      if (savedPositionMillis != null) {
        _currentPosition = Duration(milliseconds: savedPositionMillis);
      }
    });
  }

  Future<void> _initMusic() async {
    try {
      await musicPlayer.setAsset(_audioTracks[_currentTrackIndex]);
      _duration = (musicPlayer.duration) ?? Duration.zero;
      _currentTrackName = _audioTracks[_currentTrackIndex]
          .split('/')
          .last
          .replaceAll('.wav', '');

      if (_currentPosition != Duration.zero) {
        await musicPlayer.seek(_currentPosition);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading audio source: $e");
      }
    }
  }

  Future<void> _saveVolume(double volume) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume', volume);
  }

  Future<void> _savePosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('position', _currentPosition.inMilliseconds);
    await prefs.setInt('trackIndex', _currentTrackIndex);
  }

  void _listenToPositionChanges() {
    musicPlayer.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  void _listenToPlayerStateChanges() {
    musicPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_currentTrackIndex == _audioTracks.length - 1) {
          musicPlayer.pause();
          setState(() {
            _isPlaying = false;
          });
        } else {
          _nextTrack();
        }
      } else if (state.processingState == ProcessingState.ready) {
        _savePosition();
      }
    });
  }

  void _togglePlayPause() {
    if (musicPlayer.playing) {
      musicPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      musicPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _nextTrack() {
    if (_currentTrackIndex < _audioTracks.length - 1) {
      _currentTrackIndex++;
      _initMusic().then((_) {
        musicPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      });
    }
  }

  void _previousTrack() {
    if (_currentTrackIndex > 0) {
      _currentTrackIndex--;
      _initMusic().then((_) {
        musicPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _savePosition();
    musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                _currentTrackName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Image.asset(
                  _audioImages[_currentTrackIndex],
                  key: ValueKey<String>(_audioImages[_currentTrackIndex]),
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    color: Colors.white,
                    onPressed: _previousTrack,
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    iconSize: 55,
                    onPressed: _togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    color: Colors.white,
                    onPressed: _nextTrack,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Playback Position',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  if (_duration > Duration.zero)
                    Column(
                      children: [
                        Slider(
                          value: _currentPosition.inSeconds.toDouble(),
                          min: 0.0,
                          max: _duration.inSeconds.toDouble(),
                          divisions:
                              _duration.inSeconds > 0
                                  ? _duration.inSeconds
                                  : null,
                          activeColor: Colors.white,
                          inactiveColor: Colors.grey,
                          onChanged: (value) {
                            setState(() {
                              _currentPosition = Duration(
                                seconds: value.round(),
                              );
                              musicPlayer.seek(_currentPosition);
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currentPosition.toString().split('.').first,
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _duration.toString().split('.').first,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                        musicPlayer.setVolume(value);
                      });
                      _saveVolume(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
