import 'package:flutter/material.dart';
import 'package:cyber_bullying_detection/accepted_frd_req.dart';
import 'package:cyber_bullying_detection/ratings.dart';
import 'package:cyber_bullying_detection/send_complaint.dart';
import 'package:cyber_bullying_detection/view_friend_request.dart';
import 'delete_account.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A11CB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE4E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _menuButton(
                context,
                icon: Icons.message,
                label: "Send Complaint",
                page: const SendComplaintPage(),
                color: const Color(0xFFF9A826),
              ),
              _menuButton(
                context,
                icon: Icons.star,
                label: "Rate Us",
                page: const Ratings(),
                color: const Color(0xFFE8488B),
              ),
              _menuButton(
                context,
                icon: Icons.people_outline,
                label: "View Friend Request",
                page: const ViewFriendRequestPage(),
                color: const Color(0xFF6A4E9B),
              ),
              _menuButton(
                context,
                icon: Icons.mobile_friendly_sharp,
                label: "Friends",
                page: const AcceptedFriendsPage(),
                color: const Color(0xFFFF7E5F),
              ),
              // ---> NEW DELETE ACCOUNT BUTTON <---
              _menuButton(
                context,
                icon: Icons.delete_forever,
                label: "Delete Account",
                page: const DeleteAccountPage(), // Links to our new page
                color: const Color(0xFFE53935), // A strong red color to signify danger
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, {required IconData icon, required String label, required Widget page, required Color color}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}