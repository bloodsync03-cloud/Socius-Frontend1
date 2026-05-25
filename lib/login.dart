import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'register.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

/* -------------------- APP -------------------- */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Socius',
      theme: ThemeData.light().copyWith(
        useMaterial3: true,
      ),
      home: const LoginPage(title: 'Login'),
    );
  }
}

/* -------------------- LOGIN PAGE -------------------- */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /* -------------------- UI -------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          animatedBackground(),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: cinematicLoginCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------- ANIMATED BACKGROUND -------------------- */

  Widget animatedBackground() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                    const Color(0xFF8EC5FC), const Color(0xFFE0C3FC), _controller.value)!,
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

  /* -------------------- LOGIN CARD -------------------- */

  Widget cinematicLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- SOCIUS LOGO ---
          const Text(
            "Socius",
            style: TextStyle(
              fontFamily: 'BetaniaPatmos', // <--- Changed to custom font family
              fontSize: 60,
              color: Colors.deepPurple,
              letterSpacing: 1.5,
            ),
          ),
          // -------------------

          const SizedBox(height: 40),

          Form(
            key: _formKey,
            child: Column(
              children: [
                textField(
                  controller: usernameController,
                  hint: "Username",
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),
                textField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 30),
                loginButton(),
                const SizedBox(height: 20),
                registerRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------- TEXTFIELD -------------------- */

  Widget textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(color: Colors.black87),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Enter $hint";
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.35),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.deepPurpleAccent),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            )
                : null,
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
          ),
        ),
      ),
    );
  }

  /* -------------------- LOGIN BUTTON -------------------- */

  Widget loginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _login,
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
              : const Text("LOGIN",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
    );
  }

  /* -------------------- REGISTER -------------------- */

  Widget registerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have account?", style: TextStyle(color: Colors.black54)),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserSignUp()),
            );
          },
          child: const Text("Create Account",
              style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  /* -------------------- LOGIN API -------------------- */

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String url = sh.getString("url") ?? "http://YOUR-IP:8000/myapp";

      final response = await http.post(
        Uri.parse("$url/user_login/"),
        body: {
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "ok") {
          sh.setString("lid", data["lid"].toString());
          Fluttertoast.showToast(msg: "Login Successful");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (data["status"] == "blocked") {
          Fluttertoast.showToast(msg: "Blocked by admin");
        } else {
          Fluttertoast.showToast(msg: "Invalid Login");
        }
      } else {
        Fluttertoast.showToast(msg: "Server error");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Network error");
    }

    setState(() => _isLoading = false);
  }
}