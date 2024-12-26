import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_helper.dart';


int _start = 60;
late Timer _gameTimer;
bool _isGameOver = false;
bool _timerStarted = false;
bool _isPaused = false;
AudioPlayer audioPlayer = AudioPlayer();
bool _canFlip = true;

class CardModel {
  final String image;
  bool isFlipped;
  bool isMatched;

  CardModel({required this.image, this.isFlipped = false, this.isMatched = false});
}

class MainPage extends StatefulWidget {
  final int level;
  final List<String> images;

  MainPage({required this.level, required this.images});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<CardModel> cards = [];
  CardModel? firstSelectedCard;
  CardModel? secondSelectedCard;
  int matchesFound = 0;
  Map<int, bool> levelCompletionStatus = {};
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initializeCards();
    _loadLevelStatus(); // Load completion data on game start

  }



  void _loadLevelStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (int i = 1; i <= 6; i++) { // Assuming 6 levels
      // Only unlock level 1 initially, lock all others
      levelCompletionStatus[i] = prefs.getBool('level_$i') ?? (i == 1);
    }
    setState(() {}); // Refresh UI with loaded data
  }


  Future<void> unlockNextLevel(int completedLevel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_$completedLevel', true); // Mark current level as completed
    levelCompletionStatus[completedLevel] = true;

    // Unlock the next level if it exists
    if (levelCompletionStatus.containsKey(completedLevel + 1)) {
      await prefs.setBool('level_${completedLevel + 1}', true); // Unlock the next level
      levelCompletionStatus[completedLevel + 1] = true;
    }

    setState(() {}); // Refresh UI with updated data
  }



  int getTimeForLevel(int level) {
    if (level == 1) return 60;
    if (level == 2) return 45;
    if (level >= 3 || level <=5 ) return 30;
    return 20;
  }

  void _initializeCards() {
    final allImages = [...widget.images, ...widget.images];
    allImages.shuffle(Random());

    setState(() {
      cards = allImages.map((image) => CardModel(image: image)).toList();
      firstSelectedCard = null;
      secondSelectedCard = null;
      matchesFound = 0;
      _isGameOver = false;
      _isPaused = false;
      _start = getTimeForLevel(widget.level); // Set the time based on level
      _timerStarted = false;
    });
  }



  void _onCardTap(CardModel card) async {
    if (_isPaused || _isGameOver || card.isFlipped || card.isMatched || !_canFlip) return;

    if (!_timerStarted) {
      _startTimer();
      _timerStarted = true;
    }

    setState(() {
      card.isFlipped = true;
    });

    if (firstSelectedCard == null) {
      firstSelectedCard = card;
    } else if (secondSelectedCard == null && card != firstSelectedCard) {
      secondSelectedCard = card;
      _canFlip = false;

      if (firstSelectedCard!.image == secondSelectedCard!.image) {
        setState(() {
          firstSelectedCard!.isMatched = true;
          secondSelectedCard!.isMatched = true;
          matchesFound++;

          // Play the match sound
          _playMatchSound();

          firstSelectedCard = null;
          secondSelectedCard = null;
          _canFlip = true;

          if (matchesFound == widget.images.length) {
            _gameTimer.cancel();
            _isGameOver = true;
            _showPerformanceDialog();
          }
        });
      } else {
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            firstSelectedCard!.isFlipped = false;
            secondSelectedCard!.isFlipped = false;
            firstSelectedCard = null;
            secondSelectedCard = null;
            _canFlip = true;
          });
        });
      }
    }
  }


  Future<void> _playMatchSound() async {
    await audioPlayer.play(AssetSource('assets/right_sound.mp3'));
  }


  void _startTimer() {
    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isGameOver = true;
          _gameTimer.cancel();
          _showGameOverDialog();
        });
      } else {
        if (!_isPaused) {
          setState(() {
            _start--;
          });
        }
      }
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF69697),
          title: Text("Game Over"),
          content: Text("Time's up! Better luck next time.\nDo you want to play again?"),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red, // Red background for 'No' button
              ),
              child: Text("No", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(true); // Navigate back to LevelScreen
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green, // Green background for 'Yes' button
              ),
              child: Text("Yes", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _restartGame(); // Restart the game
              },
            ),
          ],
        );
      },
    );
  }


  void _restartGame() {
    _gameTimer.cancel();
    _initializeCards();
    _startTimer();
  }

  Future<bool> _onWillPop() async {
    _pauseGame();
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFBAD6EB),
        title: Text("Pause Menu"),
        content: Text("Game is paused. What would you like to do?"),
        actions: <Widget>[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue, width: 2),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
              _resumeGame();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, color: Colors.blue),
                SizedBox(width: 6),
                Text("Resume", style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.orange, width: 2),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
              _restartGame();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.replay, color: Colors.orange),
                SizedBox(width: 6),
                Text("Restart", style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red, width: 2),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(true); // Navigate back to the level screen
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, color: Colors.red),
                SizedBox(width: 6),
                Text("Home", style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    ) ?? false;
  }


  void _pauseGame() {
    setState(() {
      _isPaused = true;
      _gameTimer.cancel(); // Stop the timer when paused
    });
  }

  // Resume the game
  void _resumeGame() {
    setState(() {
      _gameTimer.cancel();
      _isPaused = false;
      _startTimer(); // Restart the timer
    });
  }

  void _showPauseDialog() {
    _pauseGame(); // Pause the game
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFBAD6EB),
          title: Text("Pause Menu"),
          content: Text("Game is paused. What would you like to do?"),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue, width: 2),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resumeGame();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Colors.blue),
                  SizedBox(width: 6),
                  Text("Resume", style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange, width: 2),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay, color: Colors.orange),
                  SizedBox(width: 6),
                  Text("Restart", style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red, width: 2),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, color: Colors.red),
                  SizedBox(width: 6),
                  Text("Home", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Background image (placed behind everything else)
            Positioned.fill(
              child: Image.asset(
                'assets/level_background1.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                // Level Title
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 8.0),
                  child: Center(
                    child: Text(
                      'Level : ${widget.level}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'GhibliFont',
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Time and Pause Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Time icon and text
                      Row(
                        children: [
                          Image.asset(
                            'assets/time_icon.png', // Path to your image asset
                            height: 36, // Adjusted size for time icon
                          ),
                          SizedBox(width: 6), // Small space between the image and time text
                          Text(
                            '$_start', // Time value or countdown
                            style: TextStyle(
                              fontSize: 22, // Font size
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Pause button aligned to the right edge
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2), // White border around pause button
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                        child: IconButton(
                          icon: Icon(Icons.pause, color: Colors.white),
                          onPressed: _showPauseDialog,
                        ),
                      ),
                    ],
                  ),
                ),
                // Game Grid
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      constraints: BoxConstraints(maxWidth: 600),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return GestureDetector(
                            onTap: () {
                              _onCardTap(card);
                            },
                            child: Container(
                              height: 120, // Set a fixed height
                              width: 120, // Set a fixed width
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12), // Rounded corners for each card
                                child: AnimatedSwitcher(
                                  duration: Duration(milliseconds: 300),
                                  child: card.isFlipped || card.isMatched
                                      ? Image.asset(
                                    card.image,
                                    key: ValueKey(card.image),
                                    fit: BoxFit.cover, // Ensures the image covers the card entirely
                                  )
                                      : Image.asset(
                                    'assets/card_cover.jpg', // Cover image path
                                    key: ValueKey('cover-$index'),
                                    fit: BoxFit.cover, // Ensures the cover image also covers the entire card
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }






  void _showPerformanceDialog() {
    int stars = _calculateStars();

    if (stars > 0) { // Only unlock the next level if the player earned at least 1 star
      unlockNextLevel(widget.level);

      // Save star rating to the database
      DatabaseHelper.instance.updateStars(widget.level, stars);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Performance"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("You earned $stars star${stars > 1 ? 's' : ''}!"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: Colors.yellow,
                    size: 30,
                  );
                }),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(true); // Navigate back to the level screen
              },
            ),
            TextButton(
              child: Text("Restart"),
              onPressed: () {
                Navigator.of(context).pop(false);
                _restartGame();
              },
            ),
          ],
        );
      },
    );
  }


  int _calculateStars() {
    if (_start > 30) {
      return 3;
    } else if (_start > 15) {
      return 2;
    } else {
      return 1;
    }
  }
}
