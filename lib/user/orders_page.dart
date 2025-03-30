import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cow_and_crop/constants.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final String baseUrl = BASE_URL; // Adjust if needed
  String? userId;
  late Future<List<dynamic>> futureOrders = Future.value([]);

  // Order filter variable and options
  String _selectedOrderFilter = "All";
  final List<String> _orderFilterOptions = [
    "All",
    "Pending",
    "Delivered",
    "Cancelled",
    "Rejected",
    "Accepted",
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("userId");
    if (userId == null || userId!.isEmpty) {
      setState(() {
        futureOrders = Future.value([]);
      });
    } else {
      setState(() {
        futureOrders = fetchOrders(userId!);
      });
    }
  }

  Future<List<dynamic>> fetchOrders(String userId) async {
    final response = await http.get(Uri.parse("${baseUrl}api/orders/$userId"));
    if (response.statusCode == 200) {
      List<dynamic> orders = jsonDecode(response.body) as List<dynamic>;
      if (_selectedOrderFilter != "All") {
        orders =
            orders.where((order) {
              final status = order["status"]?.toString().toLowerCase() ?? "";
              return status == _selectedOrderFilter.toLowerCase();
            }).toList();
      }
      orders.sort(
        (a, b) => DateTime.parse(
          b["createdAt"],
        ).compareTo(DateTime.parse(a["createdAt"])),
      );
      return orders;
    } else {
      throw Exception("Failed to load orders");
    }
  }

  void _refreshOrders() {
    if (userId != null) {
      setState(() {
        futureOrders = fetchOrders(userId!);
      });
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final Uri uri = Uri.parse("${baseUrl}api/orders/$orderId");
    final response = await http.put(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": "cancelled"}),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order cancelled")));
      _refreshOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to cancel order: ${response.statusCode}"),
        ),
      );
    }
  }

  void _confirmCancelOrder(String orderId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Cancel Order"),
            content: const Text("Are you sure you want to cancel this order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelOrder(orderId);
                },
                child: const Text("Yes", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Color getOrderBorderColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.amber;
      case "delivered":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "accepted":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Static charges:
    const int deliveryCharge = 50;
    const int platformFee = 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        backgroundColor: Colors.green[200],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedOrderFilter = value;
                _refreshOrders();
              });
            },
            itemBuilder: (context) {
              return _orderFilterOptions.map((option) {
                return PopupMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList();
            },
          ),
        ],
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
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                // Calculate total items and build product details line by line.
                int totalItems = 0;
                List<String> productLines = [];
                for (var item in order["products"]) {
                  int qty = int.tryParse(item["quantity"].toString()) ?? 0;
                  totalItems += qty;
                  String prodName = item["product"]["productName"] ?? "";
                  String unit = item["product"]["productQuantity"] ?? "";
                  int price = item["product"]["sellingPrice"] ?? "";
                  int finalPrice = qty * price;
                  productLines.add(
                    "$prodName ($price) - $qty x $unit = $finalPrice",
                  );
                }
                String productsText = productLines.join("\n");

                // Get order total amount from API.
                double totalAmount =
                    double.tryParse(order["totalAmount"].toString()) ?? 0.0;
                double newPayable = totalAmount + deliveryCharge + platformFee;

                // Order status and border color
                String orderStatus = order["status"] ?? "";
                Color borderColor = getOrderBorderColor(orderStatus);

                return Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Total Items and Order Status with Cancel button if pending
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Items: $totalItems",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Row(
                                children: [
                                  Text(
                                    orderStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: borderColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (orderStatus.toLowerCase() == "pending")
                                    TextButton(
                                      onPressed: () {
                                        _confirmCancelOrder(order["_id"]);
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: const Size(0, 24),
                                      ),
                                      child: const Text("Cancel"),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Order Date: ${DateFormat('dd MM yyyy, HH:mm').format(DateTime.parse(order['createdAt']))}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          // List of products line by line
                          Text(
                            productsText,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Divider(height: 20, thickness: 1),
                          // Order totals and charges
                          Text(
                            "Total Amount: ₹$totalAmount",
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
                          const Text(
                            "Platform Fee: Rs 10",
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "New Payable: ₹$newPayable",
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
              },
            );
          }
        },
      ),
    );
  }
}
