import 'dart:ui'; // Import this to use ImageFilter
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'level_screen.dart';

class AvatarSelectionScreen extends StatefulWidget {
  @override
  _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String? selectedAvatar;
  final TextEditingController nicknameController = TextEditingController();

  final List<String> avatars = [
    'assets/avater1.gif',
    'assets/avater2.gif',
    'assets/avater3.gif',
    'assets/avater4.gif',
    'assets/avater5.gif',
    'assets/avater6.gif',
  ];

  void _onNext() async {
    if (nicknameController.text.isNotEmpty && selectedAvatar != null) {
      try {
        // Insert the selected data into the SQLite database
        Map<String, dynamic> userData = {
          DatabaseHelper.columnNickname: nicknameController.text,
          DatabaseHelper.columnAvatar: selectedAvatar!,
          DatabaseHelper.columnLevel: 1, // Start at level 1
        };

        // Save the user data to SQLite
        await DatabaseHelper.instance.insertUser(userData);  // Use the insertUser method

        // Save to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('nickname', nicknameController.text);
        await prefs.setString('avatar', selectedAvatar!);
        await prefs.setBool('isFirstRun', false);

        // Navigate to the LevelScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelScreen(
              nickname: nicknameController.text,
              avatar: selectedAvatar!,
            ),
          ),
        );
      } catch (e) {
        print("Error inserting user data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an avatar and enter a nickname.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image
          Image.asset(
            'assets/avater_background.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Apply a blur effect
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10.0, // Horizontal blur amount
              sigmaY: 10.0, // Vertical blur amount
            ),
            child: Container(
              color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
              // Title
              Text(
              'Choose Your Character',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                fontFamily: 'GhibliFont', // Use a custom font if available
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),

// Reduced height to decrease space
            SizedBox(height: 20),

// Nickname input field
            TextField(
              controller: nicknameController,
              decoration: InputDecoration(
                labelText: 'Enter Nickname',
                labelStyle: TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                prefixIcon: Icon(Icons.person, color: Colors.black),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              style: TextStyle(color: Colors.black),
            ),
                SizedBox(height: 27),

                // Avatar selection
                Text(
                  'Select an Avatar:',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 22),

                // Center the avatars
                Center(
                  child: Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    alignment: WrapAlignment.center, // Center align the avatars
                    children: avatars.map((avatar) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAvatar = avatar;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedAvatar == avatar
                                ? Color(0xFF87AECE)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            avatar,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: 50),

                // Next button
                ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF87AECE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
