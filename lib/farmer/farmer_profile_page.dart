import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'update_profile_dialog.dart';
import 'update_farm_dialog.dart';
import 'package:cow_and_crop/constants.dart';

class FarmerProfilePage extends StatefulWidget {
  const FarmerProfilePage({Key? key}) : super(key: key);

  @override
  _FarmerProfilePageState createState() => _FarmerProfilePageState();
}

class _FarmerProfilePageState extends State<FarmerProfilePage> {
  final String baseUrl = BASE_URL;
  String? userId;
  Map<String, dynamic>? farmerData; // Contains both user and farm details
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarmerProfile();
  }

  Future<void> _loadFarmerProfile() async {
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
      final response = await http.get(
        Uri.parse("${baseUrl}api/farmers/$userId"),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            farmerData = data[0];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "No profile data found";
            isLoading = false;
          });
        }
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

  // Open update profile modal
  void _openUpdateProfile() async {
    await showDialog(
      context: context,
      builder:
          (context) => UpdateProfileDialog(
            userData: farmerData?["user"],
            onUpdated: _loadFarmerProfile,
          ),
    );
  }

  // Open update farm modal
  void _openUpdateFarm() async {
    await showDialog(
      context: context,
      builder:
          (context) => UpdateFarmDialog(
            farmData: farmerData!,
            onUpdated: _loadFarmerProfile,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Profile"),
        backgroundColor: Colors.amber,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Details Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Profile Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _openUpdateProfile,
                          child: const Text("Update Profile"),
                        ),
                      ],
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (farmerData?["user"]["profilePhoto"] != null)
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(
                                  "$baseUrl${farmerData?["user"]["profilePhoto"] as String}",
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text("Name: ${farmerData?["user"]["name"] ?? ""}"),
                            Text("Age: ${farmerData?["user"]["age"] ?? ""}"),
                            Text(
                              "Gender: ${farmerData?["user"]["gender"] ?? ""}",
                            ),
                            Text(
                              "Email: ${farmerData?["user"]["email"] ?? ""}",
                            ),
                            Text(
                              "Phone: ${farmerData?["user"]["phone"] ?? ""}",
                            ),
                            Text(
                              "Address: ${farmerData?["user"]["address"] ?? ""}",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Farm Details Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Farm Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _openUpdateFarm,
                          child: const Text("Update Farm"),
                        ),
                      ],
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (farmerData?["farmPhoto"] != null)
                              Image.network(
                                "$baseUrl${farmerData?["farmPhoto"] as String}",
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            const SizedBox(height: 16),
                            Text("Farm Name: ${farmerData?["farmName"] ?? ""}"),
                            Text("Location: ${farmerData?["location"] ?? ""}"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
