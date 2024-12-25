import 'package:finall/view/homescreen.dart';
import 'package:finall/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'wallet.dart';
import 'mytransactions.dart';
import 'settings.dart';

class ProfileScreen extends StatelessWidget {
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user is logged in.')),
        );
        return;
      }

      // Delete user data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete user from FirebaseAuth
      await user.delete();

      // Navigate to the login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50.0,
                backgroundImage: NetworkImage(
                  user?.photoURL ??
                      'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg',
                ),
              ),
              SizedBox(height: 24.0),
              Text(
                user?.displayName ?? "No Name",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? "No Email",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 24.0),
              _buildProfileOption(
                context,
                label: 'Wallet',
                icon: Icons.wallet,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentPage()),
                  );
                },
              ),
              _buildProfileOption(
                context,
                label: 'My Transactions',
                icon: Icons.handshake_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyTransactions()),
                  );
                },
              ),
              _buildProfileOption(
                context,
                label: 'Settings',
                icon: Icons.settings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(200, 50),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _deleteAccount(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(200, 50),
                ),
                child: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 1:
            // Navigate to Favorites
              break;
            case 2:
            // Navigate to Search
              break;
            case 3:
            // Already on the Profile screen
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('Logout'),
            content: Text('Are you sure you want to log out?'),
            actions: [
            TextButton(
            onPressed: () {
          Navigator.of(context).pop(); // Close the dialog
        },
        child: Text('Cancel'),
        ),
        TextButton(
        onPressed: () {
        FirebaseAuth.instance.signOut();
        Navigator.of(context).pop(); // Close the dialog
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        },
        child: Text("Yes, i'm sure"),
        ),
        ],
        );
      },
    );
  }

  Widget _buildProfileOption(BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.blue),
        title: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: onTap,
      ),
    );
  }
}
