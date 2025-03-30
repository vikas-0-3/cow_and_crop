import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'add_product_dialog.dart';
import 'update_product_dialog.dart';
import 'package:cow_and_crop/constants.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final String baseUrl = BASE_URL; // adjust if needed
  String? farmerId;
  // Initialize futureProducts with an empty list to avoid late initialization errors.
  late Future<List<dynamic>> futureProducts = Future.value([]);

  // Dropdown filter for product status
  String _filterStatus = "all";
  final List<String> _filterOptions = ["all", "active", "inactive"];

  @override
  void initState() {
    super.initState();
    _loadFarmerIdAndFetchProducts();
  }

  Future<void> _loadFarmerIdAndFetchProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    farmerId = prefs.getString("userId");
    setState(() {
      if (farmerId != null && farmerId!.isNotEmpty) {
        futureProducts = fetchProducts(farmerId!);
      } else {
        futureProducts = Future.value([]);
      }
    });
  }

  Future<List<dynamic>> fetchProducts(String farmerId) async {
    final response = await http.get(
      Uri.parse("${baseUrl}api/products/farmer/$farmerId"),
    );
    if (response.statusCode == 200) {
      List<dynamic> products = jsonDecode(response.body) as List<dynamic>;
      // Filter products based on _filterStatus if not "all"
      if (_filterStatus != "all") {
        products =
            products.where((p) {
              final status = p["status"]?.toString().toLowerCase() ?? "";
              return status == _filterStatus;
            }).toList();
      }
      return products;
    } else {
      throw Exception("Failed to load products");
    }
  }

  void _refreshProducts() {
    if (farmerId != null) {
      setState(() {
        futureProducts = fetchProducts(farmerId!);
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final response = await http.delete(
      Uri.parse("${baseUrl}api/products/$productId"),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product deleted")));
      _refreshProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete product: ${response.statusCode}"),
        ),
      );
    }
  }

  void _confirmDelete(String productId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to delete this product?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Cancel
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  _deleteProduct(productId);
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

  void _openUpdateProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder:
          (context) => UpdateProductDialog(
            product: product,
            onUpdate: () {
              Navigator.of(context).pop(); // close update dialog
              _refreshProducts();
            },
          ),
    );
  }

  void _openAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddProductDialog(),
    ).then((_) {
      _refreshProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        backgroundColor: Colors.amber,
        actions: [
          // Filter dropdown in the AppBar on the right side
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                icon: const Icon(Icons.filter_list, color: Colors.black),
                dropdownColor: Colors.amber,
                items:
                    _filterOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          option.toUpperCase(),
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                    if (farmerId != null && farmerId!.isNotEmpty) {
                      futureProducts = fetchProducts(farmerId!);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products found"));
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final String imageUrl =
                    baseUrl +
                    (product["productImage"] as String).replaceAll("\\", "/");
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  title: Text(product["productName"] ?? ""),
                  subtitle: Text(
                    "Qty: ${product["productQuantity"]}\nMRP: ${product["mrp"]}  Selling: ${product["sellingPrice"]}\nCategory: ${product["category"]}\nStatus: ${product["status"]}",
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(product["_id"]);
                    },
                  ),
                  onTap: () {
                    _openUpdateProductDialog(product);
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProductDialog,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add),
      ),
    );
  }
}
