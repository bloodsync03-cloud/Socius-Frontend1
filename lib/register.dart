// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:iconsax/iconsax.dart';
// import 'login.dart';
// import 'package:intl/intl.dart';
//
// class UserSignUp extends StatefulWidget {
//   const UserSignUp({super.key});
//
//   @override
//   State<UserSignUp> createState() => _UserSignUpState();
// }
//
// class _UserSignUpState extends State<UserSignUp> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();
//   final TextEditingController _placeController = TextEditingController();
//   final TextEditingController _bioController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//   TextEditingController();
//
//   String _selectedGender = 'Male';
//   String _selectedAccounttype ='Public';
//   File? _selectedImage;
//
//   /// PICK IMAGE
//   Future<void> _chooseImage() async {
//     final pickedFile =
//     await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() => _selectedImage = File(pickedFile.path));
//     } else {
//       Fluttertoast.showToast(msg: "No image selected");
//     }
//   }
//
//   /// PICK DOB
//   Future<void> _pickDate() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime(2000),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
//     }
//   }
//
//   /// SUBMIT FORM
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     if (_passwordController.text != _confirmPasswordController.text) {
//       Fluttertoast.showToast(msg: "Passwords do not match");
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String? url = sh.getString('url');
//
//     if (url == null) {
//       Fluttertoast.showToast(msg: "Server URL not configured");
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     var request = http.MultipartRequest(
//       'POST',
//       Uri.parse('$url/userregister/'),
//     );
//
//     // Add fields
//     request.fields['username'] = _usernameController.text.trim();
//     request.fields['name'] = _nameController.text.trim();
//     request.fields['email'] = _emailController.text.trim();
//     request.fields['phonenumber'] = _phoneController.text.trim();
//     request.fields['dob'] = _dobController.text.trim();
//     request.fields['place'] = _placeController.text.trim();
//     request.fields['gender'] = _selectedGender;
//     request.fields['account_type'] = _selectedAccounttype;
//     request.fields['bio'] = _bioController.text.trim();
//     request.fields['password'] = _passwordController.text.trim();
//     request.fields['cpassword'] = _confirmPasswordController.text.trim();
//
//     // Add profile picture if selected
//     if (_selectedImage != null) {
//       request.files.add(
//         await http.MultipartFile.fromPath('photo', _selectedImage!.path),
//       );
//     }
//
//     try {
//       var response = await request.send();
//       var responseString = await response.stream.bytesToString();
//       var data = jsonDecode(responseString);
//
//       if (response.statusCode == 200 && data['status'] == 'ok') {
//         Fluttertoast.showToast(msg: "Signup Successful 🎉");
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => const LoginPage(title: "Login"),
//           ),
//         );
//       } else {
//         Fluttertoast.showToast(msg: data['message'] ?? "Signup Failed");
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Network Error: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FBFF),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 /// PROFILE IMAGE
//                 GestureDetector(
//                   onTap: _chooseImage,
//                   child: CircleAvatar(
//                     radius: 40,
//                     backgroundColor: Colors.grey[200],
//                     backgroundImage:
//                     _selectedImage != null ? FileImage(_selectedImage!) : null,
//                     child: _selectedImage == null
//                         ? const Icon(Iconsax.user, size: 32, color: Colors.grey)
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text("Tap to choose profile picture",
//                     style: TextStyle(fontSize: 11, color: Colors.grey[600])),
//
//                 const SizedBox(height: 16),
//
//                 /// USERNAME
//                 _buildFormField(
//                   controller: _usernameController,
//                   label: "Username",
//                   hintText: "Enter username",
//                   icon: Iconsax.user,
//                   validator: (v) => v!.isEmpty ? "Enter username" : null,
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// FULL NAME
//                 _buildFormField(
//                   controller: _nameController,
//                   label: "Full Name",
//                   hintText: "Enter full name",
//                   icon: Iconsax.user,
//                   validator: (v) => v!.isEmpty ? "Enter name" : null,
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// EMAIL
//                 _buildFormField(
//                   controller: _emailController,
//                   label: "Email",
//                   hintText: "example@gmail.com",
//                   icon: Iconsax.sms,
//                   validator: (v) =>
//                   !RegExp(r'\S+@\S+\.\S+').hasMatch(v!) ? "Invalid email" : null,
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// PHONE
//                 _buildFormField(
//                   controller: _phoneController,
//                   label: "Phone",
//                   hintText: "10 digit number",
//                   icon: Iconsax.call,
//                   validator: (v) =>
//                   !RegExp(r'^[0-9]{10}$').hasMatch(v!) ? "Invalid phone" : null,
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// DOB
//                 TextFormField(
//                   controller: _dobController,
//                   readOnly: true,
//                   onTap: _pickDate,
//                   decoration: InputDecoration(
//                     labelText: "Date of Birth",
//                     prefixIcon: const Icon(Icons.calendar_today, size: 16),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   validator: (v) => v!.isEmpty ? "Select date of birth" : null,
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// PLACE
//                 _buildFormField(
//                   controller: _placeController,
//                   label: "Place",
//                   hintText: "Enter your city",
//                   icon: Icons.location_city,
//                   validator: (v) => v!.isEmpty ? "Enter place" : null,
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// BIO
//                 _buildFormField(
//                   controller: _bioController,
//                   label: "Bio",
//                   hintText: "Tell us something about yourself",
//                   icon: Icons.info_outline,
//                   validator: (v) => v!.isEmpty ? "Enter bio" : null,
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// GENDER
//                 const Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Gender",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF8FBFF),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.withOpacity(0.3)),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: DropdownButtonFormField<String>(
//                     value: _selectedGender,
//                     dropdownColor: Colors.white,
//                     iconEnabledColor: const Color(0xFF64B5F6),
//                     style: const TextStyle(color: Colors.black, fontSize: 13),
//                     decoration: const InputDecoration(border: InputBorder.none),
//                     items: const [
//                       DropdownMenuItem(
//                           value: "Male",
//                           child: Text("Male", style: TextStyle(color: Colors.black))),
//                       DropdownMenuItem(
//                           value: "Female",
//                           child:
//                           Text("Female", style: TextStyle(color: Colors.black))),
//                       DropdownMenuItem(
//                           value: "Other",
//                           child: Text("Other", style: TextStyle(color: Colors.black))),
//                     ],
//                     onChanged: (value) => setState(() => _selectedGender = value!),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 const Align(
//                   alignment: Alignment.centerLeft,
//                   child: Text(
//                     "Account Type",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
//                   ),
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF8FBFF),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey.withOpacity(0.3)),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: DropdownButtonFormField<String>(
//                     value: _selectedAccounttype,
//                     dropdownColor: Colors.white,
//                     iconEnabledColor: const Color(0xFF64B5F6),
//                     style: const TextStyle(color: Colors.black, fontSize: 13),
//                     decoration: const InputDecoration(border: InputBorder.none),
//                     items: const [
//                       DropdownMenuItem(
//                           value: "Public",
//                           child: Text("Public", style: TextStyle(color: Colors.black))),
//                       DropdownMenuItem(
//                           value: "Private",
//                           child:
//                           Text("Private", style: TextStyle(color: Colors.black))),
//                     ],
//                     onChanged: (value) => setState(() => _selectedAccounttype = value!),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// PASSWORD
//                 _buildPasswordField(
//                     controller: _passwordController, label: "Password", isConfirm: false),
//                 const SizedBox(height: 12),
//                 _buildPasswordField(
//                     controller: _confirmPasswordController,
//                     label: "Confirm Password",
//                     isConfirm: true),
//                 const SizedBox(height: 20),
//
//                 /// SUBMIT BUTTON
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submit,
//                     child: _isLoading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text("Create Account"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// FORM FIELD
//   Widget _buildFormField({
//     required TextEditingController controller,
//     required String label,
//     required String hintText,
//     required IconData icon,
//     required String? Function(String?) validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       validator: validator,
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hintText,
//         prefixIcon: Icon(icon, size: 16),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
//
//   /// PASSWORD FIELD
//   Widget _buildPasswordField({
//     required TextEditingController controller,
//     required String label,
//     required bool isConfirm,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: const Icon(Iconsax.lock, size: 16),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//         suffixIcon: IconButton(
//           icon: Icon(
//               isConfirm
//                   ? (_obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye)
//                   : (_obscurePassword ? Iconsax.eye_slash : Iconsax.eye),
//               size: 16),
//           onPressed: () {
//             setState(() {
//               if (isConfirm) {
//                 _obscureConfirmPassword = !_obscureConfirmPassword;
//               } else {
//                 _obscurePassword = !_obscurePassword;
//               }
//             });
//           },
//         ),
//       ),
//       validator: (v) {
//         if (v!.isEmpty) return "Enter ${label.toLowerCase()}";
//         if (isConfirm && v != _passwordController.text) return "Passwords do not match";
//         return null;
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _dobController.dispose();
//     _placeController.dispose();
//     _bioController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
// }
// import 'dart:convert';
// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:intl/intl.dart';
// import 'login.dart';
//
// class UserSignUp extends StatefulWidget {
//   const UserSignUp({super.key});
//
//   @override
//   State<UserSignUp> createState() => _UserSignUpState();
// }
//
// class _UserSignUpState extends State<UserSignUp>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//
//   late AnimationController _bgController;
//
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();
//   final TextEditingController _placeController = TextEditingController();
//   final TextEditingController _bioController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//   TextEditingController();
//
//   String _selectedGender = 'Male';
//   String _selectedAccounttype = 'Public';
//   File? _selectedImage;
//
//   @override
//   void initState() {
//     super.initState();
//     _bgController =
//     AnimationController(vsync: this, duration: const Duration(seconds: 6))
//       ..repeat(reverse: true);
//   }
//
//   /* ---------------- BACKGROUND ---------------- */
//
//   Widget animatedBackground() {
//     return AnimatedBuilder(
//       animation: _bgController,
//       builder: (context, child) {
//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color.lerp(
//                     const Color(0xff000428), const Color(0xff004e92), _bgController.value)!,
//                 const Color(0xff000000),
//                 const Color(0xff141e30),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   /* ---------------- IMAGE PICK ---------------- */
//
//   Future<void> _chooseImage() async {
//     final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (picked != null) setState(() => _selectedImage = File(picked.path));
//   }
//
//   Future<void> _pickDate() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime(2000),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
//     }
//   }
//
//   /* ---------------- SUBMIT ---------------- */
//
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_passwordController.text != _confirmPasswordController.text) {
//       Fluttertoast.showToast(msg: "Passwords not match");
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String? url = sh.getString('url');
//
//     if (url == null) {
//       Fluttertoast.showToast(msg: "Server URL not set");
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     var request =
//     http.MultipartRequest('POST', Uri.parse('$url/userregister/'));
//
//     request.fields['username'] = _usernameController.text;
//     request.fields['name'] = _nameController.text;
//     request.fields['email'] = _emailController.text;
//     request.fields['phonenumber'] = _phoneController.text;
//     request.fields['dob'] = _dobController.text;
//     request.fields['place'] = _placeController.text;
//     request.fields['gender'] = _selectedGender;
//     request.fields['account_type'] = _selectedAccounttype;
//     request.fields['bio'] = _bioController.text;
//     request.fields['password'] = _passwordController.text;
//     request.fields['cpassword'] = _confirmPasswordController.text;
//
//     if (_selectedImage != null) {
//       request.files.add(
//           await http.MultipartFile.fromPath('photo', _selectedImage!.path));
//     }
//
//     try {
//       var res = await request.send();
//       var respStr = await res.stream.bytesToString();
//       var data = jsonDecode(respStr);
//
//       if (data['status'] == 'ok') {
//         Fluttertoast.showToast(msg: "Signup Successful 🎉");
//         Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => const LoginPage(title: "Login")));
//       } else {
//         Fluttertoast.showToast(msg: "Signup Failed");
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Network Error");
//     }
//
//     setState(() => _isLoading = false);
//   }
//
//   /* ---------------- UI ---------------- */
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           animatedBackground(),
//           SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(18),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   const Text("Create Account",
//                       style: TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white)),
//                   const SizedBox(height: 20),
//                   glassForm()
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   /* ---------------- GLASS FORM ---------------- */
//
//   Widget glassForm() {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(25),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(25),
//             color: Colors.white.withOpacity(0.08),
//             border: Border.all(color: Colors.white24),
//           ),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 GestureDetector(
//                   onTap: _chooseImage,
//                   child: CircleAvatar(
//                     radius: 45,
//                     backgroundColor: Colors.white24,
//                     backgroundImage: _selectedImage != null
//                         ? FileImage(_selectedImage!)
//                         : null,
//                     child: _selectedImage == null
//                         ? const Icon(Iconsax.user, size: 35, color: Colors.white)
//                         : null,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 field(_usernameController, "Username", Iconsax.user),
//                 field(_nameController, "Full Name", Iconsax.user),
//                 field(_emailController, "Email", Iconsax.sms),
//                 field(_phoneController, "Phone", Iconsax.call),
//
//                 TextFormField(
//                   controller: _dobController,
//                   readOnly: true,
//                   onTap: _pickDate,
//                   style: const TextStyle(color: Colors.white),
//                   decoration: inputStyle("DOB", Iconsax.calendar),
//                   validator: (v) => v!.isEmpty ? "Select DOB" : null,
//                 ),
//
//                 field(_placeController, "Place", Iconsax.location),
//                 field(_bioController, "Bio", Iconsax.info_circle),
//
//                 passwordField(_passwordController, "Password", false),
//                 passwordField(_confirmPasswordController, "Confirm", true),
//
//                 const SizedBox(height: 20),
//                 cinematicButton()
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /* ---------------- FIELDS ---------------- */
//
//   Widget field(TextEditingController c, String h, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: c,
//         style: const TextStyle(color: Colors.white),
//         validator: (v) => v!.isEmpty ? "Enter $h" : null,
//         decoration: inputStyle(h, icon),
//       ),
//     );
//   }
//
//   Widget passwordField(
//       TextEditingController c, String h, bool confirm) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: c,
//         obscureText: confirm ? _obscureConfirmPassword : _obscurePassword,
//         style: const TextStyle(color: Colors.white),
//         decoration: inputStyle(h, Iconsax.lock).copyWith(
//           suffixIcon: IconButton(
//             icon: Icon(Iconsax.eye, color: Colors.white),
//             onPressed: () {
//               setState(() {
//                 if (confirm) {
//                   _obscureConfirmPassword = !_obscureConfirmPassword;
//                 } else {
//                   _obscurePassword = !_obscurePassword;
//                 }
//               });
//             },
//           ),
//         ),
//         validator: (v) => v!.isEmpty ? "Enter $h" : null,
//       ),
//     );
//   }
//
//   InputDecoration inputStyle(String hint, IconData icon) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: const TextStyle(color: Colors.grey),
//       prefixIcon: Icon(icon, color: Colors.cyanAccent),
//       filled: true,
//       fillColor: Colors.white.withOpacity(.07),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//       enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Colors.white24)),
//     );
//   }
//
//   /* ---------------- BUTTON ---------------- */
//
//   Widget cinematicButton() {
//     return GestureDetector(
//       onTap: _isLoading ? null : _submit,
//       child: Container(
//         width: double.infinity,
//         height: 55,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           gradient:
//           const LinearGradient(colors: [Colors.cyan, Colors.blueAccent]),
//           boxShadow: const [
//             BoxShadow(color: Colors.cyanAccent, blurRadius: 25)
//           ],
//         ),
//         child: Center(
//           child: _isLoading
//               ? const CircularProgressIndicator(color: Colors.black)
//               : const Text("CREATE ACCOUNT",
//               style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16)),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for Socius Logo
import 'login.dart';

class UserSignUp extends StatefulWidget {
  const UserSignUp({super.key});

  @override
  State<UserSignUp> createState() => _UserSignUpState();
}

class _UserSignUpState extends State<UserSignUp>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _bgController;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  String _selectedGender = 'Male';
  String _selectedAccounttype = 'Public';
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _bgController =
    AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  /* ---------------- BACKGROUND ---------------- */

  Widget animatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // CHANGED: Light pastel gradient matching the Login screen
              colors: [
                Color.lerp(
                    const Color(0xFF8EC5FC), const Color(0xFFE0C3FC), _bgController.value)!,
                const Color(0xFFCFDEF3),
                const Color(0xFFFBC2EB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }

  /* ---------------- IMAGE PICK ---------------- */

  Future<void> _chooseImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  /* ---------------- SUBMIT ---------------- */

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(msg: "Passwords not match");
      return;
    }

    setState(() => _isLoading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');

    if (url == null) {
      Fluttertoast.showToast(msg: "Server URL not set");
      setState(() => _isLoading = false);
      return;
    }

    var request =
    http.MultipartRequest('POST', Uri.parse('$url/userregister/'));

    request.fields['username'] = _usernameController.text;
    request.fields['name'] = _nameController.text;
    request.fields['email'] = _emailController.text;
    request.fields['phonenumber'] = _phoneController.text;
    request.fields['dob'] = _dobController.text;
    request.fields['place'] = _placeController.text;
    request.fields['gender'] = _selectedGender;
    request.fields['account_type'] = _selectedAccounttype;
    request.fields['bio'] = _bioController.text;
    request.fields['password'] = _passwordController.text;
    request.fields['cpassword'] = _confirmPasswordController.text;

    if (_selectedImage != null) {
      request.files.add(
          await http.MultipartFile.fromPath('photo', _selectedImage!.path));
    }

    try {
      var res = await request.send();
      var respStr = await res.stream.bytesToString();
      var data = jsonDecode(respStr);

      if (data['status'] == 'ok') {
        Fluttertoast.showToast(msg: "Signup Successful 🎉");
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const LoginPage(title: "Login")));
      } else {
        Fluttertoast.showToast(msg: "Signup Failed");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Network Error");
    }

    setState(() => _isLoading = false);
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          animatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25), // Adjusted padding
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- SOCIUS LOGO ---
                  Text(
                    "Socius",
                    style: GoogleFonts.aladin(
                      textStyle: const TextStyle(
                        fontSize: 42,
                        color: Colors.deepPurple,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  // -------------------

                  const SizedBox(height: 5),
                  const Text("Create Account",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54)),
                  const SizedBox(height: 30),
                  formFieldsList() // Replaced the heavy glass wrapper with just the fields
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /* ---------------- FORM LIST ---------------- */

  Widget formFieldsList() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          GestureDetector(
            onTap: _chooseImage,
            child: CircleAvatar(
              radius: 45,
              // Light transparent background for the avatar
              backgroundColor: Colors.white.withOpacity(0.5),
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : null,
              child: _selectedImage == null
                  ? const Icon(Iconsax.camera, size: 35, color: Colors.deepPurpleAccent)
                  : null,
            ),
          ),
          const SizedBox(height: 25),

          field(_usernameController, "Username", Iconsax.user),
          field(_nameController, "Full Name", Iconsax.user),
          field(_emailController, "Email", Iconsax.sms),
          field(_phoneController, "Phone", Iconsax.call),

          // Wrapped DOB in the glass helper too
          glassTextFieldWrapper(
            TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: _pickDate,
              style: const TextStyle(color: Colors.black87), // Dark text
              decoration: inputStyle("DOB", Iconsax.calendar),
              validator: (v) => v!.isEmpty ? "Select DOB" : null,
            ),
          ),

          field(_placeController, "Place", Iconsax.location),
          field(_bioController, "Bio", Iconsax.info_circle),

          passwordField(_passwordController, "Password", false),
          passwordField(_confirmPasswordController, "Confirm", true),

          const SizedBox(height: 20),
          cinematicButton(),
          const SizedBox(height: 20),

          // Back to login button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account? ", style: TextStyle(color: Colors.black54)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text("Login", style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /* ---------------- GLASS HELPER ---------------- */
  // This helper applies the frosted glass effect specifically to the text fields
  Widget glassTextFieldWrapper(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: child,
        ),
      ),
    );
  }

  /* ---------------- FIELDS ---------------- */

  Widget field(TextEditingController c, String h, IconData icon) {
    return glassTextFieldWrapper(
      TextFormField(
        controller: c,
        style: const TextStyle(color: Colors.black87), // Dark text
        validator: (v) => v!.isEmpty ? "Enter $h" : null,
        decoration: inputStyle(h, icon),
      ),
    );
  }

  Widget passwordField(TextEditingController c, String h, bool confirm) {
    return glassTextFieldWrapper(
      TextFormField(
        controller: c,
        obscureText: confirm ? _obscureConfirmPassword : _obscurePassword,
        style: const TextStyle(color: Colors.black87), // Dark text
        decoration: inputStyle(h, Iconsax.lock).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              confirm
                  ? (_obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye)
                  : (_obscurePassword ? Iconsax.eye_slash : Iconsax.eye),
              color: Colors.deepPurpleAccent,
            ),
            onPressed: () {
              setState(() {
                if (confirm) {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
              });
            },
          ),
        ),
        validator: (v) => v!.isEmpty ? "Enter $h" : null,
      ),
    );
  }

  // Updated input style to match the frosted glass look
  InputDecoration inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.35), // Transparent white
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
      ),
    );
  }

  /* ---------------- BUTTON ---------------- */

  Widget cinematicButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.blueAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("CREATE ACCOUNT",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ),
    );
  }
}