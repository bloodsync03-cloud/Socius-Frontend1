import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTANT: Update this import to match the exact file name where ChatPage is located!
// If your file is named user_chat.dart, this should be:
import 'package:cyber_bullying_detection/user_chat.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List chatList = [];
  String baseUrl = "";
  String lid = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBaseUrlAndId();
  }

  // 1. Get the logged-in user ID and the base server URL
  Future<void> loadBaseUrlAndId() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    setState(() {
      baseUrl = sh.getString('url') ?? "";
      lid = sh.getString('lid') ?? "";
    });

    if (lid.isNotEmpty && baseUrl.isNotEmpty) {
      loadRecentChats();
    } else {
      setState(() => isLoading = false);
      print("❌ ERROR: Missing lid or baseUrl in SharedPreferences");
    }
  }

  // 2. Fetch the inbox list from your new Django API
  Future<void> loadRecentChats() async {
    try {
      var response = await http.post(
        Uri.parse("$baseUrl/user_view_recent_chats/"),
        body: {'lid': lid},
      );

      var jsonData = json.decode(response.body);
      if (jsonData['status'] == 'ok') {
        setState(() {
          chatList = jsonData['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("❌ loadRecentChats FAILED: ${jsonData['message']}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ loadRecentChats ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Chats"),
        backgroundColor: const Color(0xFF6A11CB),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatList.isEmpty
          ? const Center(child: Text("No recent chats found.", style: TextStyle(fontSize: 16)))
          : ListView.builder(
        itemCount: chatList.length,
        itemBuilder: (context, index) {
          final chat = chatList[index];

          // --- THIS IS THE ONLY PART THAT WAS UPDATED ---
          // Remove '/myapp' from the base URL so we get the root server URL for media
          String rootUrl = baseUrl.replaceAll('/myapp', '');

          // Safely construct the photo URL using the new rootUrl
          final String photoUrl = (chat['photo'] != null && chat['photo'] != "")
              ? "$rootUrl${chat['photo']}"
              : "https://via.placeholder.com/150";
          // ----------------------------------------------

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // The user's avatar picture
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(photoUrl),
              onBackgroundImageError: (exception, stackTrace) {
                print("Image load error for ${chat['name']}");
              },
            ),
            // The user's name
            title: Text(
              chat['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            // The last message sent between you two
            subtitle: Text(
              chat['last_message'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // The time the last message was sent
            trailing: Text(
              chat['time'],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            // 3. Navigate to the ChatPage when tapped!
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    toId: chat['other_user_id'].toString(), // Passing their ID to ChatPage
                    name: chat['name'], // Passing their name to ChatPage
                  ),
                ),
              ).then((_) {
                // This runs when you press the back button to leave the chat.
                // It refreshes the list so the latest message updates!
                loadRecentChats();
              });
            },
          );
        },
      ),
    );
  }
}