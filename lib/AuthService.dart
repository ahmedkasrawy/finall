import 'package:finall/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '148122814027-gf5dss5u0smckg62tuuel6m141lrcq5k.apps.googleusercontent.com',
  );

  // Google Sign-Up method
  Future<void> googleSignUp(BuildContext context) async {
    try {
      // For Web: Explicitly specify the clientId
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '148122814027-gf5dss5u0smckg62tuuel6m141lrcq5k.apps.googleusercontent.com',
      );

      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      // Obtain the Google authentication details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create a credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the Google credential
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // If it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'username': googleUser.displayName ?? 'Unknown User',
          'email': googleUser.email,
          'userId': userCredential.user!.uid,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-up successful!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-up failed: $e")),
      );
    }
  }
}
