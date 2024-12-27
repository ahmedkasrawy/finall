import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finall/view/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'homescreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  Future<void> login() async {
    if (userEmailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "Both fields are required.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String userInput = userEmailController.text.trim();
    final String password = passwordController.text.trim();

    try {
      String emailToLogin = userInput;

      // If input is not an email, treat it as a username
      if (!userInput.contains('@')) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: userInput)
            .get();

        if (userQuery.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this username.',
          );
        }

        emailToLogin = userQuery.docs.first.data()['email'];
      }

      // Authenticate with Firebase using email
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToLogin,
        password: password,
      );

      // Navigate to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorMessage = "No user found for this email or username.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password. Please try again.";
        } else {
          errorMessage = "An error occurred: ${e.message}";
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/kas.png', height: 200, width: 200),
              const SizedBox(height: 16),
              // Username or Email Field
              TextField(
                controller: userEmailController,
                decoration: const InputDecoration(
                  hintText: 'Username or Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Navigate to Signup
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
                child: const Text(
                  'Don’t have an account? Sign up!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
