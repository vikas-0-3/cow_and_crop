import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'add_farmer_dialog.dart';
import 'package:cow_and_crop/constants.dart';

class FarmersPageContent extends StatefulWidget {
  const FarmersPageContent({Key? key}) : super(key: key);

  @override
  _FarmersPageContentState createState() => _FarmersPageContentState();
}

class _FarmersPageContentState extends State<FarmersPageContent> {
  // Base URL to prepend to farmPhoto path
  final String baseUrl = BASE_URL;

  late Future<List<dynamic>> futureFarms;

  @override
  void initState() {
    super.initState();
    futureFarms = fetchFarms();
  }

  // Fetch farms from the API
  Future<List<dynamic>> fetchFarms() async {
    final response = await http.get(Uri.parse("${baseUrl}api/farmers/farms"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception("Failed to load farms");
    }
  }

  // Refresh the farms list by refetching from API
  void _refreshFarms() {
    setState(() {
      futureFarms = fetchFarms();
    });
  }

  // Function to delete a farm
  Future<void> _deleteFarm(String userId, String farmerId) async {
    final res = await http.delete(Uri.parse("${baseUrl}api/farmers/$farmerId"));
    final response = await http.delete(
      Uri.parse("${baseUrl}api/users/$userId"),
    );
    if (res.statusCode == 200 ||
        response.statusCode == 200 ||
        response.statusCode == 204) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Farm deleted")));
      _refreshFarms();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete farm: ${response.statusCode}"),
        ),
      );
    }
  }

  // Show confirmation dialog before deleting a farm
  void _confirmDelete(String userId, String farmerId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text("Are you sure you want to delete this farm?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Cancel
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  _deleteFarm(userId, farmerId);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // Open the Add Farmer modal dialog
  void _openAddFarmerModal() {
    showDialog(
      context: context,
      builder:
          (context) => AddFarmerDialog(
            onSubmit: (Map<String, dynamic> farmerData) {
              // In a real app, call your add-farmer API here.
              Navigator.of(context).pop();
              _refreshFarms();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmers"),
        backgroundColor: Color(0xFFFFA4D3),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureFarms,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No farms found"));
          } else {
            final farms = snapshot.data!;
            return ListView.builder(
              itemCount: farms.length,
              itemBuilder: (context, index) {
                final farm = farms[index];
                // Build the full image URL, converting backslashes to forward slashes
                final String imageUrl =
                    baseUrl +
                    (farm["farmPhoto"] as String).replaceAll("\\", "/");
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  title: Text(farm["farmName"] ?? ""),
                  subtitle: Text(farm["location"] ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(farm["user"], farm["_id"]);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFarmerModal,
        backgroundColor: const Color(0xFFFF5E99),
        child: const Icon(Icons.add),
      ),
    );
  }
}
