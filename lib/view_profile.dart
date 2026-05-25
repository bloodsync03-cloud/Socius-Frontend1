import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Make sure these point to your actual files
import 'edit_profile.dart';
// ---> THE FIX 1: Import the new ViewCommentsPage instead of the old add_comment.dart <---
import 'view_comment.dart';
// ---> NEW: Added import to access the friends list page
import 'accepted_frd_req.dart';

class ViewProfile extends StatelessWidget {
  const ViewProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CombinedProfilePage(),
    );
  }
}

class CombinedProfilePage extends StatefulWidget {
  const CombinedProfilePage({super.key});

  @override
  State<CombinedProfilePage> createState() => _CombinedProfilePageState();
}

class _CombinedProfilePageState extends State<CombinedProfilePage> {
  bool _isLoadingProfile = true;
  bool _isLoadingPosts = true;

  // Profile Data
  String username_ = '';
  String name_ = '';
  String place_ = '';
  String bio_ = '';
  String photo_ = '';
  String friendCount_ = '0'; // ---> NEW: State to hold the number of friends

  // Posts Data
  List posts = [];
  String imgUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchUserPosts();
  }

  // 1. Fetch from your Django 'user_view_profile'
  Future<void> _fetchProfileData() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    String lid = sh.getString('lid') ?? '';
    String savedImgUrl = sh.getString('img_url') ?? '';

    final uri = Uri.parse('$url/user_view_profile/');

    try {
      final response = await http.post(uri, body: {'lid': lid});
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'ok') {
          final data = decoded['data'];
          if (mounted) {
            setState(() {
              username_ = data['username']?.toString() ?? '';
              name_ = data['name']?.toString() ?? '';
              place_ = data['place']?.toString() ?? '';
              bio_ = data['bio']?.toString() ?? '';
              // Append base URL to the photo path returned from Django
              photo_ = savedImgUrl + (data['photo']?.toString() ?? '');

              // ---> NEW: Catch the friend count from Django
              friendCount_ = data['friend_count']?.toString() ?? '0';

              _isLoadingProfile = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // 2. Fetch from your Django 'user_view_post'
  Future<void> _fetchUserPosts() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    if (mounted) {
      setState(() {
        imgUrl = sh.getString('img_url') ?? "";
      });
    }

    try {
      final response = await http.post(
        Uri.parse('$url/user_view_post/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          if (mounted) {
            setState(() {
              posts = jsonData['data'];
              _isLoadingPosts = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingPosts = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  // ---> NEW: TOGGLE LIKE API FUNCTION <---
  Future<void> _toggleLike(int index, String postId) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    try {
      final response = await http.post(
        Uri.parse('$url/user_toggle_like/'),
        body: {
          'lid': lid,
          'post_id': postId,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          // Immediately update the specific post in the list and redraw the screen!
          setState(() {
            posts[index]['is_liked'] = (jsonData['action'] == 'liked');
            posts[index]['like_count'] = jsonData['total_likes'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  // ---> Delete Post API Call
  Future<void> _deletePost(String postId) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    try {
      final response = await http.post(
        Uri.parse('$url/user_delete_post/'),
        body: {
          'lid': lid,
          'post_id': postId,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          // If Django successfully deleted it, remove it instantly from the screen
          setState(() {
            posts.removeWhere((post) => post['id'].toString() == postId);
          });
          Fluttertoast.showToast(msg: "Post deleted successfully", backgroundColor: Colors.green);
        } else {
          Fluttertoast.showToast(msg: "Failed to delete post", backgroundColor: Colors.red);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error connecting to server", backgroundColor: Colors.red);
    }
  }

  // ---> Confirmation Popup
  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Delete Post"),
          content: const Text("Are you sure you want to permanently delete this post?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                _deletePost(postId);         // Then trigger the deletion
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Helper function to safely build image URLs (just like home feed)
  String getSafeImageUrl(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return imgUrl.endsWith("/") ? "$imgUrl$path" : "$imgUrl/$path";
  }

  @override
  Widget build(BuildContext context) {
    bool isFullyLoading = _isLoadingProfile || _isLoadingPosts;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4361EE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isFullyLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_fetchProfileData(), _fetchUserPosts()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              const Divider(height: 1, thickness: 1),
              _buildPostsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---> NEW LOGIC: Layout matching the drawing <---
  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns bio and place to the left edge
        children: [

          // TOP ROW: Avatar, Name/Username, Friends Count
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage: photo_.isNotEmpty
                    ? NetworkImage(photo_)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 16), // Space between avatar and text

              // 2. Name & Username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name_,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "@$username_",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // 3. Friends Count (Now fully clickable!)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AcceptedFriendsPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10), // Neat ripple effect
                child: Padding(
                  padding: const EdgeInsets.only(right: 15.0, top: 8, bottom: 8, left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        friendCount_,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Friends",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16), // Spacing between top row and Bio

          // BOTTOM SECTION: Bio and Location
          if (bio_.isNotEmpty) ...[
            Text(
              bio_,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
          ],
          if (place_.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(place_, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ],

          const SizedBox(height: 25),

          // 3. BOTTOM (Edit Profile Button)
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserEditProfile()),
                );
                _fetchProfileData(); // Refresh after edit
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4361EE),
                side: const BorderSide(color: Color(0xFF4361EE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Text(
          'No Posts Available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      // Removed the padding here to make the cards edge-to-edge
      padding: EdgeInsets.zero,
      shrinkWrap: true, // Vital for ListView inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Prevent double scrolling
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        String postImage = getSafeImageUrl(post['photo'] ?? "");

        // --- NEW INSTAGRAM-STYLE POST CARD ---
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          elevation: 2,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Post Header (Your Info)
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: photo_.isNotEmpty ? NetworkImage(photo_) : null,
                  backgroundColor: Colors.grey[300],
                  child: photo_.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Text(
                  name_,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: post['location'] != null && post['location'].toString().isNotEmpty
                    ? Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(post['location'], style: const TextStyle(fontSize: 12)),
                  ],
                )
                    : null,

                // ---> NEW LOGIC: The 3-Dot Dropdown Menu <---
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(post['id'].toString());
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Post', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Post Image
              if (postImage.isNotEmpty)
                Image.network(
                  postImage,
                  height: 350, // Matches Home Feed
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 350,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                ),

              // 3. Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // ---> THE UPDATED LIKE SECTION <---
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            post['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                            color: post['is_liked'] == true ? Colors.red : Colors.black,
                            size: 28,
                          ),
                          onPressed: () {
                            _toggleLike(index, post['id'].toString());
                          },
                        ),
                        if (post['like_count'] != null && post['like_count'] > 0)
                          Text(
                            "${post['like_count']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // ---> THE FIX 2: Launch the Bottom Sheet for Comments <---
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, size: 26),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ViewCommentsPage(
                            postId: post['id'].toString(), // Profile API uses 'id' instead of 'post_id'
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      "${post['date']} ${post['time'] ?? ''}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // 4. Caption
              if (post['caption'] != null && post['caption'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                      children: [
                        TextSpan(
                          text: "$username_ ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: post['caption']),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}