import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cow_and_crop/constants.dart';

class UpdateProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onUpdate;
  const UpdateProductDialog({
    Key? key,
    required this.product,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _UpdateProductDialogState createState() => _UpdateProductDialogState();
}

class _UpdateProductDialogState extends State<UpdateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = BASE_URL;

  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _mrpController;
  late TextEditingController _sellingPriceController;

  String? _selectedCategory;
  final List<String> _categories = ["Fruits", "Vegetables", "Dairy"];

  String? _selectedStatus;
  final List<String> _statuses = ["active", "inactive"];

  String? _productImagePath; // new image file path, if selected
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.product["productName"],
    );
    _quantityController = TextEditingController(
      text: widget.product["productQuantity"].toString(),
    );
    _mrpController = TextEditingController(
      text: widget.product["mrp"].toString(),
    );
    _sellingPriceController = TextEditingController(
      text: widget.product["sellingPrice"].toString(),
    );
    _selectedCategory = widget.product["category"];
    _selectedStatus = widget.product["status"] ?? "active";
    _productImagePath = ""; // Initially no new image selected.
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _mrpController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickProductImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _productImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? farmerId = prefs.getString("userId");
      if (farmerId == null || farmerId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      try {
        final productId = widget.product["_id"];
        final Uri uri = Uri.parse("${baseUrl}api/products/$productId");
        var request = http.MultipartRequest("PUT", uri);

        // Add updated fields
        request.fields["productName"] = _productNameController.text.trim();
        request.fields["category"] = _selectedCategory ?? "";
        request.fields["productQuantity"] = _quantityController.text.trim();
        request.fields["mrp"] = _mrpController.text.trim();
        request.fields["sellingPrice"] = _sellingPriceController.text.trim();
        request.fields["status"] = _selectedStatus ?? "active";
        request.fields["farmerId"] = farmerId;

        // Attach product image if a new one was selected
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

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200 || response.statusCode == 201) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text("Success"),
                  content: const Text("Product updated successfully"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close success dialog
                        // Navigator.of(context).pop(); // close update dialog
                        widget.onUpdate();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update product: ${response.statusCode}"),
            ),
          );
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
      title: const Text("Update Product"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Button to change product image
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickProductImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Change Product Image"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              if (_productImagePath != null &&
                  _productImagePath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text("Selected: ${_productImagePath!.split('/').last}"),
              ],
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
                keyboardType: TextInputType.number,
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
              // Status dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Status"),
                items:
                    _statuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                value: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? "Select a status"
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
        ElevatedButton(onPressed: _submitUpdate, child: const Text("Submit")),
      ],
    );
  }
}
