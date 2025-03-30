import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cow_and_crop/constants.dart';
import 'package:cow_and_crop/user/BuyNowDialog.dart';
import 'package:cow_and_crop/user/add_to_cart_dialog.dart';

class HomeContent extends StatefulWidget {
  final VoidCallback? onViewAll;
  const HomeContent({Key? key, this.onViewAll}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final String baseUrl = BASE_URL;
  late Future<List<dynamic>> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = fetchAllProducts();
  }

  Future<List<dynamic>> fetchAllProducts() async {
    final response = await http.get(Uri.parse("${baseUrl}api/products/"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception("Failed to load products");
    }
  }

  // Select up to 5 random products for a given category
  List<dynamic> selectRandomProducts(List<dynamic> products, String category) {
    List<dynamic> filtered =
        products.where((product) {
          final cat = (product["category"] as String?)?.toLowerCase() ?? "";
          return cat == category.toLowerCase();
        }).toList();
    filtered.shuffle(Random());
    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }

  // Product card widget
  Widget productCard(Map<String, dynamic> product) {
    final String imageUrl =
        baseUrl + (product["productImage"] as String).replaceAll("\\", "/");
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 4),
              // Product name with unit
              Text(
                "${product["productName"]} (${product["productQuantity"]})",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Price details
              Row(
                children: [
                  Text(
                    "₹${product["mrp"]}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "₹${product["sellingPrice"]}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // "Add to Cart" button (opens respective popup)
              ElevatedButton.icon(
                onPressed: () => _addToCart(product),
                icon: const Icon(Icons.add_shopping_cart, size: 14),
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

              // "Buy Now" button (opens respective popup)
              ElevatedButton.icon(
                onPressed: () => _buyNow(product),
                icon: const Icon(Icons.shopping_bag, size: 14),
                label: const Text("Buy Now", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Carousel widget for a category
  Widget categoryCarousel(String category, List<dynamic> products) {
    List<dynamic> selectedProducts = selectRandomProducts(products, category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            category,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        // Horizontal carousel
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedProducts.length,
            itemBuilder: (context, index) {
              final product = selectedProducts[index];
              return productCard(product);
            },
          ),
        ),
        // "View All" button calls the callback provided by the parent.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed:
                widget.onViewAll, // This callback is provided by the parent.
            child: const Text("View All"),
          ),
        ),
      ],
    );
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
    return FutureBuilder<List<dynamic>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No products found"));
        } else {
          final allProducts = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                categoryCarousel("Vegetables", allProducts),
                categoryCarousel("Fruits", allProducts),
                categoryCarousel("Dairy", allProducts),
              ],
            ),
          );
        }
      },
    );
  }
}
