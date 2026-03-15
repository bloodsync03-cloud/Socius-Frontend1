// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ReportPostPage extends StatefulWidget {
//   final String postId;
//
//   const ReportPostPage({super.key, required this.postId});
//
//   @override
//   State<ReportPostPage> createState() => _ReportPostPageState();
// }
//
// class _ReportPostPageState extends State<ReportPostPage> {
//   // The default selected reason
//   String _selectedReason = 'Inappropriate Image';
//   bool _isSubmitting = false;
//
//   // List of reasons a user can choose from
//   final List<String> _reportReasons = [
//     'Inappropriate Image',
//     'Cyberbullying or Harassment',
//     'Spam or Scam',
//     'Hate Speech',
//     'Violence or Dangerous Organizations',
//   ];
//
//   Future<void> _submitReport() async {
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String url = sh.getString('url') ?? "";
//     String lid = sh.getString('lid') ?? "";
//
//     try {
//       var response = await http.post(
//         Uri.parse('$url/user_report_post/'),
//         body: {
//           "lid": lid,
//           "post_id": widget.postId,
//           "reason": _selectedReason,
//         },
//       );
//
//       var data = json.decode(response.body);
//
//       if (data['status'] == 'ok') {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Post reported to admin successfully."), backgroundColor: Colors.green),
//           );
//           // Go back to the feed after reporting
//           Navigator.pop(context);
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Error connecting to server."), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSubmitting = false;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Report Post", style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFF6A11CB),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Why are you reporting this post?",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               "Your report is anonymous. If someone is in immediate danger, call the local emergency services.",
//               style: TextStyle(color: Colors.grey, fontSize: 14),
//             ),
//             const SizedBox(height: 20),
//
//             // Build the list of radio buttons
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _reportReasons.length,
//                 itemBuilder: (context, index) {
//                   return RadioListTile<String>(
//                     title: Text(_reportReasons[index]),
//                     value: _reportReasons[index],
//                     groupValue: _selectedReason,
//                     activeColor: const Color(0xFF6A11CB),
//                     onChanged: (String? value) {
//                       setState(() {
//                         _selectedReason = value!;
//                       });
//                     },
//                   );
//                 },
//               ),
//             ),
//
//             // Submit Button
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _isSubmitting ? null : _submitReport,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: _isSubmitting
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text("Submit Report", style: TextStyle(color: Colors.white, fontSize: 16)),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportPostPage extends StatefulWidget {
  final String postId;

  const ReportPostPage({super.key, required this.postId});

  @override
  State<ReportPostPage> createState() => _ReportPostPageState();
}

class _ReportPostPageState extends State<ReportPostPage> {
  // The default selected reason
  String _selectedReason = 'Inappropriate Image';
  bool _isSubmitting = false;

  // ---> NEW: Controller for the optional details text field
  final TextEditingController _detailsController = TextEditingController();

  // List of reasons a user can choose from
  final List<String> _reportReasons = [
    'Inappropriate Image',
    'Cyberbullying or Harassment',
    'Spam or Scam',
    'Hate Speech',
    'Violence or Dangerous Organizations',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";

    // ---> NEW LOGIC: Combine the radio button reason with the optional text <---
    String finalReasonToSubmit = _selectedReason;
    if (_detailsController.text.trim().isNotEmpty) {
      finalReasonToSubmit = "$_selectedReason: ${_detailsController.text.trim()}";
    }

    // Safety check: Django's max_length is 200. We truncate it just in case!
    if (finalReasonToSubmit.length > 200) {
      finalReasonToSubmit = "${finalReasonToSubmit.substring(0, 197)}...";
    }

    try {
      var response = await http.post(
        Uri.parse('$url/user_report_post/'),
        body: {
          "lid": lid,
          "post_id": widget.postId,
          "reason": finalReasonToSubmit, // Sending the combined string to Django
        },
      );

      var data = json.decode(response.body);

      if (data['status'] == 'ok') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post reported to admin successfully."), backgroundColor: Colors.green),
          );
          // Go back to the feed after reporting
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error connecting to server."), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Post", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A11CB),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Wrapped the whole body in a SingleChildScrollView so the keyboard doesn't hide the submit button
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Why are you reporting this post?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your report is anonymous. If someone is in immediate danger, call the local emergency services.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Build the list of radio buttons
            ListView.builder(
              shrinkWrap: true, // Needed inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disables inner scrolling
              itemCount: _reportReasons.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  title: Text(_reportReasons[index]),
                  value: _reportReasons[index],
                  groupValue: _selectedReason,
                  activeColor: const Color(0xFF6A11CB),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 10),

            // ---> NEW: Optional Details Text Field <---
            const Text(
              "Additional Details (Optional)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 100, // Limits typing so we don't break the Django 200 char limit
              decoration: InputDecoration(
                hintText: "Tell us more about why you are reporting this...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Report", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}