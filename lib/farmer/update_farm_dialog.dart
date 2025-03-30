import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cow_and_crop/constants.dart';

class UpdateFarmDialog extends StatefulWidget {
  final Map<String, dynamic> farmData;
  final VoidCallback onUpdated;
  const UpdateFarmDialog({
    Key? key,
    required this.farmData,
    required this.onUpdated,
  }) : super(key: key);

  @override
  _UpdateFarmDialogState createState() => _UpdateFarmDialogState();
}

class _UpdateFarmDialogState extends State<UpdateFarmDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _farmNameController;
  late TextEditingController _farmLocationController;
  String? _farmPhotoPath;
  final ImagePicker _picker = ImagePicker();
  final String baseUrl = BASE_URL;

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController(
      text: widget.farmData["farmName"],
    );
    _farmLocationController = TextEditingController(
      text: widget.farmData["location"],
    );
    _farmPhotoPath = ""; // No new image selected initially.
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _farmLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickFarmPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _farmPhotoPath = pickedFile.path;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      try {
        final farmId = widget.farmData["_id"];
        final Uri uri = Uri.parse("${baseUrl}api/farmers/$farmId");
        var request = http.MultipartRequest("PUT", uri);
        request.fields["farmName"] = _farmNameController.text.trim();
        request.fields["location"] = _farmLocationController.text.trim();

        if (_farmPhotoPath != null && _farmPhotoPath!.isNotEmpty) {
          File farmFile = File(_farmPhotoPath!);
          request.files.add(
            await http.MultipartFile.fromPath(
              "farmPhoto",
              farmFile.path,
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
                  content: const Text("Farm updated successfully"),
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
              content: Text("Failed to update farm: ${response.statusCode}"),
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
      title: const Text("Update Farm"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Button to change farm image
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFarmPhoto,
                      icon: const Icon(Icons.image),
                      label: const Text("Change Farm Photo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              if (_farmPhotoPath != null && _farmPhotoPath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text("Selected: ${_farmPhotoPath!.split('/').last}"),
              ],
              // Farm Name
              TextFormField(
                controller: _farmNameController,
                decoration: const InputDecoration(labelText: "Farm Name"),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              // Farm Location
              TextFormField(
                controller: _farmLocationController,
                decoration: const InputDecoration(labelText: "Farm Location"),
                validator: (value) => value!.isEmpty ? "Required" : null,
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
