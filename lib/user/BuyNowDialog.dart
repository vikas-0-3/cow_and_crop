import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cow_and_crop/constants.dart';

class BuyNowDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  const BuyNowDialog({Key? key, required this.product}) : super(key: key);

  @override
  _BuyNowDialogState createState() => _BuyNowDialogState();
}

class _BuyNowDialogState extends State<BuyNowDialog> {
  final _formKey = GlobalKey<FormState>();
  int _selectedQuantity = 1; // default quantity is 1
  bool _isOrdering = false;
  String? _error;
  final String baseUrl = BASE_URL;
  Future<void> _placeOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isOrdering = true;
        _error = null;
      });
      try {
        // Retrieve user id from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString("userId");
        if (userId == null || userId.isEmpty) {
          setState(() {
            _error = "User not logged in";
            _isOrdering = false;
          });
          return;
        }
        // Parse selling price and compute total amount.
        double sellingPrice;
        if (widget.product["sellingPrice"] is int) {
          sellingPrice = (widget.product["sellingPrice"] as int).toDouble();
        } else if (widget.product["sellingPrice"] is double) {
          sellingPrice = widget.product["sellingPrice"];
        } else {
          sellingPrice =
              double.tryParse(widget.product["sellingPrice"].toString()) ?? 0.0;
        }
        double totalAmount = sellingPrice * _selectedQuantity;

        Map<String, dynamic> payload = {
          "user": userId,
          "products": [
            {"product": widget.product["_id"], "quantity": _selectedQuantity},
          ],
          "totalAmount": totalAmount,
        };

        final Uri uri = Uri.parse("${baseUrl}api/orders/");
        final response = await http.post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("Order Placed"),
                  content: const Text(
                    "Your order has been placed successfully.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close success dialog
                        Navigator.of(context).pop(); // close BuyNowDialog
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        } else {
          setState(() {
            _error = "Failed to place order: ${response.statusCode}";
          });
        }
      } catch (e) {
        setState(() {
          _error = "Error: $e";
        });
      } finally {
        setState(() {
          _isOrdering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the product's "productQuantity" field as the unit label (e.g., "1 kg")
    String productUnit = widget.product["productQuantity"] ?? "";
    return AlertDialog(
      title: Text("Buy Now: ${widget.product["productName"] ?? ""}"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Quantity:"),
            Row(
              children: [
                DropdownButton<int>(
                  value: _selectedQuantity,
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
                      _selectedQuantity = value!;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(" * $productUnit"),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isOrdering ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isOrdering ? null : _placeOrder,
          child:
              _isOrdering
                  ? const CircularProgressIndicator()
                  : const Text("Order"),
        ),
      ],
    );
  }
}
