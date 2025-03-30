import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'update_profile_dialog.dart';
import 'package:cow_and_crop/constants.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final String baseUrl = BASE_URL;
  String? userId;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    if (userId == null || userId!.isEmpty) {
      setState(() {
        errorMessage = "User not logged in";
        isLoading = false;
      });
      return;
    }
    try {
      final response = await http.get(Uri.parse("${baseUrl}api/users/$userId"));
      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load profile: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  void _openUpdateProfileDialog() async {
    if (userData != null) {
      await showDialog(
        context: context,
        builder:
            (context) => UpdateProfileDialog(
              userData: userData!,
              onUpdated: _loadUserProfile,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.green[200],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (userData?["profilePhoto"] != null)
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                "$baseUrl${(userData?["profilePhoto"] as String).replaceAll("\\", "/")}",
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            "Name: ${userData?["name"] ?? ""}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            "Age: ${userData?["age"] ?? ""}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            "Gender: ${userData?["gender"] ?? ""}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            "Email: ${userData?["email"] ?? ""}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            "Phone: ${userData?["phone"] ?? ""}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            "Address: ${userData?["address"] ?? ""}",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openUpdateProfileDialog,
        backgroundColor: Colors.green[200],
        child: const Icon(Icons.edit),
      ),
    );
  }
}
