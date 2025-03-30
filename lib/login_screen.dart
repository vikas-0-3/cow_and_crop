import 'package:cow_and_crop/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/admin_dashboard.dart';
import 'farmer/farmer_dashboard.dart';
import 'user/user_dashboard.dart';
import 'constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  final String baseUrl = BASE_URL;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  // Check if user is already logged in
  Future<void> _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString("userId");
    final String? role = prefs.getString("role");
    if (userId != null && role != null) {
      // User is already logged in; navigate to the appropriate dashboard
      _navigateToDashboard(role);
    }
  }

  // Navigate to dashboard based on role
  void _navigateToDashboard(String role) {
    if (role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (role == "farmer") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FarmerDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserDashboard()),
      );
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final Uri uri = Uri.parse("${baseUrl}api/auth/login");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["message"] == "Logged in successfully") {
          final String role = data["role"];
          final String userId = data["userId"];

          // Save userId and role in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", userId);
          await prefs.setString("role", role);

          // Navigate based on role
          _navigateToDashboard(role);
        } else {
          setState(() {
            _errorMessage = data["message"] ?? "Login failed";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Invalid Credentials! Please try again.";
        });
      }
    } catch (err) {
      setState(() {
        _errorMessage = "Error: $err";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // TOP-RIGHT PINK SHAPE
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E99),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          // BOTTOM-LEFT PINK SHAPE
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFFFA4D3),
                borderRadius: BorderRadius.only(topRight: Radius.circular(100)),
              ),
            ),
          ),
          // MAIN CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Hey! Good to see you again",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  // EMAIL FIELD
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      hintText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // PASSWORD FIELD
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      hintText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // REMEMBER ME + FORGOT PASSWORD
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: Colors.pink,
                          ),
                          const Text("Remember me"),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement Forgot Password logic
                        },
                        child: const Text(
                          "Forgot password?",
                          style: TextStyle(color: Colors.pink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // SIGN IN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "SIGN IN",
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const Spacer(),
                  // SIGN UP TEXT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account? "),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Sign Up Screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistrationPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
