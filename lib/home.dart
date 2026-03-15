// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // Your existing imports for the Bottom Navigation Bar
// import 'package:cyber_bullying_detection/search_user.dart';
// import 'package:cyber_bullying_detection/view_profile.dart';
// import 'package:cyber_bullying_detection/chat_list_screen.dart';
// import 'package:cyber_bullying_detection/add_post.dart';
// import 'login.dart';
// import 'add_comment.dart';
// import 'menu_screen.dart';
// // Import the new Report Post Page
// import 'report_post.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   // --- FEED STATE VARIABLES ---
//   bool _isLoading = true;
//   List feedPosts = [];
//   String imgUrl = "";
//   String currentUserId = "";
//
//   // --- PAGINATION VARIABLES ---
//   int currentPage = 1;
//   bool _isFetchingMore = false; // Controls the bottom loading spinner
//   bool _hasMore = true;         // Tells us when to stop asking Django for more
//   final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchHomeFeed(isRefresh: true); // Start fresh on load
//
//     // Listen to how far the user is scrolling
//     _scrollController.addListener(() {
//       // If we are near the bottom, and we aren't already fetching, and there is more to load...
//       if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
//           !_isFetchingMore &&
//           _hasMore) {
//         _fetchHomeFeed(); // Fetch the next chunk
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   // --- FETCH FEED API (Upgraded for Chunks) ---
//   Future<void> _fetchHomeFeed({bool isRefresh = false}) async {
//     if (isRefresh) {
//       currentPage = 1;
//       _hasMore = true;
//       if (mounted) setState(() => _isLoading = true);
//     } else {
//       if (mounted) setState(() => _isFetchingMore = true);
//     }
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String url = sh.getString('url') ?? "";
//     String lid = sh.getString('lid') ?? "";
//
//     if (mounted) {
//       setState(() {
//         imgUrl = sh.getString('img_url') ?? "";
//         currentUserId = lid; // We store the logged-in user's ID here!
//       });
//     }
//
//     try {
//       final response = await http.post(
//         Uri.parse('$url/user_view_home_feed/'),
//         body: {
//           'lid': lid,
//           'page': currentPage.toString(), // Send the exact page we need
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);
//         if (jsonData['status'] == 'ok') {
//           if (mounted) {
//             setState(() {
//               if (isRefresh) {
//                 feedPosts = jsonData['data']; // First load replaces everything
//               } else {
//                 feedPosts.addAll(jsonData['data']); // Scrolling appends to the bottom!
//               }
//
//               currentPage++; // Get ready for the next chunk
//               _hasMore = jsonData['has_more'] ?? false; // Check if Django says we hit the end
//               _isLoading = false;
//               _isFetchingMore = false;
//             });
//           }
//         } else {
//           if (mounted) setState(() { _isLoading = false; _isFetchingMore = false; });
//         }
//       }
//     } catch (e) {
//       if (mounted) setState(() { _isLoading = false; _isFetchingMore = false; });
//     }
//   }
//
//   // ---> NEW: TOGGLE LIKE API FUNCTION <---
//   Future<void> _toggleLike(int index, String postId) async {
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String url = sh.getString('url') ?? "";
//     String lid = sh.getString('lid') ?? "";
//
//     try {
//       final response = await http.post(
//         Uri.parse('$url/user_toggle_like/'),
//         body: {
//           'lid': lid,
//           'post_id': postId,
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);
//         if (jsonData['status'] == 'ok') {
//           // Immediately update the specific post in the list and redraw the screen!
//           setState(() {
//             feedPosts[index]['is_liked'] = (jsonData['action'] == 'liked');
//             feedPosts[index]['like_count'] = jsonData['total_likes'];
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Error toggling like: $e");
//     }
//   }
//
//   // --- HELPER FUNCTION ---
//   String getSafeImageUrl(String path) {
//     if (path.isEmpty) return "";
//     if (path.startsWith("http")) return path;
//     return imgUrl.endsWith("/") ? "$imgUrl$path" : "$imgUrl/$path";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       // 1. YOUR GRADIENT APP BAR
//       appBar: AppBar(
//         title: const Text(
//           "Socius",
//           style: TextStyle(fontFamily: 'BetaniaPatmos', fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Colors.white),
//         ),
//         centerTitle: true,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginPage(title: 'Login')),
//               );
//             },
//           )
//         ],
//       ),
//
//       // 2. THE MAIN FEED BODY
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//         onRefresh: () => _fetchHomeFeed(isRefresh: true), // Pull-to-refresh resets to chunk 1
//         child: feedPosts.isEmpty
//             ? SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Container(
//             height: MediaQuery.of(context).size.height * 0.7,
//             alignment: Alignment.center,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.dynamic_feed, size: 80, color: Colors.grey[400]),
//                 const SizedBox(height: 16),
//                 Text(
//                   "No posts yet!",
//                   style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Add more friends to see their updates here.",
//                   style: TextStyle(color: Colors.grey[500]),
//                 ),
//               ],
//             ),
//           ),
//         )
//             : ListView.builder(
//           controller: _scrollController, // Added the scroll tracker here!
//           itemCount: feedPosts.length + (_isFetchingMore ? 1 : 0), // Add 1 extra slot for the spinner if loading
//           itemBuilder: (context, index) {
//
//             // If we are at the very bottom slot and loading, show the spinner
//             if (index == feedPosts.length) {
//               return const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 20),
//                 child: Center(child: CircularProgressIndicator()),
//               );
//             }
//
//             final post = feedPosts[index];
//             // ---> UPDATED: We pass the index now so the button knows which post to update <---
//             return _buildPostCard(post, index);
//           },
//         ),
//       ),
//
//       // 3. UPDATED BOTTOM NAVIGATION BAR
//       bottomNavigationBar: BottomAppBar(
//         color: Colors.white,
//         elevation: 10,
//         child: SizedBox(
//           height: 55,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spaces icons perfectly
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.search, size: 28),
//                 color: const Color(0xFF6A11CB),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const SearchUserPage()),
//                   );
//                 },
//               ),
//               IconButton(
//                 icon: const Icon(Icons.chat_bubble_outline, size: 28),
//                 color: const Color(0xFF6A11CB),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ChatListScreen()),
//                   );
//                 },
//               ),
//               IconButton(
//                 icon: const Icon(Icons.add_circle_outline, size: 32),
//                 color: const Color(0xFF6A11CB),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const AddPostPage()),
//                   );
//                 },
//               ),
//               IconButton(
//                 icon: const Icon(Icons.person_outline, size: 28),
//                 color: const Color(0xFF6A11CB),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ViewProfile()),
//                   );
//                 },
//               ),
//               // ---> THE MENU BUTTON <---
//               IconButton(
//                 icon: const Icon(Icons.menu, size: 28),
//                 color: const Color(0xFF6A11CB),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const MenuScreen()),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // --- POST CARD WIDGET ---
//   // ---> UPDATED: Now requires the index to pass to _toggleLike <---
//   Widget _buildPostCard(Map post, int index) {
//     String authorPhoto = getSafeImageUrl(post['author_photo'] ?? "");
//     String postImage = getSafeImageUrl(post['photo'] ?? "");
//
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
//       elevation: 2,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ListTile(
//             leading: CircleAvatar(
//               backgroundImage: authorPhoto.isNotEmpty ? NetworkImage(authorPhoto) : null,
//               backgroundColor: Colors.grey[300],
//               child: authorPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
//             ),
//             title: Text(
//               post['author_name'] ?? 'Unknown User',
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             subtitle: post['location'] != null && post['location'].toString().isNotEmpty
//                 ? Row(
//               children: [
//                 const Icon(Icons.location_on, size: 12, color: Colors.grey),
//                 const SizedBox(width: 3),
//                 Text(post['location'], style: const TextStyle(fontSize: 12)),
//               ],
//             )
//                 : null,
//
//             // If the post author is the current user, show an empty box.
//             // If it's someone else, show the report button!
//             trailing: post['author_id'].toString() != currentUserId
//                 ? PopupMenuButton<String>(
//               icon: const Icon(Icons.more_vert),
//               onSelected: (value) {
//                 if (value == 'report') {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ReportPostPage(postId: post['post_id'].toString()),
//                     ),
//                   );
//                 }
//               },
//               itemBuilder: (context) => [
//                 const PopupMenuItem(
//                   value: 'report',
//                   child: Row(
//                     children: [
//                       Icon(Icons.report_problem, color: Colors.red, size: 20),
//                       SizedBox(width: 8),
//                       Text("Report Post"),
//                     ],
//                   ),
//                 ),
//               ],
//             )
//                 : const SizedBox.shrink(),
//           ),
//
//           if (postImage.isNotEmpty)
//             Image.network(
//               postImage,
//               height: 350,
//               width: double.infinity,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) => Container(
//                 height: 350,
//                 color: Colors.grey[200],
//                 child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
//               ),
//             ),
//
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 // ---> THE UPDATED LIKE SECTION <---
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         post['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
//                         color: post['is_liked'] == true ? Colors.red : Colors.black,
//                         size: 28,
//                       ),
//                       onPressed: () {
//                         // Triggers the toggle using the current post's index and ID
//                         _toggleLike(index, post['post_id'].toString());
//                       },
//                     ),
//                     if (post['like_count'] != null && post['like_count'] > 0)
//                       Text(
//                         "${post['like_count']}",
//                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       ),
//                   ],
//                 ),
//
//                 const SizedBox(width: 10), // Small gap before the comment button
//
//                 IconButton(
//                   icon: const Icon(Icons.chat_bubble_outline, size: 26),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => PostCommentsPage(
//                           postId: post['post_id'].toString(),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 const Spacer(),
//                 Text(
//                   "${post['date']} ${post['time'] ?? ''}",
//                   style: const TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           if (post['caption'] != null && post['caption'].toString().isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
//               child: RichText(
//                 text: TextSpan(
//                   style: const TextStyle(color: Colors.black, fontSize: 15),
//                   children: [
//                     TextSpan(
//                       text: "${post['author_username']} ",
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     TextSpan(text: post['caption']),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Your existing imports for the Bottom Navigation Bar
import 'package:cyber_bullying_detection/search_user.dart';
import 'package:cyber_bullying_detection/view_profile.dart';
import 'package:cyber_bullying_detection/chat_list_screen.dart';
import 'package:cyber_bullying_detection/add_post.dart';
import 'login.dart';
import 'add_comment.dart';
import 'menu_screen.dart';
// Import the new Report Post Page
import 'report_post.dart';
// ---> NEW: Import the Other User Profile Page
import 'view_other_user_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- FEED STATE VARIABLES ---
  bool _isLoading = true;
  List feedPosts = [];
  String imgUrl = "";
  String currentUserId = "";

  // --- PAGINATION VARIABLES ---
  int currentPage = 1;
  bool _isFetchingMore = false; // Controls the bottom loading spinner
  bool _hasMore = true;         // Tells us when to stop asking Django for more
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHomeFeed(isRefresh: true); // Start fresh on load

    // Listen to how far the user is scrolling
    _scrollController.addListener(() {
      // If we are near the bottom, and we aren't already fetching, and there is more to load...
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isFetchingMore &&
          _hasMore) {
        _fetchHomeFeed(); // Fetch the next chunk
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- FETCH FEED API (Upgraded for Chunks) ---
  Future<void> _fetchHomeFeed({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      _hasMore = true;
      if (mounted) setState(() => _isLoading = true);
    } else {
      if (mounted) setState(() => _isFetchingMore = true);
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    if (mounted) {
      setState(() {
        imgUrl = sh.getString('img_url') ?? "";
        currentUserId = lid; // We store the logged-in user's ID here!
      });
    }

    try {
      final response = await http.post(
        Uri.parse('$url/user_view_home_feed/'),
        body: {
          'lid': lid,
          'page': currentPage.toString(), // Send the exact page we need
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          if (mounted) {
            setState(() {
              if (isRefresh) {
                feedPosts = jsonData['data']; // First load replaces everything
              } else {
                feedPosts.addAll(jsonData['data']); // Scrolling appends to the bottom!
              }

              currentPage++; // Get ready for the next chunk
              _hasMore = jsonData['has_more'] ?? false; // Check if Django says we hit the end
              _isLoading = false;
              _isFetchingMore = false;
            });
          }
        } else {
          if (mounted) setState(() { _isLoading = false; _isFetchingMore = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _isFetchingMore = false; });
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
            feedPosts[index]['is_liked'] = (jsonData['action'] == 'liked');
            feedPosts[index]['like_count'] = jsonData['total_likes'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  // --- HELPER FUNCTION ---
  String getSafeImageUrl(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return imgUrl.endsWith("/") ? "$imgUrl$path" : "$imgUrl/$path";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // 1. YOUR GRADIENT APP BAR
      appBar: AppBar(
        title: const Text(
          "Socius",
          style: TextStyle(fontFamily: 'BetaniaPatmos', fontWeight: FontWeight.w600, letterSpacing: 0.5, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage(title: 'Login')),
              );
            },
          )
        ],
      ),

      // 2. THE MAIN FEED BODY
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => _fetchHomeFeed(isRefresh: true), // Pull-to-refresh resets to chunk 1
        child: feedPosts.isEmpty
            ? SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dynamic_feed, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No posts yet!",
                  style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add more friends to see their updates here.",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          controller: _scrollController, // Added the scroll tracker here!
          itemCount: feedPosts.length + (_isFetchingMore ? 1 : 0), // Add 1 extra slot for the spinner if loading
          itemBuilder: (context, index) {

            // If we are at the very bottom slot and loading, show the spinner
            if (index == feedPosts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final post = feedPosts[index];
            // ---> UPDATED: We pass the index now so the button knows which post to update <---
            return _buildPostCard(post, index);
          },
        ),
      ),

      // 3. UPDATED BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 55,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spaces icons perfectly
            children: [
              IconButton(
                icon: const Icon(Icons.search, size: 28),
                color: const Color(0xFF6A11CB),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchUserPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 28),
                color: const Color(0xFF6A11CB),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 32),
                color: const Color(0xFF6A11CB),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPostPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, size: 28),
                color: const Color(0xFF6A11CB),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ViewProfile()),
                  );
                },
              ),
              // ---> THE MENU BUTTON <---
              IconButton(
                icon: const Icon(Icons.menu, size: 28),
                color: const Color(0xFF6A11CB),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MenuScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- POST CARD WIDGET ---
  // ---> UPDATED: Now requires the index to pass to _toggleLike <---
  Widget _buildPostCard(Map post, int index) {
    String authorPhoto = getSafeImageUrl(post['author_photo'] ?? "");
    String postImage = getSafeImageUrl(post['photo'] ?? "");

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            // ---> NEW: Instagram-style Profile Navigation on Header Click <---
            onTap: () {
              if (post['author_id'].toString() == currentUserId) {
                // If it's your own post, go to your profile
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewProfile()),
                );
              } else {
                // If it's someone else's post, go to their profile
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherUserProfilePage(targetUserId: post['author_id'].toString()),
                  ),
                );
              }
            },
            leading: CircleAvatar(
              backgroundImage: authorPhoto.isNotEmpty ? NetworkImage(authorPhoto) : null,
              backgroundColor: Colors.grey[300],
              child: authorPhoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(
              post['author_name'] ?? 'Unknown User',
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

            // If the post author is the current user, show an empty box.
            // If it's someone else, show the report button!
            trailing: post['author_id'].toString() != currentUserId
                ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'report') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportPostPage(postId: post['post_id'].toString()),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report_problem, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text("Report Post"),
                    ],
                  ),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),

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
                        // Triggers the toggle using the current post's index and ID
                        _toggleLike(index, post['post_id'].toString());
                      },
                    ),
                    if (post['like_count'] != null && post['like_count'] > 0)
                      Text(
                        "${post['like_count']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                  ],
                ),

                const SizedBox(width: 10), // Small gap before the comment button

                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostCommentsPage(
                          postId: post['post_id'].toString(),
                        ),
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
          if (post['caption'] != null && post['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  children: [
                    TextSpan(
                      text: "${post['author_username']} ",
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
  }
}