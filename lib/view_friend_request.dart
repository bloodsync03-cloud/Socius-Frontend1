import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewFriendRequestPage extends StatefulWidget {
  const ViewFriendRequestPage({super.key});

  @override
  State<ViewFriendRequestPage> createState() => _ViewFriendRequestPageState();
}

class _ViewFriendRequestPageState extends State<ViewFriendRequestPage> {
  bool isLoading = true;
  List pendingUserRequests = [];

  String imgUrl = "";
  String lid = "";

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ================= FETCH REQUESTS =================
  Future<void> fetchRequests() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url') ?? "";
      lid = sh.getString('lid') ?? "";
      imgUrl = sh.getString('img_url') ?? "";

      final res = await http.post(
        Uri.parse('$url/userviewfriendrequests/'),
        body: {'lid': lid},
      );

      final data = jsonDecode(res.body);

      setState(() {
        pendingUserRequests =
        data['status'] == 'ok' ? data['data'] : [];
        isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
      setState(() => isLoading = false);
    }
  }

  // ================= ACCEPT FRIEND =================
  Future<void> acceptRequest(String requestId) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url') ?? "";

      final res = await http.post(
        Uri.parse('$url/user_accept_friend/'),
        body: {'rid': requestId},
      );

      final data = jsonDecode(res.body);
      Fluttertoast.showToast(msg: data['message'] ?? "Accepted");

      if (data['status'] == 'ok') {
        fetchRequests();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  // ================= REJECT FRIEND =================
  Future<void> rejectRequest(String requestId) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString('url') ?? "";

      final res = await http.post(
        Uri.parse('$url/user_reject_friend/'),
        body: {'rid': requestId},
      );

      final data = jsonDecode(res.body);
      Fluttertoast.showToast(msg: data['message'] ?? "Rejected");

      if (data['status'] == 'ok') {
        fetchRequests();
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  // ================= IMAGE URL =================
  String getImageUrl(String photo) {
    if (photo.isEmpty) return "";
    if (photo.startsWith("http")) return photo;
    return imgUrl.endsWith("/")
        ? "$imgUrl$photo"
        : "$imgUrl/$photo";
  }

  // ================= FRIEND CARD =================
  Widget friendTile(Map user) {
    String photoUrl = getImageUrl(user['photo'] ?? "");

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundImage:
          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          user['name'] ?? "No Name",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user['username'] ?? ""),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () =>
                  acceptRequest(user['request_id'].toString()),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () =>
                  rejectRequest(user['request_id'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friend Requests"),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingUserRequests.isEmpty
          ? const Center(child: Text("No Pending Requests"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pendingUserRequests.length,
        itemBuilder: (context, index) {
          return friendTile(pendingUserRequests[index]);
        },
      ),
    );
  }
}
