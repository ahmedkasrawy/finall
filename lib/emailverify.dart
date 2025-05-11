import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'view/homescreen.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isEmailSent = false;
  bool _isLoading = false;
  bool _isVerifying = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _verificationCheckTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Only send verification email if not already sent
    if (_currentUser != null && !_currentUser!.emailVerified && !_isEmailSent) {
      sendEmailVerification();
    }
    
    // Start automatic verification check
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _verificationCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startVerificationCheck() {
    _verificationCheckTimer?.cancel();
    _verificationCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkEmailVerified();
      }
    });
  }

  Future<void> sendEmailVerification() async {
    if (_currentUser != null && !_currentUser!.emailVerified) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _currentUser!.sendEmailVerification();
        setState(() {
          _isEmailSent = true;
          _resendCooldown = 60;
        });
        _startCooldownTimer();
        Fluttertoast.showToast(
          msg: 'Verification email sent! Please check your inbox.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.message}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_currentUser == null) return;

    try {
      await _currentUser!.reload();
      if (_currentUser!.emailVerified) {
        _verificationCheckTimer?.cancel();
        if (!mounted) return;

        // Show success message
        Fluttertoast.showToast(
          msg: 'Email verified successfully! Logging you in...',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Navigate to home screen and clear the navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error checking email verification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Verify Your Email',
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0.5,
          automaticallyImplyLeading: false,
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Image.asset('assets/kas.png', height: 200, width: 200),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.mark_email_unread,
                        size: 50,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Verification Email Sent',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We have sent a verification link to:\n${_currentUser?.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Please follow these steps:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildStepItem(1, 'Check your email inbox'),
                      _buildStepItem(2, 'Click the verification link'),
                      _buildStepItem(3, 'Return to this screen'),
                      _buildStepItem(4, 'You will be automatically logged in'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                if (_isVerifying)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _isLoading || _resendCooldown > 0
                        ? null
                        : sendEmailVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _resendCooldown > 0
                                ? 'Resend in $_resendCooldown s'
                                : 'Resend Verification Email',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
