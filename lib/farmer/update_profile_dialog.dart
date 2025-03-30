import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cow_and_crop/constants.dart';

class UpdateProfileDialog extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onUpdated;
  const UpdateProfileDialog({
    Key? key,
    required this.userData,
    required this.onUpdated,
  }) : super(key: key);

  @override
  _UpdateProfileDialogState createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<UpdateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final String baseUrl = BASE_URL;
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  // late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _profilePhotoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userData?["name"] ?? "",
    );
    _ageController = TextEditingController(
      text: widget.userData?["age"]?.toString() ?? "",
    );
    _genderController = TextEditingController(
      text: widget.userData?["gender"] ?? "",
    );
    // _emailController = TextEditingController(
    //   text: widget.userData?["email"] ?? "",
    // );
    _phoneController = TextEditingController(
      text: widget.userData?["phone"] ?? "",
    );
    _addressController = TextEditingController(
      text: widget.userData?["address"] ?? "",
    );
    _profilePhotoPath = ""; // Initially no new image selected.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    // _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profilePhotoPath = pickedFile.path;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final String userId = widget.userData?["_id"] ?? "";
      final Uri uri = Uri.parse("${baseUrl}api/users/$userId");
      var request = http.MultipartRequest("PUT", uri);
      request.fields["name"] = _nameController.text.trim();
      request.fields["age"] = _ageController.text.trim();
      request.fields["gender"] = _genderController.text.trim();
      // request.fields["email"] = _emailController.text.trim();
      request.fields["phone"] = _phoneController.text.trim();
      request.fields["address"] = _addressController.text.trim();

      if (_profilePhotoPath != null && _profilePhotoPath!.isNotEmpty) {
        File profileFile = File(_profilePhotoPath!);
        request.files.add(
          await http.MultipartFile.fromPath(
            "profilePhoto",
            profileFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onUpdated();
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Success"),
                content: const Text("Profile updated successfully"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // close success dialog
                      Navigator.of(context).pop(); // close update dialog
                      widget.onUpdated();
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile: ${response.statusCode}"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Profile"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Button to change profile image
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.image),
                      label: const Text("Change Profile Photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              if (_profilePhotoPath != null &&
                  _profilePhotoPath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text("Selected: ${_profilePhotoPath!.split('/').last}"),
              ],
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Gender"),
                value:
                    _genderController.text.isNotEmpty
                        ? _genderController.text
                        : null,
                items: const [
                  DropdownMenuItem(value: "male", child: Text("Male")),
                  DropdownMenuItem(value: "female", child: Text("Female")),
                ],
                onChanged: (value) {
                  setState(() {
                    _genderController.text = value ?? "";
                  });
                },
                validator:
                    (value) =>
                        (value == null || value.isEmpty) ? "Required" : null,
              ),

              // TextFormField(
              //   controller: _emailController,
              //   decoration: const InputDecoration(labelText: "Email"),
              //   validator: (value) => value!.isEmpty ? "Required" : null,
              // ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: _submit, child: const Text("Submit")),
      ],
    );
  }
}
