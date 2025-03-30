import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cow_and_crop/constants.dart';

class AddToCartDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  const AddToCartDialog({Key? key, required this.product}) : super(key: key);

  @override
  _AddToCartDialogState createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<AddToCartDialog> {
  final _formKey = GlobalKey<FormState>();
  int _selectedQuantity = 1; // default quantity is 1
  bool _isProcessing = false;
  final String baseUrl = BASE_URL;
  Future<void> _placeCartOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });
      try {
        // Retrieve user id from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString("userId");
        if (userId == null || userId.isEmpty) {
          setState(() {
            _isProcessing = false;
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

        // Build order payload with a single product
        Map<String, dynamic> payload = {
          "user": userId,
          "products": [
            {"product": widget.product["_id"], "quantity": _selectedQuantity},
          ],
          "totalAmount": totalAmount,
        };

        final Uri uri = Uri.parse("${baseUrl}api/cart/");
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
                  title: const Text("Added to Cart"),
                  content: const Text("Product added to cart successfully."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        } else {
          setState(() {});
        }
      } catch (e) {
        setState(() {});
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the product's "productQuantity" field as the unit label (e.g., "1 kg")
    String productUnit = widget.product["productQuantity"] ?? "";
    return AlertDialog(
      title: Text("Add to Cart: ${widget.product["productName"] ?? ""}"),
      content: Form(
        key: _formKey,
        child: Row(
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
            Text(productUnit),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _placeCartOrder,
          child:
              _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text("Add to cart"),
        ),
      ],
    );
  }
}
