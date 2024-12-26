import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

class SoundManager with WidgetsBindingObserver {
  static final SoundManager _instance = SoundManager._internal();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isSoundEnabled = true;

  factory SoundManager() {
    return _instance;
  }

  SoundManager._internal();

  Future<void> playBackgroundMusic() async {
    if (isSoundEnabled) {
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource('background_music.mp3'));
    }
  }

  void stopBackgroundMusic() {
    audioPlayer.stop();
  }

  void toggleSound(bool enabled) {
    isSoundEnabled = enabled;
    if (isSoundEnabled) {
      playBackgroundMusic();
    } else {
      stopBackgroundMusic();
    }
  }

  // Lifecycle methods
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // Stop the music when the app goes into the background
      stopBackgroundMusic();
    } else if (state == AppLifecycleState.resumed) {
      // Optionally, resume the music if the app comes back to the foreground
      if (isSoundEnabled) {
        playBackgroundMusic();
      }
    }
  }

  void init() {
    // Add the observer to listen for lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    // Remove the observer when done to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    stopBackgroundMusic(); // Stop music when disposed
  }
}
