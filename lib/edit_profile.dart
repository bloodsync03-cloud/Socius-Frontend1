import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class UserEditProfile extends StatefulWidget {
  const UserEditProfile({super.key});

  @override
  State<UserEditProfile> createState() => _UserEditProfileState();
}

class _UserEditProfileState extends State<UserEditProfile> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedAccounttype = 'Public';
  File? _selectedImage;
  String _currentPhoto = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load existing user info
  Future<void> _loadUserData() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? lid = sh.getString('lid');
    String? imgUrl = sh.getString('img_url');

    if (url == null || lid == null) return;

    final response = await http.post(
      Uri.parse('$url/user_view_profile/'),
      body: {'lid': lid},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        final user = data['data'];
        setState(() {
          _usernameController.text = user['username'] ?? '';
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _phoneController.text = user['phone'] ?? '';
          _dobController.text = user['dob'] ?? '';
          _placeController.text = user['place'] ?? '';
          _bioController.text = user['bio'] ?? '';
          _selectedGender = user['gender'] ?? 'Male';
          _selectedAccounttype = user['account_type'] ?? 'Public';
          _currentPhoto = (imgUrl ?? '') + (user['photo'] ?? '');
        });
      }
    }
  }

  /// Pick profile image
  Future<void> _chooseImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  /// Pick date of birth
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
  }

  /// Submit form
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? lid = sh.getString('lid');

    if (url == null || lid == null) {
      Fluttertoast.showToast(msg: "Server URL or User ID not found");
      setState(() => _isLoading = false);
      return;
    }

    var request = http.MultipartRequest('POST', Uri.parse('$url/user_update_profile/'));
    request.fields['lid'] = lid; // **must send user ID**
    request.fields['username'] = _usernameController.text.trim();
    request.fields['name'] = _nameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['phonenumber'] = _phoneController.text.trim();
    request.fields['dob'] = _dobController.text.trim();
    request.fields['place'] = _placeController.text.trim();
    request.fields['gender'] = _selectedGender;
    request.fields['account_type'] = _selectedAccounttype;
    request.fields['bio'] = _bioController.text.trim();

    if (_selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', _selectedImage!.path));
    }

    var response = await request.send();
    var responseString = await response.stream.bytesToString();
    var data = jsonDecode(responseString);

    if (response.statusCode == 200 && data['status'] == 'ok') {
      Fluttertoast.showToast(msg: "Profile Updated Successfully");
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: data['message'] ?? "Update Failed");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(title: const Text("Edit Profile"), backgroundColor: Colors.green),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// Profile image
                GestureDetector(
                  onTap: _chooseImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentPhoto.isNotEmpty ? NetworkImage(_currentPhoto) : null) as ImageProvider<Object>?,
                    child: (_selectedImage == null && _currentPhoto.isEmpty)
                        ? const Icon(Iconsax.user, size: 32, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text("Tap to choose profile picture",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 16),

                _buildFormField(_usernameController, "Username", "Enter username", Iconsax.user),
                const SizedBox(height: 12),
                _buildFormField(_nameController, "Full Name", "Enter full name", Iconsax.user),
                const SizedBox(height: 12),
                _buildFormField(_emailController, "Email", "example@gmail.com", Iconsax.sms),
                const SizedBox(height: 12),
                _buildFormField(_phoneController, "Phone", "10 digit number", Iconsax.call),
                const SizedBox(height: 12),

                /// DOB
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    prefixIcon: const Icon(Icons.calendar_today, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),

                _buildFormField(_placeController, "Place", "Enter your city", Icons.location_city),
                const SizedBox(height: 12),
                _buildFormField(_bioController, "Bio", "Tell us something about yourself", Icons.info_outline),
                const SizedBox(height: 12),

                /// Gender
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                    DropdownMenuItem(value: "Other", child: Text("Other")),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v!),
                  decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                /// Account type
                DropdownButtonFormField<String>(
                  value: _selectedAccounttype,
                  items: const [
                    DropdownMenuItem(value: "Public", child: Text("Public")),
                    DropdownMenuItem(value: "Private", child: Text("Private")),
                  ],
                  onChanged: (v) => setState(() => _selectedAccounttype = v!),
                  decoration: const InputDecoration(labelText: "Account Type", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),

                /// Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Update Profile"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(TextEditingController controller, String label, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (v) => v!.isEmpty ? "Enter $label" : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _placeController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
