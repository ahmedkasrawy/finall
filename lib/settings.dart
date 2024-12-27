import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ProfileScreeen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? username;
  String? email;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          username = userDoc.data()?['username'] ?? 'No Name';
          email = user.email ?? 'No Email';
        });
      } catch (e) {
        print('Error fetching user details: $e');
        setState(() {
          username = 'No Name';
          email = 'No Email';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // Profile Section
          _buildProfileSection(context),
          Divider(thickness: 1),
          // Settings Options
          _buildSettingsOption(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          _buildSettingsOption(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () => _showPrivacyPolicy(context),
          ),
          _buildSettingsOption(
            context,
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () => _showTermsOfService(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          username ?? 'Loading...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(email ?? 'Loading...'),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
      ),
    );
  }

  Widget _buildSettingsOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(icon, size: 28, color: Colors.blueAccent),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: trailing,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
      onTap: onTap,
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showBottomSheet(
      context,
      title: 'Privacy Policy',
      content:
      'Your privacy is important to us. We collect and use your personal information in accordance with our Privacy Policy. Please review our Privacy Policy for more details.',
    );
  }

  void _showTermsOfService(BuildContext context) {
    _showBottomSheet(
      context,
      title: 'Terms of Service',
      content:
      'By using our car rental service, you agree to the following terms and conditions:\n\n'
          '- You must be at least 18 years old to rent a car.\n'
          '- You must have a valid driver\'s license.\n'
          '- You are responsible for any damages to the car.\n'
          '- You agree to pay all fees and charges associated with your rental.\n\n'
          'Please review our full terms of service for more details.',
    );
  }

  void _showBottomSheet(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              Text(
                content,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              SizedBox(height: 24.0),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: Size(120, 40),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
