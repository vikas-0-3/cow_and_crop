import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cow_and_crop/constants.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({Key? key}) : super(key: key);

  @override
  _AdminProductsPageState createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final String baseUrl = BASE_URL;
  late Future<List<dynamic>> futureProducts;

  // Filter state variables.
  String _selectedCategory = "All";
  String _selectedFarmer = "All";

  // Dropdown options.
  List<String> _categoryOptions = ["All"];
  List<String> _farmerOptions = ["All"];

  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
  }

  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(
      Uri.parse("${baseUrl}api/products/allproducts"),
    );
    if (response.statusCode == 200) {
      List<dynamic> products = jsonDecode(response.body) as List<dynamic>;

      // Build unique category options.
      Set<String> categorySet = {};
      // Build unique farmer options using the farmer name.
      Set<String> farmerSet = {};
      for (var product in products) {
        // Category
        String category = product["category"]?.toString() ?? "";
        if (category.isNotEmpty) {
          categorySet.add(category);
        }
        // Farmer: using product["farmer"]["name"]
        if (product["farmer"] != null && product["farmer"]["name"] != null) {
          String farmerName = product["farmer"]["name"].toString();
          if (farmerName.isNotEmpty) {
            farmerSet.add(farmerName);
          }
        }
      }
      // Update the dropdown options.
      setState(() {
        _categoryOptions = ["All", ...categorySet];
        _farmerOptions = ["All", ...farmerSet];
      });
      return products;
    } else {
      throw Exception("Failed to load products");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Products"),
        backgroundColor: const Color(0xFFFFA4D3),
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
            List<dynamic> products = snapshot.data!;
            // Apply category filter.
            if (_selectedCategory != "All") {
              products =
                  products.where((p) {
                    String category = p["category"]?.toString() ?? "";
                    return category.toLowerCase() ==
                        _selectedCategory.toLowerCase();
                  }).toList();
            }
            // Apply farmer filter.
            if (_selectedFarmer != "All") {
              products =
                  products.where((p) {
                    if (p["farmer"] != null && p["farmer"]["name"] != null) {
                      String farmerName = p["farmer"]["name"].toString();
                      return farmerName.toLowerCase() ==
                          _selectedFarmer.toLowerCase();
                    }
                    return false;
                  }).toList();
            }
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedFarmer,
                          items:
                              _farmerOptions.map((farmer) {
                                return DropdownMenuItem<String>(
                                  value: farmer,
                                  child: Text(farmer),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFarmer = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Products list.
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final String imageUrl =
                          baseUrl +
                          (product["productImage"] as String).replaceAll(
                            "\\",
                            "/",
                          );
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                          title: Text(product["productName"] ?? ""),
                          subtitle: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: "MRP: ₹${product["mrp"]} ",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                TextSpan(
                                  text: "Selling: ₹${product["sellingPrice"]}",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: "\nCategory: ${product["category"]}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                TextSpan(
                                  text:
                                      "\nFarmer: ${product["farmer"]?["name"] ?? ""}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
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
