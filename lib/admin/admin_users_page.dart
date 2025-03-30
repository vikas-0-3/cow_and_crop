import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cow_and_crop/constants.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  _AdminUsersPageState createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final String baseUrl = BASE_URL;
  late Future<List<dynamic>> futureUsers;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(Uri.parse("${baseUrl}api/users/allusers"));
    if (response.statusCode == 200) {
      List<dynamic> users = jsonDecode(response.body) as List<dynamic>;
      return users;
    } else {
      throw Exception("Failed to load users");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        backgroundColor: const Color(0xFFFFA4D3),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          } else {
            List<dynamic> users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                // Build the profile image URL by replacing backslashes with forward slashes.
                final String imageUrl =
                    baseUrl +
                    (user["profilePhoto"] as String).replaceAll("\\", "/");
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 60);
                        },
                      ),
                    ),
                    title: Text(user["name"] ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Age: ${user["age"]}"),
                        Text("Gender: ${user["gender"]}"),
                        Text("Email: ${user["email"]}"),
                        Text("Phone: ${user["phone"]}"),
                        Text("Address: ${user["address"]}"),
                        Text("Role: ${user["role"]}"),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
