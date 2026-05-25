import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ---> THE FIX 1: Import the new ViewCommentsPage instead of add_comment.dart <---
import 'view_comment.dart';
import 'user_chat.dart';
// ---> NEW: Import the Report Post Page
import 'report_post.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String targetUserId;

  const OtherUserProfilePage({super.key, required this.targetUserId});

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  bool _isLoadingProfile = true;
  bool _isLoadingPosts = true;
  String _friendStatus = 'loading';

  // ---> NEW: Boolean to track if we are locked out
  bool _isPrivateAccount = false;

  // Profile Data
  String username_ = '';
  String name_ = '';
  String place_ = '';
  String bio_ = '';
  String photo_ = '';
  String friendCount_ = '0'; // ---> NEW: Added to match view_profile design

  // Posts Data
  List posts = [];
  String imgUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchUserPosts();
    _fetchFriendStatus();
  }

  Future<void> _fetchProfileData() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    String savedImgUrl = sh.getString('img_url') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$url/user_view_profile/'),
        body: {'lid': widget.targetUserId},
      );
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
              photo_ = savedImgUrl + (data['photo']?.toString() ?? '');
              friendCount_ = data['friend_count']?.toString() ?? '0'; // Get friend count
              _isLoadingProfile = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchUserPosts() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String viewerId = sh.getString('lid') ?? ""; // Our logged-in ID

    if (mounted) {
      setState(() {
        imgUrl = sh.getString('img_url') ?? "";
      });
    }

    try {
      final response = await http.post(
        Uri.parse('$url/user_view_other_post/'), // Changed to the secure API
        body: {
          'lid': widget.targetUserId,
          'viewer_id': viewerId, // Passing our ID to Django
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'ok') {
          if (mounted) {
            setState(() {
              posts = jsonData['data'];
              _isPrivateAccount = false;
              _isLoadingPosts = false;
            });
          }
        } else if (jsonData['status'] == 'private') {
          // Django blocked us! Lock the UI.
          if (mounted) {
            setState(() {
              _isPrivateAccount = true;
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

  Future<void> _fetchFriendStatus() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    String lid = sh.getString('lid') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$url/check_friend_status/'),
        body: {'lid': lid, 'tid': widget.targetUserId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          if (mounted) {
            setState(() {
              _friendStatus = data['connection'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Status error: $e");
    }
  }

  Future<void> _handleFriendAction(String action) async {
    setState(() {
      _friendStatus = 'loading';
    });

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    String lid = sh.getString('lid') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$url/handle_friend_action/'),
        body: {
          'lid': lid,
          'tid': widget.targetUserId,
          'action': action
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          _fetchFriendStatus();
          if (action == 'add') Fluttertoast.showToast(msg: "Friend Request Sent!");
          if (action == 'accept') {
            Fluttertoast.showToast(msg: "Friend Request Accepted!");
            // Refresh posts instantly! If it was private, it should unlock now!
            setState(() => _isLoadingPosts = true);
            _fetchUserPosts();
          }
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Action failed");
      _fetchFriendStatus();
    }
  }

  // ---> NEW: Function to handle friend removal <---
  Future<void> _removeFriend() async {
    Navigator.of(context).pop(); // Close the confirmation dialog first

    setState(() {
      _friendStatus = 'loading';
    });

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? '';
    String lid = sh.getString('lid') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$url/user_remove_friend/'),
        body: {
          'lid': lid,
          'tid': widget.targetUserId,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          Fluttertoast.showToast(msg: "Friend removed");
          _fetchFriendStatus();
          // Refresh posts instantly so the profile locks again if it's private
          setState(() => _isLoadingPosts = true);
          _fetchUserPosts();
        } else {
          Fluttertoast.showToast(msg: data['message'] ?? "Failed to remove friend");
          _fetchFriendStatus();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Action failed");
      _fetchFriendStatus();
    }
  }

  // ---> NEW: Confirmation Popup for removing a friend <---
  void _showRemoveFriendConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Remove Friend"),
          content: const Text("Are you sure you want to remove this friend? You'll need to send a friend request again to reconnect."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _removeFriend, // Proceed to remove
              child: const Text("Remove", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Helper function to safely build image URLs
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
        title: Text(name_.isNotEmpty ? name_ : 'Profile', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4361EE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isFullyLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_fetchProfileData(), _fetchUserPosts(), _fetchFriendStatus()]);
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

  // ---> UPDATED: Layout matching the view_profile.dart drawing <---
  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW: Avatar, Name/Username, Friends Count
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: photo_.isNotEmpty
                    ? NetworkImage(photo_)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 16),
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
              // Friends Count
              Padding(
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
            ],
          ),

          const SizedBox(height: 16),

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

          _buildDynamicActionButton(),
        ],
      ),
    );
  }

  Widget _buildDynamicActionButton() {
    if (_friendStatus == 'loading') {
      return const SizedBox(
        height: 45,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    else if (_friendStatus == 'accepted') {
      // ---> NEW: Message and Remove buttons side by side <---
      return SizedBox(
        height: 45,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        toId: widget.targetUserId,
                        name: name_,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                label: const Text('Message', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B998B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showRemoveFriendConfirmation,
                icon: const Icon(Icons.person_remove, size: 18, color: Colors.red),
                label: const Text('Remove', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    }
    else if (_friendStatus == 'pending') {
      return SizedBox(
        width: double.infinity,
        height: 45,
        child: OutlinedButton.icon(
          onPressed: () {
            Fluttertoast.showToast(msg: "Waiting for them to accept");
          },
          icon: const Icon(Icons.access_time, size: 18, color: Colors.grey),
          label: const Text('Requested', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
    else if (_friendStatus == 'received') {
      return SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton.icon(
          onPressed: () => _handleFriendAction('accept'),
          icon: const Icon(Icons.check, size: 18, color: Colors.white),
          label: const Text('Accept Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF9A826),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
    else {
      return SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton.icon(
          onPressed: () => _handleFriendAction('add'),
          icon: const Icon(Icons.person_add, size: 18, color: Colors.white),
          label: const Text('Add Friend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4361EE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
  }

  // ---> UPDATED: Layout matching the view_profile.dart drawing <---
  Widget _buildPostsSection() {
    if (_isPrivateAccount) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 30.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[400]!, width: 2),
              ),
              child: Icon(Icons.lock_outline, size: 50, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Text(
              'This Account is Private',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'Only friends can see what they share. Send a request to connect.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        String postImage = getSafeImageUrl(post['photo'] ?? "");

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          elevation: 2,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Post Header
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

                // ---> NEW LOGIC: Report Button replacing Delete <---
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'report') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Notice we use post['id'] here since that's what user_view_other_post returns
                          builder: (context) => ReportPostPage(postId: post['id'].toString()),
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report_problem, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Report Post'),
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
                  height: 350,
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
                            postId: post['id'].toString(),
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