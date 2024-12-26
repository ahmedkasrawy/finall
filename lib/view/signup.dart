import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../emailverify.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signup() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': emailController.text.trim(),
          'userId': user.uid,
          'username': usernameController.text.trim(), // Save manually entered username
        });

        if (!user.emailVerified) {
          await user.sendEmailVerification();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const EmailVerificationScreen(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Signup failed.";
      if (e.code == 'weak-password') {
        errorMessage = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "The account already exists for that email.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is not valid.";
      } else {
        errorMessage = e.message.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> googleSignUp(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google sign-in canceled.")));
        return;
      }

      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      String username = googleUser.email.split('@')[0];
      if (username.length > 5) {
        username = username.substring(0, 5);
      }

      CollectionReference users = FirebaseFirestore.instance.collection('users');
      QuerySnapshot usernameSnapshot = await users.where('username', isEqualTo: username).get();

      if (usernameSnapshot.docs.isNotEmpty) {
        int counter = 1;
        String originalUsername = username;
        while (usernameSnapshot.docs.isNotEmpty) {
          username = '$originalUsername$counter';
          usernameSnapshot = await users.where('username', isEqualTo: username).get();
          counter++;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': googleUser.email,
        'userId': userCredential.user!.uid,
        'username': username,
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google sign-up failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: 'Enter email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Enter password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField( // Username Textfield
                controller: usernameController,
                decoration: const InputDecoration(
                  hintText: 'Enter Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Sign up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () {
                    googleSignUp(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.login),
                      SizedBox(width: 8),
                      Text('Sign up with Google'),
                    ],
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