// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
//
// class PostCommentsPage extends StatefulWidget {
//   final String postId;
//
//   const PostCommentsPage({super.key, required this.postId});
//
//   @override
//   State<PostCommentsPage> createState() => _PostCommentsPageState();
// }
//
// class _PostCommentsPageState extends State<PostCommentsPage> {
//   final TextEditingController _commentController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//
//   bool _isSubmitting = false;
//   bool _loadingComments = true;
//
//   List<Map<String, dynamic>> _comments = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadComments();
//   }
//
//   // ---------------- LOAD COMMENTS ----------------
//   Future<void> _loadComments() async {
//     setState(() => _loadingComments = true);
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String? url = sh.getString('url');
//     String? lid = sh.getString('lid');
//
//     if (url == null || lid == null) {
//       setState(() => _loadingComments = false);
//       return;
//     }
//
//     final response = await http.post(
//       Uri.parse('$url/userviewcomment/'),
//       body: {
//         'lid': lid,
//         'post_id': widget.postId,
//       },
//     );
//
//     final jsonData = jsonDecode(response.body);
//
//     if (jsonData['status'] == 'ok') {
//       setState(() {
//         _comments = List<Map<String, dynamic>>.from(jsonData['data']);
//       });
//     }
//
//     setState(() => _loadingComments = false);
//   }
//
//   // ---------------- ADD COMMENT ----------------
//   Future<void> _submitComment() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isSubmitting = true);
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String? url = sh.getString('url');
//     String? lid = sh.getString('lid');
//
//     if (url == null || lid == null) {
//       Fluttertoast.showToast(msg: 'Session expired');
//       setState(() => _isSubmitting = false);
//       return;
//     }
//
//     final response = await http.post(
//       Uri.parse('$url/user_add_comment/'),
//       body: {
//         'lid': lid,
//         'post_id': widget.postId,
//         'comments': _commentController.text.trim(),
//       },
//     );
//
//     final jsonData = jsonDecode(response.body);
//
//     if (jsonData['status'] == 'ok') {
//       Fluttertoast.showToast(msg: 'Comment added');
//       _commentController.clear();
//       _loadComments();
//     } else {
//       Fluttertoast.showToast(msg: 'Failed to add comment');
//     }
//
//     setState(() => _isSubmitting = false);
//   }
//
//   // ---------------- UI ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Comments'),
//         backgroundColor: const Color(0xFF4361EE),
//       ),
//       body: Column(
//         children: [
//           _commentInputCard(),
//           Expanded(child: _commentsList()),
//         ],
//       ),
//     );
//   }
//
//   // ---------------- COMMENT INPUT ----------------
//   Widget _commentInputCard() {
//     return Card(
//       margin: const EdgeInsets.all(12),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _commentController,
//                 maxLines: 4,
//                 decoration: InputDecoration(
//                   hintText: 'Write your comment...',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Enter a comment';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 height: 45,
//                 child: ElevatedButton(
//                   onPressed: _isSubmitting ? null : _submitComment,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4361EE),
//                   ),
//                   child: _isSubmitting
//                       ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor:
//                       AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                       : const Text('Add Comment'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ---------------- COMMENTS LIST ----------------
//   Widget _commentsList() {
//     if (_loadingComments) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (_comments.isEmpty) {
//       return const Center(
//         child: Text(
//           'No comments yet',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );
//     }
//
//     return RefreshIndicator(
//       onRefresh: _loadComments,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: _comments.length,
//         itemBuilder: (context, index) {
//           final c = _comments[index];
//
//           return Card(
//             margin: const EdgeInsets.only(bottom: 10),
//             child: ListTile(
//               title: Text(
//                 c['user'].toString(),
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(c['comments']),
//                   if (c['reply'] != null && c['reply'].toString().isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Text(
//                         'Reply: ${c['reply']}',
//                         style: const TextStyle(
//                           color: Colors.green,
//                           fontStyle: FontStyle.italic,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '${c['date']} ${c['time']}',
//                     style: const TextStyle(
//                         fontSize: 11, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PostCommentsPage extends StatefulWidget {
  final String postId;

  const PostCommentsPage({super.key, required this.postId});

  @override
  State<PostCommentsPage> createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends State<PostCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _loadingComments = true;

  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // ---------------- LOAD COMMENTS ----------------
  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? lid = sh.getString('lid');

    if (url == null || lid == null) {
      setState(() => _loadingComments = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$url/userviewcomment/'),
        body: {
          'lid': lid,
          'post_id': widget.postId,
        },
      );

      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(jsonData['data']);
        });
      }
    } catch (e) {
      debugPrint("Error loading comments: $e");
    }

    setState(() => _loadingComments = false);
  }

  // ---------------- ADD COMMENT ----------------
  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? lid = sh.getString('lid');

    if (url == null || lid == null) {
      Fluttertoast.showToast(msg: 'Session expired');
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$url/user_add_comment/'),
        body: {
          'lid': lid,
          'post_id': widget.postId,
          'comments': _commentController.text.trim(),
        },
      );

      final jsonData = jsonDecode(response.body);

      // ---> UPDATED LOGIC TO HANDLE ML RESPONSES <---
      if (jsonData['status'] == 'ok') {
        Fluttertoast.showToast(
          msg: 'Comment added successfully',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _commentController.clear();
        _loadComments(); // Refresh list to show new comment
      } else if (jsonData['status'] == 'error') {
        // If the ML Model flags it as Toxic, show the warning!
        Fluttertoast.showToast(
          msg: jsonData['message'] ?? 'Cyberbullying detected. Comment blocked.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG, // Make it stay on screen a bit longer
        );
      } else {
        Fluttertoast.showToast(msg: 'Failed to add comment');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error connecting to server',
        backgroundColor: Colors.red,
      );
    }

    setState(() => _isSubmitting = false);
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4361EE),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _commentInputCard(),
          Expanded(child: _commentsList()),
        ],
      ),
    );
  }

  // ---------------- COMMENT INPUT ----------------
  Widget _commentInputCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a comment';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4361EE),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Add Comment', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- COMMENTS LIST ----------------
  Widget _commentsList() {
    if (_loadingComments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_comments.isEmpty) {
      return const Center(
        child: Text(
          'No comments yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _comments.length,
        itemBuilder: (context, index) {
          final c = _comments[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                c['user'].toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['comments']),
                  if (c['reply'] != null && c['reply'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Reply: ${c['reply']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${c['date']} ${c['time']}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}