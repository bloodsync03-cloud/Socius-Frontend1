import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Ratings extends StatefulWidget {
  const Ratings({super.key});

  @override
  State<Ratings> createState() => _RatingsState();
}

class _RatingsState extends State<Ratings> {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _loadingReviews = false;

  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  /// ---------------- POST TO SUBMIT REVIEW ----------------
  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    if (_reviewController.text.length > 500) {
      Fluttertoast.showToast(
          msg: "Review exceeds 500 characters",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      if (url == null || lid == null) {
        Fluttertoast.showToast(
            msg: "Session expired. Please login again",
            backgroundColor: Colors.red,
            textColor: Colors.white);
        return;
      }

      final response = await http.post(
        Uri.parse('$url/user_add_rating/'),
        body: {
          'lid': lid,
          'review': _reviewController.text.trim(),
          'rating': _ratingController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          Fluttertoast.showToast(
              msg: "Review submitted successfully!",
              backgroundColor: Colors.green,
              textColor: Colors.white);
          _reviewController.clear();
          _ratingController.clear();
          _loadReviews();
        } else {
          Fluttertoast.showToast(
              msg: data['message'] ?? "Submission failed",
              backgroundColor: Colors.red,
              textColor: Colors.white);
        }
      } else {
        Fluttertoast.showToast(
            msg: "Server error ${response.statusCode}",
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Network error",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ---------------- POST TO LOAD REVIEWS ----------------
  Future<void> _loadReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      if (url == null || lid == null) return;

      final response = await http.post(
        Uri.parse('$url/user_view_reviews/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            _reviews = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Failed to load reviews",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    } finally {
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reviews & Ratings"),
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Review Input
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _reviewController,
                          maxLength: 500,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: "Write your review...",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter review";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _ratingController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Rating (1-5)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter rating";
                            }
                            int? rating = int.tryParse(value);
                            if (rating == null || rating < 1 || rating > 5) {
                              return "Rating must be 1 to 5";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitReview,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                                : const Text("Submit Review"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Reviews List
              _loadingReviews
                  ? const Center(child: CircularProgressIndicator())
                  : _reviews.isEmpty
                  ? const Text("No reviews yet")
                  : Column(
                children: _reviews
                    .map((r) => Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(r['review'] ?? ""),
                    subtitle: Text(
                        "Rating: ${r['rating'] ?? "-"}\nDate: ${r['date'] ?? "-"}"),
                  ),
                ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
