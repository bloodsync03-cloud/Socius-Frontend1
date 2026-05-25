import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ViewCommentsPage extends StatefulWidget {
  final String postId;

  const ViewCommentsPage({
    super.key,
    required this.postId,
  });

  @override
  State<ViewCommentsPage> createState() => _ViewCommentsPageState();
}

class _ViewCommentsPageState extends State<ViewCommentsPage> {
  List comments = [];
  bool loading = true;
  bool isSending = false;

  String imgUrl = "";
  // ---> NEW: Variable to hold the current user's profile photo <---
  String currentUserPhoto = "";

  // Controller for the new comment text field
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String getSafeImageUrl(String path) {
    if (path.isEmpty || path == "null") return "";
    if (path.startsWith("http")) return path;
    return imgUrl.endsWith("/") ? "$imgUrl$path" : "$imgUrl/$path";
  }

  Future<void> fetchComments() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url')!;
      String lid = sh.getString('lid')!;

      // Save the base image URL from shared preferences
      imgUrl = sh.getString('img_url') ?? "";

      // ---> NEW: Fetch the logged-in user's photo from SharedPreferences <---
      String savedPhoto = sh.getString('photo') ?? "";
      if (mounted) {
        setState(() {
          currentUserPhoto = getSafeImageUrl(savedPhoto);
        });
      }

      final res = await http.post(
        Uri.parse('$url/userviewcomment/'),
        body: {
          'lid': lid,
          'post_id': widget.postId,
        },
      );

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            comments = jsonData['data'] ?? [];
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => loading = false);
        }
        Fluttertoast.showToast(msg: "Server error: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching comments: $e");
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    setState(() => isSending = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url')!;
      String lid = sh.getString('lid')!;

      final res = await http.post(
        Uri.parse('$url/user_add_comment/'),
        body: {
          'lid': lid,
          'post_id': widget.postId,
          'comment': _commentController.text.trim(),
        },
      );

      final jsonData = jsonDecode(res.body);

      if (jsonData['status'] == 'ok') {
        _commentController.clear();
        fetchComments();
      } else {
        Fluttertoast.showToast(msg: "Failed to add comment");
      }
    } catch (e) {
      debugPrint("Error adding comment: $e");
      Fluttertoast.showToast(msg: "Network error");
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // --- The Isolated Drag Handle ---
                SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                    width: double.infinity,
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "Comments",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                ),

                // --- The Main Content (Independent Scrolling) ---
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : comments.isEmpty
                      ? const Center(child: Text("No comments yet. Be the first!"))
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];

                      final String commentText = (c['comment'] ?? c['comments'] ?? 'Unknown comment').toString();
                      final String username = (c['user'] ?? 'Unknown').toString();
                      final String time = (c['time'] ?? '').toString();

                      final String userPhoto = getSafeImageUrl((c['photo'] ?? '').toString());

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: userPhoto.isNotEmpty ? NetworkImage(userPhoto) : null,
                              child: userPhoto.isEmpty
                                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        time,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    commentText,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // --- Add Comment Field ---
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // ---> UPDATED: Replaced hardcoded Icon with network image <---
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: currentUserPhoto.isNotEmpty ? NetworkImage(currentUserPhoto) : null,
                        child: currentUserPhoto.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "Add a comment...",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            isDense: true,
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      isSending
                          ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)
                        ),
                      )
                          : IconButton(
                        icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                        onPressed: addComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}