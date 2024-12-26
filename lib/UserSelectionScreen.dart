import 'package:finall/view/ChatScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSelectionScreen extends StatefulWidget {
  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text("Please log in to use the chat feature.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Select User to Chat'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase(); // Update the search query
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by username...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                // Filter users based on the search query
                final filteredUsers = users.where((user) {
                  final userData = user.data() as Map<String, dynamic>?;
                  if (userData == null) return false;

                  final username = userData['username'] ?? '';
                  return username.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final userData = user.data() as Map<String, dynamic>?; // Safely cast to a Map
                    if (userData == null) {
                      return Container(); // Skip if userData is null
                    }

                    final userId = user.id;
                    final username = userData['username'] ?? 'Unknown User'; // Default to 'Unknown User'

                    if (userId == currentUser.uid) {
                      return Container(); // Skip current user
                    }

                    return ListTile(
                      title: Text(username),
                      onTap: () {
                        final chatId = generateChatId(currentUser.uid, userId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatId,
                              recipientName: username,
                              recipientId: userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String generateChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 ? '$userId1\_$userId2' : '$userId2\_$userId1';
  }
}