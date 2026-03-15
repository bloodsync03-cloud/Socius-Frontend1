import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Needed to boot the user back to the login screen

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _isDeleting = false;

  Future<void> _deleteMyAccount() async {
    setState(() => _isDeleting = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";
    String imgUrl = sh.getString('img_url') ?? ""; // ---> Grabbed the image URL too!

    try {
      final response = await http.post(
        Uri.parse('$url/user_delete_account/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          Fluttertoast.showToast(msg: "Account permanently deleted.", backgroundColor: Colors.red);

          // ---> THE FIX: Clear their saved login info, but restore the server URLs! <---
          await sh.clear();
          await sh.setString('url', url);
          await sh.setString('img_url', imgUrl);

          // Kick them out to the Login Screen and destroy the "Back" history
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage(title: 'Login')),
                  (Route<dynamic> route) => false,
            );
          }
        } else {
          Fluttertoast.showToast(msg: "Failed to delete account.", backgroundColor: Colors.orange);
          if (mounted) setState(() => _isDeleting = false);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Network Error", backgroundColor: Colors.orange);
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Delete Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935), // Red AppBar to signal danger
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.warning_amber_rounded, size: 80, color: Color(0xFFE53935)),
            const SizedBox(height: 20),
            const Text(
              "This action is permanent.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "If you delete your account, you will permanently lose all of your:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // The warning list
            _buildWarningItem(Icons.image, "Photos and Posts"),
            _buildWarningItem(Icons.people, "Friends and Connections"),
            _buildWarningItem(Icons.message, "Messages and Comments"),
            _buildWarningItem(Icons.favorite, "Likes and Activity"),

            const Spacer(),

            // The final button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isDeleting ? null : _deleteMyAccount,
                child: _isDeleting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "I understand, delete my account",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}