import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cow_and_crop/constants.dart';

class FarmerHomeContent extends StatefulWidget {
  const FarmerHomeContent({Key? key}) : super(key: key);

  @override
  _FarmerHomeContentState createState() => _FarmerHomeContentState();
}

class _FarmerHomeContentState extends State<FarmerHomeContent> {
  final String baseUrl = BASE_URL;
  late Future<Map<String, int>> productCountsFuture;

  @override
  void initState() {
    super.initState();
    productCountsFuture = fetchProductCounts();
  }

  Future<Map<String, int>> fetchProductCounts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? farmerId = prefs.getString("userId");
    if (farmerId == null || farmerId.isEmpty) {
      throw Exception("Farmer not logged in");
    }

    final response = await http.get(
      Uri.parse("${baseUrl}api/products/farmer/$farmerId"),
    );
    if (response.statusCode == 200) {
      final List<dynamic> products = jsonDecode(response.body) as List<dynamic>;
      final int total = products.length;
      final int active =
          products.where((p) {
            final status = p["status"];
            return status != null &&
                status.toString().toLowerCase() == "active";
          }).length;
      final int inactive =
          products.where((p) {
            final status = p["status"];
            return status != null &&
                status.toString().toLowerCase() == "inactive";
          }).length;
      return {"total": total, "active": active, "inactive": inactive};
    } else {
      throw Exception("Failed to load products");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: productCountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData) {
          return const Center(child: Text("No data found"));
        } else {
          final counts = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Card: Total Products
                Card(
                  color: Colors.orange,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.list, size: 40, color: Colors.white),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Products : ${counts["total"]}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Row with two cards: Active and Inactive
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.green,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 40,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Active",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "${counts["active"]}",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.red,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cancel,
                                size: 40,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Inactive",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "${counts["inactive"]}",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
