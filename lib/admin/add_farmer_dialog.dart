import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cow_and_crop/constants.dart';

class AddFarmerDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  const AddFarmerDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _AddFarmerDialogState createState() => _AddFarmerDialogState();
}

class _AddFarmerDialogState extends State<AddFarmerDialog> {
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = BASE_URL;
  // Controllers for user fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Controllers for farm fields
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmLocationController = TextEditingController();

  // For images, store file paths
  String? _profilePhoto;
  String? _farmPhoto;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfilePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profilePhoto = pickedFile.path;
      });
    }
  }

  Future<void> _pickFarmPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _farmPhoto = pickedFile.path;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _farmNameController.dispose();
    _farmLocationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // ----- API 1: Register user (farmer) -----
        final Uri uri1 = Uri.parse("${baseUrl}api/auth/register");
        var request1 = http.MultipartRequest("POST", uri1);

        // Add text fields for user registration
        request1.fields["name"] = _nameController.text.trim();
        request1.fields["age"] = _ageController.text.trim();
        request1.fields["gender"] = _genderController.text.trim();
        request1.fields["email"] = _emailController.text.trim();
        request1.fields["phone"] = _phoneController.text.trim();
        request1.fields["password"] = _passwordController.text.trim();
        request1.fields["address"] = _addressController.text.trim();
        request1.fields["role"] = "farmer";

        // Attach profilePhoto if selected
        if (_profilePhoto != null && _profilePhoto!.isNotEmpty) {
          File profileFile = File(_profilePhoto!);
          request1.files.add(
            await http.MultipartFile.fromPath(
              "profilePhoto",
              profileFile.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }

        // Send API 1 request
        var streamedResponse1 = await request1.send();
        var response1 = await http.Response.fromStream(streamedResponse1);
        if (response1.statusCode == 200 || response1.statusCode == 201) {
          var json1 = jsonDecode(response1.body);
          String userId =
              json1["userId"]; // Make sure your API returns this field

          // ----- API 2: Register farm -----
          final Uri uri2 = Uri.parse("${baseUrl}api/farmers");
          var request2 = http.MultipartRequest("POST", uri2);
          request2.fields["userId"] = userId;
          request2.fields["farmName"] = _farmNameController.text.trim();
          request2.fields["location"] = _farmLocationController.text.trim();

          // Attach farmPhoto if selected
          if (_farmPhoto != null && _farmPhoto!.isNotEmpty) {
            File farmFile = File(_farmPhoto!);
            request2.files.add(
              await http.MultipartFile.fromPath(
                "farmPhoto",
                farmFile.path,
                contentType: MediaType('image', 'jpeg'),
              ),
            );
          }

          var streamedResponse2 = await request2.send();
          var response2 = await http.Response.fromStream(streamedResponse2);
          if (response2.statusCode == 200 || response2.statusCode == 201) {
            // Both APIs succeeded. Show success alert and close dialog.
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text("Success"),
                    content: const Text("Farmer successfully registered."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // close success dialog
                          Navigator.of(
                            context,
                          ).pop(); // close add farmer dialog
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Failed to register farm: ${response2.statusCode}",
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to register user: ${response1.statusCode}"),
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
      title: const Text("Add Farmer"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // User details
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(labelText: "Gender"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const Divider(),
              // Farm details
              TextFormField(
                controller: _farmNameController,
                decoration: const InputDecoration(labelText: "Farm Name"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _farmLocationController,
                decoration: const InputDecoration(labelText: "Farm Location"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 8),
              // Photo upload fields in two lines
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.image),
                      label: const Text("Upload Profile Photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFarmPhoto,
                      icon: const Icon(Icons.image),
                      label: const Text("Upload Farm Photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              if (_profilePhoto != null) ...[
                const SizedBox(height: 8),
                Text("Selected Profile: ${_profilePhoto!.split('/').last}"),
              ],
              if (_farmPhoto != null) ...[
                const SizedBox(height: 8),
                Text("Selected Farm: ${_farmPhoto!.split('/').last}"),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancel
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: _submit, child: const Text("Submit")),
      ],
    );
  }
}
