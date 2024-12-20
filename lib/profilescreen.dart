import 'package:finall/search.dart';
import 'package:flutter/material.dart';

import 'homescreen.dart';
import 'mytransactions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false; // Tracks the current theme

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: ProfileScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final VoidCallback toggleTheme; // Function to toggle theme
  final bool isDarkMode;

  ProfileScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              icon: Icon(Icons.arrow_back),
            ),
            SizedBox(width: 8.0),
            Text('My Profile'),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50.0,
                backgroundImage: NetworkImage(
                    'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg'),
              ),
              SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "First Name",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 16.0),
                  Text(
                    "Last Name",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement Wallet functionality here
                },
                icon: Icon(Icons.wallet, size: 30),
                label: Text('Wallet'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement My Bookings functionality here
                },
                icon: Icon(Icons.calendar_month, size: 30),
                label: Text('My Bookings'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyTransactions()),
                  );
                },
                icon: Icon(Icons.handshake_rounded, size: 30),
                label: Text('My Transactions'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                ),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: toggleTheme,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                ),
                child: Text(
                  isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Logout functionality can be implemented here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(200, 50),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              icon: Image.asset(
                'assets/home.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                onTap: () {
                  // Navigate to the SearchScreen when the TextField is tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                };
                },
              icon: Image.asset(
                'assets/magnifying-glass.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                // Profile screen button; no navigation needed here
              },
              icon: Image.asset(
                'assets/user.png', // Replace with your asset path
                width: 24,
                height: 24,
              ),
              iconSize: 40,
            ),
          ],
        ),
      ),
    );
  }
}