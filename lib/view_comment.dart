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

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url')!;
    String lid = sh.getString('lid')!;

    final res = await http.post(
      Uri.parse('$url/user_view_comments/'),
      body: {
        'lid': lid,
        'post_id': widget.postId,
      },
    );

    final jsonData = jsonDecode(res.body);

    setState(() {
      comments = jsonData['data'];
      loading = false;
    });
  }

  Future<void> sendReply(String commentId, String reply) async {
    if (reply.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Reply cannot be empty");
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url')!;

    final res = await http.post(
      Uri.parse('$url/send_comment_reply/'),
      body: {
        'comment_id': commentId,
        'reply': reply,
      },
    );

    final jsonData = jsonDecode(res.body);

    if (jsonData['status'] == 'ok') {
      Fluttertoast.showToast(msg: "Reply sent");
      fetchComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : comments.isEmpty
          ? const Center(child: Text("No comments"))
          : ListView.builder(
        itemCount: comments.length,
        itemBuilder: (context, index) {
          final c = comments[index];
          final replyCtrl = TextEditingController();

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['comment'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  c['reply'] != ""
                      ? Text(
                    "Reply: ${c['reply']}",
                    style: const TextStyle(
                        color: Colors.green),
                  )
                      : const Text(
                    "No reply yet",
                    style:
                    TextStyle(color: Colors.grey),
                  ),

                  const Divider(),

                  TextField(
                    controller: replyCtrl,
                    decoration: const InputDecoration(
                      hintText: "Type reply...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 6),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => sendReply(
                        c['id'].toString(),
                        replyCtrl.text,
                      ),
                      child: const Text("Send Reply"),
                    ),
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
