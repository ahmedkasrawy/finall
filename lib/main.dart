import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finall/emailverify.dart';
import 'package:finall/view/bnpl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'view/homescreen.dart';
import 'view/login_screen.dart';

// Define app colors
class AppColors {
  static const primary = Color(0xFF1E3D59);
  static const secondary = Color(0xFFFF6E40);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFB00020);
  static const success = Color(0xFF4CAF50);
  static const textPrimary = Color(0xFF1E3D59);
  static const textSecondary = Color(0xFF757575);
}
class FirebaseConfig {
  static const apiKey = "AIzaSyCcXlbrnBYbv17NC353NR56L5XSQ6K70uo";
  static const appId = "1:148122814027:android:56fe216bc5c2ea38412fce";
  static const messagingSenderId = "148122814027";
  static const projectId = "final-d40dc";
  static const storageBucket = "final-d40dc.firebasestorage.app";
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize CacheHelper
    await CacheHelper.cacheInitialization();

    // Initialize Firebase only if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          appId: FirebaseConfig.appId,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
        ),
      );
    }
  } catch (e) {
    debugPrint('Initialization error: $e');
    // Handle initialization error gracefully
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasrawy Group',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.error,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: AppColors.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.white,
          contentTextStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          behavior: SnackBarBehavior.floating,
          width: double.infinity,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          if (snapshot.hasData) {
            return HomeScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
      await Future.delayed(const Duration(seconds: 5));

      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

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
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      if (!mounted) return;
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      // Navigate to login screen as fallback
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  'assets/kisovid.gif',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // App Name
            Text(
              'Kasrawy Group',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            Text(
              'Your Trusted Car Rental Partner',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class CacheHelper {
  static SharedPreferences? _preferences;

  /// Initialize SharedPreferences
  static Future<void> cacheInitialization() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Save data to SharedPreferences
  static Future<bool> saveData({required String key, required dynamic value}) async {
    if (_preferences == null) {
      await cacheInitialization();
    }

    if (value is String) {
      return await _preferences?.setString(key, value) ?? false;
    } else if (value is bool) {
      return await _preferences?.setBool(key, value) ?? false;
    } else if (value is int) {
      return await _preferences?.setInt(key, value) ?? false;
    } else if (value is double) {
      return await _preferences?.setDouble(key, value) ?? false;
    }
    return false;
  }

  /// Retrieve data from SharedPreferences
  static dynamic getData({required String key}) {
    if (_preferences == null) {
      return null;
    }
    return _preferences?.get(key);
  }

  /// Remove a specific key from SharedPreferences
  static Future<bool> removeData({required String key}) async {
    if (_preferences == null) {
      await cacheInitialization();
    }
    return await _preferences?.remove(key) ?? false;
  }
}