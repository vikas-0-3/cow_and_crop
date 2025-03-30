import 'dart:convert';
import 'package:cow_and_crop/user/BuyNowDialog.dart';
import 'package:cow_and_crop/user/add_to_cart_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cow_and_crop/constants.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final String baseUrl = BASE_URL; // from constants.dart
  late Future<List<dynamic>> futureProducts;

  // Dropdown filter for product category
  String _selectedCategory = "All";
  final List<String> _categoryOptions = [
    "All",
    "Fruits",
    "Vegetables",
    "Dairy",
  ];

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse("${baseUrl}api/products/"));
    if (response.statusCode == 200) {
      List<dynamic> products = jsonDecode(response.body) as List<dynamic>;
      // Filter products by category if not "All"
      if (_selectedCategory != "All") {
        products =
            products.where((p) {
              final cat = (p["category"] as String?)?.toLowerCase() ?? "";
              return cat == _selectedCategory.toLowerCase();
            }).toList();
      }
      return products;
    } else {
      throw Exception("Failed to load products");
    }
  }

  void _refreshProducts() {
    setState(() {
      futureProducts = fetchProducts();
    });
  }

  // Open AddToCart dialog.
  void _addToCart(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AddToCartDialog(product: product),
    );
  }

  // Open BuyNow dialog.
  void _buyNow(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => BuyNowDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        backgroundColor: Colors.green[200],
        actions: [
          // Filter dropdown in AppBar.
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                icon: const Icon(Icons.filter_list, color: Colors.black),
                dropdownColor: Colors.green[200],
                items:
                    _categoryOptions.map((option) {
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
                    _selectedCategory = value!;
                    _refreshProducts();
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
            return MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
              padding: const EdgeInsets.all(8.0),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final String imageUrl =
                    baseUrl +
                    (product["productImage"] as String).replaceAll("\\", "/");
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Product Name. This will now allow for dynamic height.
                        Text(
                          "${product["productName"]} (${product["productQuantity"]})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Price details: MRP (strikethrough) and Selling Price.
                        Row(
                          children: [
                            Text(
                              "₹${product["mrp"]}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹${product["sellingPrice"]}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // "Add to Cart" Button.
                        ElevatedButton.icon(
                          onPressed: () => _addToCart(product),
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text(
                            "Add to Cart",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // "Buy Now" Button.
                        ElevatedButton.icon(
                          onPressed: () => _buyNow(product),
                          icon: const Icon(Icons.shopping_bag, size: 16),
                          label: const Text(
                            "Buy Now",
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 30),
                          ),
                        ),
                      ],
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
