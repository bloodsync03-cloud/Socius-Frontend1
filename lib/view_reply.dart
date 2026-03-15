import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Reply',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ViewReply(),
    );
  }
}

class ViewReply extends StatefulWidget {
  const ViewReply({super.key});

  @override
  State<ViewReply> createState() => _ViewReplyState();
}

class _ViewReplyState extends State<ViewReply> {

  List<String> complaint_ = [];
  List<String> reply_ = [];
  List<String> status_ = [];

  @override
  void initState() {
    super.initState();
    viewReply();
  }

  Future<void> viewReply() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urlBase = sh.getString('url') ?? '';
      String lid = sh.getString('lid') ?? '';

      final response = await http.post(
        Uri.parse('$urlBase/user_view_complaint_reply/'),
        body: {'lid': lid},
      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata['data'];

        List<String> complaint = [];
        List<String> reply = [];
        List<String> status = [];

        for (int i = 0; i < arr.length; i++) {
          complaint.add(arr[i]['complaint'].toString());
          reply.add(arr[i]['reply'].toString());
          status.add(arr[i]['status'].toString());
        }

        setState(() {
          complaint_ = complaint;
          reply_ = reply;
          status_ = status;
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("REPLIES"),
        backgroundColor: Colors.indigo,
      ),
      body: complaint_.isEmpty
          ? const Center(
        child: Text(
          "No complaints found",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: complaint_.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.black, Colors.indigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Icon(Icons.report_problem,
                            color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            complaint_[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(Icons.reply, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reply_[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(
                          status_[index].toLowerCase() == "pending"
                              ? Icons.cancel
                              : Icons.check_circle,
                          color: status_[index].toLowerCase() == "pending"
                              ? Colors.red
                              : Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status_[index],
                          style: TextStyle(
                            color:
                            status_[index].toLowerCase() == "pending"
                                ? Colors.red
                                : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
