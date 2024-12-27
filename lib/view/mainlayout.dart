import 'package:flutter/material.dart';
import '../ProfileScreen.dart';
import 'homescreen.dart';
import 'FavoritesScreen.dart';
import 'UserSelectionScreen.dart';
import 'bottom.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const MainLayout({
    Key? key,
    required this.child,
    required this.selectedIndex,
  }) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1: // Favorites
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FavoritesScreen()),
        );
        break;
      case 2: // Chat (User Selection Screen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserSelectionScreen()),
        );
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigation(
        selectedIndex: selectedIndex,
        onItemTapped: (index) => _onItemTapped(context, index),
      ),
    );
  }
}
