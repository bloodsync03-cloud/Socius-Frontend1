import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'view_other_user_profile.dart';

class AcceptedFriendsPage extends StatefulWidget {
  const AcceptedFriendsPage({super.key});

  @override
  State<AcceptedFriendsPage> createState() => _AcceptedFriendsPageState();
}

class _AcceptedFriendsPageState extends State<AcceptedFriendsPage> {
  // We keep TWO lists now: one for the raw data, one for the searched data
  List allFriends = [];
  List filteredFriends = [];
  bool isLoading = true;

  String lid = "";
  String url = "";
  String imgUrl = "";

  // Controller to read what the user is typing
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  // ---------------- LOAD FRIENDS ----------------
  Future<void> loadFriends() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    lid = sh.getString('lid') ?? "";
    url = sh.getString('url') ?? "";
    imgUrl = sh.getString('img_url') ?? "";

    if (lid.isEmpty || url.isEmpty) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('$url/user_view_accepted_friends/'),
        body: {'lid': lid},
      );

      if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'ok') {
          if (mounted) {
            setState(() {
              allFriends = data['data'];
              filteredFriends = allFriends; // Initially, show everyone
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Load friends error: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  // ---------------- SEARCH LOGIC ----------------
  void _runSearch(String query) {
    List results = [];
    if (query.isEmpty) {
      // If the search bar is empty, show all friends
      results = allFriends;
    } else {
      // Filter the list by name OR username
      results = allFriends.where((user) {
        final nameLower = user['name'].toString().toLowerCase();
        final usernameLower = user['username'].toString().toLowerCase();
        final searchLower = query.toLowerCase();

        return nameLower.contains(searchLower) || usernameLower.contains(searchLower);
      }).toList();
    }

    // Update the UI with the filtered list instantly
    setState(() {
      filteredFriends = results;
    });
  }

  // ---------------- IMAGE URL ----------------
  String getImage(String photo) {
    if (photo.isEmpty) return "";
    return imgUrl.endsWith('/') ? imgUrl + photo : '$imgUrl/$photo';
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Friends", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4361EE),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // ---> THE NEW SEARCH BAR <---
          Container(
            color: const Color(0xFF4361EE),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runSearch(value),
              decoration: InputDecoration(
                hintText: "Search friends...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ---> THE FRIEND LIST <---
          Expanded(
            child: filteredFriends.isEmpty
                ? const Center(
              child: Text(
                "No friends found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredFriends.length,
              itemBuilder: (context, index) {
                final user = filteredFriends[index];

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: user['photo'] != null && user['photo'].toString().isNotEmpty
                          ? NetworkImage(getImage(user['photo']))
                          : null,
                      child: user['photo'] == null || user['photo'].toString().isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      user['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "@${user['username']}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),

                    // ---> CLICK TO VIEW PROFILE <---
                    onTap: () {
                      // Navigate straight to the OtherUserProfilePage!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfilePage(
                            targetUserId: user['login_id'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}