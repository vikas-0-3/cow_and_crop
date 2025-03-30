import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cow_and_crop/constants.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final String baseUrl = BASE_URL;
  late Future<List<dynamic>> futureOrders;

  // Filters state.
  String _selectedStatus = "All";
  String _selectedCategory = "All";
  final List<String> _statusOptions = [
    "All",
    "pending",
    "cancelled",
    "delivered",
    "accepted",
  ];
  List<String> _categoryOptions = ["All"];

  @override
  void initState() {
    super.initState();
    futureOrders = fetchOrders();
  }

  Future<List<dynamic>> fetchOrders() async {
    final response = await http.get(Uri.parse("${baseUrl}api/orders/"));

    if (response.statusCode == 200) {
      List<dynamic> orders = jsonDecode(response.body) as List<dynamic>;

      // Build unique categories from orders' products.
      Set<String> categorySet = {};
      for (var order in orders) {
        if (order["products"] != null && order["products"] is List) {
          for (var item in order["products"]) {
            String cat = item["product"]["category"]?.toString() ?? "";
            if (cat.isNotEmpty) {
              categorySet.add(cat);
            }
          }
        }
      }

      // Update category options in state.
      setState(() {
        _categoryOptions = ["All", ...categorySet];
      });

      // Reverse the list so that latest is at the top.
      return orders.reversed.toList();
    } else {
      throw Exception("Failed to load orders");
    }
  }

  List<dynamic> _filterOrders(List<dynamic> orders) {
    // Filter orders by status if not "All"
    if (_selectedStatus != "All") {
      orders =
          orders.where((order) {
            String status = order["status"]?.toString().toLowerCase() ?? "";
            return status == _selectedStatus.toLowerCase();
          }).toList();
    }
    // Filter orders by category: include order if at least one product matches.
    if (_selectedCategory != "All") {
      orders =
          orders.where((order) {
            if (order["products"] != null && order["products"] is List) {
              for (var item in order["products"]) {
                String cat =
                    item["product"]["category"]?.toString().toLowerCase() ?? "";
                if (cat == _selectedCategory.toLowerCase()) {
                  return true;
                }
              }
            }
            return false;
          }).toList();
    }
    return orders;
  }

  // Return border color based on order status.
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

  // Accept order by updating status via API.
  Future<void> _acceptOrder(String orderId) async {
    final Uri uri = Uri.parse("${baseUrl}api/orders/$orderId");
    final response = await http.put(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": "accepted"}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order accepted")));
      setState(() {
        futureOrders = fetchOrders();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to accept order: ${response.statusCode}"),
        ),
      );
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Format order date.
    String orderDate = "";
    try {
      DateTime dt = DateTime.parse(order["createdAt"]);
      orderDate = DateFormat('dd MM yyyy, HH:mm').format(dt);
    } catch (e) {
      orderDate = order["createdAt"].toString();
    }

    // Build list of product details.
    List<Widget> productWidgets = [];
    if (order["products"] != null && order["products"] is List) {
      for (var item in order["products"]) {
        String prodName = item["product"]["productName"] ?? "";
        int qty = int.tryParse(item["quantity"].toString()) ?? 0;
        String unit = item["product"]["productQuantity"] ?? "";
        int price = item["product"]["sellingPrice"] ?? "";
        int finalPrice = qty * price;
        productWidgets.add(
          Text(
            "$prodName ($price) - $qty x $unit = $finalPrice",
            style: const TextStyle(fontSize: 14),
          ),
        );
      }
    }

    Color borderColor = getOrderBorderColor(order["status"] ?? "");

    // Card content.
    Widget cardContent = Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order ID: ${order["_id"]}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Status: ${order["status"]}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "Order Date: $orderDate",
                style: const TextStyle(fontSize: 14),
              ),
              const Divider(),
              ...productWidgets,
              const Divider(),
              Text(
                "Total Amount: ₹${order["totalAmount"]}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Delivery Charge: Rs 50",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text("Platform Fee: Rs 10", style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                "New Payable: ₹${order["totalAmount"] + 60}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // If order is pending, wrap card in an InkWell to accept order on tap.
    if (order["status"].toString().toLowerCase() == "pending") {
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("Accept Order"),
                  content: const Text(
                    "Are you sure you want to accept this order?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _acceptOrder(order["_id"]);
                      },
                      child: const Text(
                        "Yes",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
          );
        },
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Orders"),
        backgroundColor: const Color(0xFFFFA4D3),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No orders found"));
          } else {
            List<dynamic> orders = snapshot.data!;
            orders = _filterOrders(orders);
            return Column(
              children: [
                // Filters UI.
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedStatus,
                          items:
                              _statusOptions.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCategory,
                          items:
                              _categoryOptions.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat,
                                  child: Text(cat),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Orders list.
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
