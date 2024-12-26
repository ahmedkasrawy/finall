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

  // Corrected generateChatId function
  String generateChatId(String userId1, String userId2) {
    // Use string interpolation correctly:
    return userId1.compareTo(userId2) < 0 ? '${userId1}_$userId2' : '${userId2}_$userId1';
    //OR you can use this
    //return userId1.compareTo(userId2) < 0 ? userId1 + '_' + userId2 : userId2 + '_' + userId1;

  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Select User to Chat")),
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
                  _searchQuery = value.trim().toLowerCase();
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
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No users found."));
                }

                final users = snapshot.data!.docs;

                final filteredUsers = users.where((user) {
                  final userData = user.data() as Map<String, dynamic>?;
                  if (userData == null) return false;

                  final username = userData['username']?.toLowerCase() ?? '';
                  return username.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(child: Text("No users found matching your search."));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final userData = user.data() as Map<String, dynamic>?;
                    if (userData == null) return Container();

                    final userId = user.id;
                    final username = userData['username'] ?? 'Unknown User';
                    final profilePicture = userData['profilePicture'] as String?;

                    if (userId == currentUser.uid) return Container();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
                        child: profilePicture == null ? Icon(Icons.person) : null,
                      ),
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
}