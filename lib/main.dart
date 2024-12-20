import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daynnite.dart';
import 'homescreen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.cacheInitialization(); // Initialize CacheHelper

  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Initialize Firebase only if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCcXlbrnBYbv17NC353NR56L5XSQ6K70uo",
        appId: "1:148122814027:android:56fe216bc5c2ea38412fce",
        messagingSenderId: "148122814027",
        projectId: "final-d40dc",
        storageBucket: "final-d40dc.firebasestorage.app",
      ),
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stay Logged In Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Start with the splash screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after a fixed duration
    Future.delayed(const Duration(seconds: 3), () {
      // Check authentication state and navigate accordingly
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white38,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/kisovid.gif', // Replace with your GIF path
              fit: BoxFit.fill,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthStateCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Navigate based on authentication state
    if (user != null) {
      return HomeScreen(); // Navigate to HomeScreen if authenticated
    } else {
      return LoginScreen(); // Navigate to LoginScreen if not authenticated
    }
  }
}
