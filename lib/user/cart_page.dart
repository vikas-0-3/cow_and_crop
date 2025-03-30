import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cow_and_crop/constants.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final String baseUrl = BASE_URL;
  late Future<Map<String, dynamic>?> futureCart;

  @override
  void initState() {
    super.initState();
    futureCart = fetchCart();
  }

  Future<Map<String, dynamic>?> fetchCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");
    if (userId == null || userId.isEmpty) return null;
    final Uri uri = Uri.parse("${baseUrl}api/cart/$userId");
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> cartList = jsonDecode(response.body);
      if (cartList.isNotEmpty) {
        return cartList[0] as Map<String, dynamic>;
      }
    }
    return null;
  }

  void _reloadCart() {
    setState(() {
      futureCart = fetchCart();
    });
  }

  /// Update a cart item quantity using the new endpoint.
  Future<void> _updateCartItem(
    String cartId,
    String productId,
    int newQuantity,
  ) async {
    final Uri uri = Uri.parse("${baseUrl}api/cart/$cartId/products/$productId");
    final response = await http.put(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"quantity": newQuantity}),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      _reloadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update product: ${response.statusCode}"),
        ),
      );
    }
  }

  /// Remove a cart item using the new endpoint.
  Future<void> _removeCartItem(String cartId, String productId) async {
    final Uri uri = Uri.parse("${baseUrl}api/cart/$cartId/products/$productId");
    final response = await http.delete(uri);
    if (response.statusCode == 200 || response.statusCode == 204) {
      _reloadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to remove product: ${response.statusCode}"),
        ),
      );
    }
  }

  /// Show a dialog to update quantity for a given cart item.
  void _showUpdateQuantityDialog(
    Map<String, dynamic> cart,
    Map<String, dynamic> cartItem,
  ) {
    int currentQuantity = int.tryParse(cartItem["quantity"].toString()) ?? 1;
    int newQuantity = currentQuantity;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Update Quantity for ${cartItem["product"]["productName"]}",
              ),
              content: Row(
                children: [
                  DropdownButton<int>(
                    value: newQuantity,
                    items:
                        List.generate(10, (index) => index + 1)
                            .map(
                              (val) => DropdownMenuItem<int>(
                                value: val,
                                child: Text(val.toString()),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        newQuantity = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(cartItem["product"]["productQuantity"] ?? ""),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateCartItem(cart["_id"], cartItem["_id"], newQuantity);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show a confirmation dialog to remove a cart item.
  void _confirmRemoveCartItem(
    Map<String, dynamic> cart,
    Map<String, dynamic> cartItem,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Remove Product"),
            content: const Text(
              "Are you sure you want to remove this product from the cart?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _removeCartItem(cart["_id"], cartItem["_id"]);
                },
                child: const Text("Yes", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  /// Build a cart item card with update and remove options.
  Widget _buildCartItem(Map<String, dynamic> cart, Map<String, dynamic> item) {
    final product = item["product"];
    final String imageUrl =
        baseUrl + (product["productImage"] as String).replaceAll("\\", "/");
    return GestureDetector(
      onTap: () => _showUpdateQuantityDialog(cart, item),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Stack(
          children: [
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(product["productName"] ?? ""),
              subtitle: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(
                    context,
                  ).style.copyWith(fontSize: 14),
                  children: [
                    TextSpan(
                      text:
                          "Quantity: ${item["quantity"]} x ${product["productQuantity"]}\n",
                    ),
                    TextSpan(
                      text: "MRP: ₹${product["mrp"]}  ",
                      style: const TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    TextSpan(
                      text: "₹${product["sellingPrice"]}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: TextButton(
                onPressed: () => _confirmRemoveCartItem(cart, item),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 0),
                  padding: const EdgeInsets.all(4),
                ),
                child: const Text(
                  "Remove",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Checkout: confirmation then create order and delete cart.
  Future<void> _checkoutCart(Map<String, dynamic> cart) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Checkout"),
            content: const Text("Are you sure you want to place your order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");
    if (userId == null || userId.isEmpty) return;

    // Build order payload from cart data.
    Map<String, dynamic> orderPayload = {
      "user": userId,
      "products":
          (cart["products"] as List).map((item) {
            return {
              "product": item["product"]["_id"],
              "quantity": item["quantity"],
            };
          }).toList(),
      "totalAmount": cart["totalAmount"],
    };

    final Uri orderUri = Uri.parse("${baseUrl}api/orders/");
    final orderResponse = await http.post(
      orderUri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(orderPayload),
    );

    if (orderResponse.statusCode == 200 || orderResponse.statusCode == 201) {
      final String cartId = cart["_id"];
      final Uri deleteUri = Uri.parse("${baseUrl}api/cart/$cartId");
      final deleteResponse = await http.delete(deleteUri);
      if (deleteResponse.statusCode == 200 ||
          deleteResponse.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully")),
        );
        setState(() {
          futureCart = Future.value(null);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Order placed but failed to clear cart: ${deleteResponse.statusCode}",
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to place order: ${orderResponse.statusCode}"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        backgroundColor: Colors.green[200],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: futureCart,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.data == null) {
            return const Center(child: Text("Your cart is empty"));
          } else {
            final cart = snapshot.data!;
            final List<dynamic> items = cart["products"] ?? [];
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(cart, items[index]);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Total Amount: ₹${cart["totalAmount"]}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _checkoutCart(cart);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[200],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Checkout",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
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
