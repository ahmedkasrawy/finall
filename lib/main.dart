import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finall/emailverify.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daynnite.dart';
import 'view/homescreen.dart';
import 'view/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize CacheHelper
  await CacheHelper.cacheInitialization();

  // Initialize Firebase only if not already initialized
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCcXlbrnBYbv17NC353NR56L5XSQ6K70uo",
          appId: "1:148122814027:android:56fe216bc5c2ea38412fce",
          messagingSenderId: "148122814027",
          projectId: "final-d40dc",
          storageBucket: "final-d40dc.firebasestorage.app",
        ),
      );
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the "Debug" banner
      title: 'Kasrawy Group',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Start with the splash screen
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
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Delay before navigation
      await Future.delayed(const Duration(seconds: 3));

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // If a user is signed in, navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // Navigate to LoginScreen if no user is signed in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      print('Error checking auth state: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
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

class CacheHelper {
  static SharedPreferences? _preferences;

  /// Initialize SharedPreferences
  static Future<void> cacheInitialization() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Save data to SharedPreferences
  static Future<void> saveData({required String key, required dynamic value}) async {
    if (value is String) {
      await _preferences?.setString(key, value);
    } else if (value is bool) {
      await _preferences?.setBool(key, value);
    } else if (value is int) {
      await _preferences?.setInt(key, value);
    } else if (value is double) {
      await _preferences?.setDouble(key, value);
    }
  }

  /// Retrieve data from SharedPreferences
  static dynamic getData({required String key}) {
    return _preferences?.get(key);
  }

  /// Remove a specific key from SharedPreferences
  static Future<void> removeData({required String key}) async {
    await _preferences?.remove(key);
  }
}
