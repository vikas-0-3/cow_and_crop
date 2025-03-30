import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cow_and_crop/constants.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final String baseUrl = BASE_URL;
  late Future<Map<String, dynamic>> futureDashboardData;

  Future<Map<String, dynamic>> fetchDashboardData() async {
    // Fetch all products, orders, and users concurrently.
    final productsResponse = await http.get(
      Uri.parse("${baseUrl}api/products/allproducts"),
    );
    final ordersResponse = await http.get(Uri.parse("${baseUrl}api/orders/"));
    final usersResponse = await http.get(Uri.parse("${baseUrl}api/users/"));

    if (productsResponse.statusCode == 200 &&
        ordersResponse.statusCode == 200 &&
        usersResponse.statusCode == 200) {
      List<dynamic> products =
          jsonDecode(productsResponse.body) as List<dynamic>;
      List<dynamic> orders = jsonDecode(ordersResponse.body) as List<dynamic>;
      List<dynamic> users = jsonDecode(usersResponse.body) as List<dynamic>;

      return {"products": products, "orders": orders, "users": users};
    } else {
      throw Exception("Failed to load dashboard data");
    }
  }

  @override
  void initState() {
    super.initState();
    futureDashboardData = fetchDashboardData();
  }

  // Helper widget for category cards.
  Widget _buildCategoryCard(String category, int count, Color color) {
    return Card(
      color: color,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("$count", style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  // Helper widget for order status cards.
  Widget _buildOrderStatusCard(String status, int count, Color color) {
    return Card(
      color: color,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("$count", style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  // Helper widget for summary cards.
  Widget _buildSummaryCard(String title, Widget content, Color color) {
    return Card(
      color: color,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  // Get border color for orders (not used here, but could be used for individual order cards).
  Color getOrderBorderColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.yellow;
      case "cancelled":
        return Colors.red;
      case "delivered":
        return Colors.green;
      case "accepted":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: futureDashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          final data = snapshot.data!;
          final products = data["products"] as List<dynamic>;
          final orders = data["orders"] as List<dynamic>;
          final users = data["users"] as List<dynamic>;

          // Compute product counts.
          int totalProducts = products.length;
          int activeProducts =
              products
                  .where(
                    (p) => p["status"].toString().toLowerCase() == "active",
                  )
                  .length;
          int inactiveProducts = totalProducts - activeProducts;
          int fruitsCount =
              products
                  .where(
                    (p) => p["category"].toString().toLowerCase() == "fruits",
                  )
                  .length;
          int vegetablesCount =
              products
                  .where(
                    (p) =>
                        p["category"].toString().toLowerCase() == "vegetables",
                  )
                  .length;
          int dairyCount =
              products
                  .where(
                    (p) => p["category"].toString().toLowerCase() == "dairy",
                  )
                  .length;

          // Compute order counts.
          int totalOrders = orders.length;
          int pendingOrders =
              orders
                  .where(
                    (o) => o["status"].toString().toLowerCase() == "pending",
                  )
                  .length;
          int acceptedOrders =
              orders
                  .where(
                    (o) => o["status"].toString().toLowerCase() == "accepted",
                  )
                  .length;
          int cancelledOrders =
              orders
                  .where(
                    (o) => o["status"].toString().toLowerCase() == "cancelled",
                  )
                  .length;
          int deliveredOrders =
              orders
                  .where(
                    (o) => o["status"].toString().toLowerCase() == "delivered",
                  )
                  .length;

          // Compute user counts.
          int totalUsers = users.length - 1;
          int userCount =
              users
                  .where((u) => u["role"].toString().toLowerCase() == "user")
                  .length;
          int farmerCount =
              users
                  .where((u) => u["role"].toString().toLowerCase() == "farmer")
                  .length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Products Summary Card.
                  _buildSummaryCard(
                    "Products",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Products: $totalProducts",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  "Active",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text("$activeProducts"),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  "Inactive",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text("$inactiveProducts"),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Colors.lightBlue.shade100,
                  ),
                  const SizedBox(height: 16),
                  // Category Cards Row.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryCard(
                          "Fruits",
                          fruitsCount,
                          Colors.orange.shade100,
                        ),
                        _buildCategoryCard(
                          "Vegetables",
                          vegetablesCount,
                          Colors.green.shade100,
                        ),
                        _buildCategoryCard(
                          "Dairy",
                          dairyCount,
                          Colors.pink.shade100,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Orders Summary Card.
                  _buildSummaryCard(
                    "Orders",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Orders: $totalOrders",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildOrderStatusCard(
                                "Pending",
                                pendingOrders,
                                Colors.yellow.shade100,
                              ),
                              _buildOrderStatusCard(
                                "Accepted",
                                acceptedOrders,
                                Colors.blue.shade100,
                              ),
                              _buildOrderStatusCard(
                                "Cancelled",
                                cancelledOrders,
                                Colors.red.shade100,
                              ),
                              _buildOrderStatusCard(
                                "Delivered",
                                deliveredOrders,
                                Colors.green.shade100,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Colors.amber.shade100,
                  ),
                  const SizedBox(height: 16),
                  // Users Summary Card.
                  _buildSummaryCard(
                    "Users",
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Users: $totalUsers",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  "Users",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text('$userCount'),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  "Farmers",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text("$farmerCount"),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Colors.purple.shade100,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
