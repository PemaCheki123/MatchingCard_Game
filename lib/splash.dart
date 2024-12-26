import 'package:flutter/material.dart';
import 'avatar_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_screen.dart';
import 'sound_manager.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();


    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start animation (you can remove this if you don't want any animation)
    _controller.forward();

    // Delay for splash screen
    Future.delayed(const Duration(seconds: 4), () {
      _checkUserSetup();
    });
  }
// Function to check if nickname and avatar are set in SharedPreferences
  void _checkUserSetup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nickname = prefs.getString('nickname');
    String? avatar = prefs.getString('avatar');

    if (nickname != null && avatar != null) {
      // If nickname and avatar are set, navigate to the LevelScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LevelScreen(
            nickname: nickname,
            avatar: avatar,
          ),
        ),
      );
    } else {
      // If nickname and avatar are not set, navigate to AvatarSelectionScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AvatarSelectionScreen()),
      );
    }
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Start playing music when the splash screen appears
    SoundManager().init();
    SoundManager().playBackgroundMusic();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image
          Image.asset(
            'assets/splash.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Text and loading indicator
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.2, // Adjust this value to move the text up
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // App title with increased font size and styling
                Text(
                  'Ghibli Card',
                  style: TextStyle(
                    fontFamily: 'GhibliFont',
                    fontSize: 50, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.5,
                    shadows: [
                      Shadow(
                        offset: Offset(3, 3),
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Divider(
                  color: const Color(0xFFE9972D), // Line color
                  thickness: 3.0,           // Line thickness
                  indent: 100.0,            // Left indent
                  endIndent: 100.0,         // Right indent
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  'A Magical Matching Adventure',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'GhibliFont',
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4, // Thinner indicator
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
