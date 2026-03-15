import 'dart:async'; // 1. ADDED ASYNC IMPORT FOR THE TIMER
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final String toId;
  final String name;

  const ChatPage({
    super.key,
    required this.toId,
    required this.name,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List chats = [];
  String lid = "";
  String url = "";
  TextEditingController msgController = TextEditingController();
  bool loading = false;

  Timer? chatTimer;

  // --- ADDED VARIABLES FOR SCROLL TRACKING ---
  final ScrollController _scrollController = ScrollController();
  bool _showScrollDownButton = false;
  // -------------------------------------------

  @override
  void initState() {
    super.initState();

    // --- ADDED LISTENER TO TRACK SCROLL POSITION ---
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        // Check if we are scrolled up more than 100 pixels away from the bottom
        bool isScrolledUp = (_scrollController.position.maxScrollExtent - _scrollController.offset) > 100;

        // Update the UI only if the state needs to change
        if (_showScrollDownButton != isScrolledUp) {
          setState(() {
            _showScrollDownButton = isScrolledUp;
          });
        }
      }
    });
    // -----------------------------------------------

    initAndLoad();
  }

  @override
  void dispose() {
    chatTimer?.cancel();
    msgController.dispose();
    _scrollController.dispose(); // ADDED DISPOSE FOR CONTROLLER
    super.dispose();
  }

  Future<void> initAndLoad() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    lid = sh.getString('lid') ?? "";
    url = sh.getString('url') ?? "";

    print("📌 LOGGED IN ID (lid): $lid");
    print("📌 TO USER ID: ${widget.toId}");
    print("📌 BASE URL: $url");

    if (lid.isEmpty || widget.toId.isEmpty) {
      print("❌ ERROR: Invalid IDs");
      return;
    }

    loadChat();

    chatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      loadChat();
    });
  }

  // --- ADDED FUNCTION TO SCROLL TO BOTTOM ---
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  // ------------------------------------------

  // ---------- LOAD CHAT ----------
  Future<void> loadChat() async {
    print("🔄 Loading chat...");
    print("➡️ from_id: $lid , to_id: ${widget.toId}");

    try {
      final res = await http.post(
        Uri.parse('$url/user_view_chat/'),
        body: {
          'from_id': lid,
          'to_id': widget.toId,
        },
      );

      print("✅ loadChat STATUS CODE: ${res.statusCode}");
      print("📩 loadChat RESPONSE: ${res.body}");

      final data = jsonDecode(res.body);

      if (data['status'] == 'ok') {
        setState(() {
          chats = data['data'];
        });
        print("💬 TOTAL MESSAGES: ${chats.length}");

        // --- ADDED: ONLY JUMP TO BOTTOM IF USER IS NOT SCROLLED UP ---
        if (!_showScrollDownButton) {
          _scrollToBottom();
        }
        // -------------------------------------------------------------

      } else {
        print("❌ loadChat FAILED");
      }
    } catch (e) {
      print("❌ loadChat ERROR: $e");
    }
  }

  // ---------- SEND MESSAGE ----------
  Future<void> sendMessage() async {
    if (msgController.text.trim().isEmpty) {
      print("⚠️ Empty message, not sending");
      return;
    }

    print("📤 Sending message...");
    print("➡️ FROM: $lid TO: ${widget.toId}");
    print("📝 MESSAGE: ${msgController.text}");

    try {
      setState(() => loading = true);

      final res = await http.post(
        Uri.parse('$url/user_send_message/'),
        body: {
          'fid': lid,
          'tid': widget.toId,
          'message': msgController.text.trim(),
        },
      );

      print("✅ sendMessage STATUS CODE: ${res.statusCode}");
      print("📩 sendMessage RESPONSE: ${res.body}");

      msgController.clear();

      // Force the list to scroll to the newly sent message
      setState(() => _showScrollDownButton = false);
      loadChat();

    } catch (e) {
      print("❌ sendMessage ERROR: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Expanded(
            // --- ADDED STACK TO OVERLAY THE ARROW BUTTON ---
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController, // ADDED CONTROLLER HERE
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    bool isMe =
                        chats[index]['from_id'].toString() == lid;

                    print(
                        "🧾 MSG ${index + 1}: from ${chats[index]['from_id']}");

                    return Align(
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          chats[index]['message'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // --- ADDED FLOATING DOWN ARROW WHEN SCROLLED UP ---
                if (_showScrollDownButton)
                  Positioned(
                    bottom: 10,
                    right: 15,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.indigo,
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ),
                  ),
                // --------------------------------------------------
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: msgController,
                    decoration: const InputDecoration(
                      hintText: "Message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: loading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send, color: Colors.indigo),
                onPressed: loading ? null : sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}