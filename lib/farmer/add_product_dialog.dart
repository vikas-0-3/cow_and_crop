import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cow_and_crop/constants.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({Key? key}) : super(key: key);

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = BASE_URL;
  // Controllers for product fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  String? _selectedCategory;
  final List<String> _categories = ["Fruits", "Vegetables", "Dairy"];

  // For product image
  String? _productImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProductImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _productImagePath = pickedFile.path;
      });
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _mrpController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Retrieve farmerId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? farmerId = prefs.getString("userId");
      if (farmerId == null || farmerId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      try {
        // Build the multipart request
        final Uri uri = Uri.parse("${baseUrl}api/products");
        var request = http.MultipartRequest("POST", uri);

        // Add form fields
        request.fields["productName"] = _productNameController.text.trim();
        request.fields["category"] = _selectedCategory ?? "";
        request.fields["productQuantity"] = _quantityController.text.trim();
        request.fields["mrp"] = _mrpController.text.trim();
        request.fields["sellingPrice"] = _sellingPriceController.text.trim();
        request.fields["farmerId"] = farmerId;

        // Attach product image if one is selected
        if (_productImagePath != null && _productImagePath!.isNotEmpty) {
          File productFile = File(_productImagePath!);
          request.files.add(
            await http.MultipartFile.fromPath(
              "productImage",
              productFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }

        print("------ request ---------");
        print(request);

        // Send the request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Show success alert and close the dialog
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("Success"),
                  content: const Text("Product added successfully"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close success dialog
                        Navigator.of(context).pop(); // close AddProductDialog
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to add product: ${response.statusCode}"),
            ),
          );
          print(response);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Product"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Product Image upload button (placed on top)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickProductImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Upload Product Image"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              if (_productImagePath != null) ...[
                const SizedBox(height: 8),
                Text("Selected: ${_productImagePath!.split('/').last}"),
              ],
              const SizedBox(height: 8),
              // Product Name
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              // Product Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: "Product Quantity",
                ),
                keyboardType: TextInputType.text,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              // MRP
              TextFormField(
                controller: _mrpController,
                decoration: const InputDecoration(labelText: "MRP"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              // Selling Price
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(labelText: "Selling Price"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              // Category dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Category"),
                items:
                    _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? "Select a category"
                            : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancel button
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: _submit, child: const Text("Submit")),
      ],
    );
  }
}
