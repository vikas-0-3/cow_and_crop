import 'dart:io';
import 'package:cow_and_crop/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'constants.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  final String baseUrl = BASE_URL;

  // Step 1 controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Step 2 controllers
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  final List<String> _genderOptions = ["male", "female"];
  final TextEditingController _addressController = TextEditingController();
  String? _profilePhotoPath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfilePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profilePhotoPath = pickedFile.path;
      });
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Validate step 1: Name, Email, Phone, Password required.
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all required fields")),
        );
        return;
      }
      setState(() {
        _currentStep = 1;
      });
    } else if (_currentStep == 1) {
      // Validate step 2: Age, Gender, Address required.
      if (_ageController.text.isEmpty ||
          _selectedGender == null ||
          _addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all required fields")),
        );
        return;
      }
      _submitRegistration();
    }
  }

  void _onStepCancel() {
    if (_currentStep == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        _currentStep = _currentStep - 1;
      });
    }
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Build the multipart request
      final Uri uri = Uri.parse("${baseUrl}api/auth/register");
      var request = http.MultipartRequest("POST", uri);

      // Add fields
      request.fields["name"] = _nameController.text.trim();
      request.fields["email"] = _emailController.text.trim();
      request.fields["phone"] = _phoneController.text.trim();
      request.fields["password"] = _passwordController.text.trim();
      request.fields["age"] = _ageController.text.trim();
      request.fields["gender"] = _selectedGender ?? "";
      request.fields["address"] = _addressController.text.trim();
      request.fields["role"] = "user"; // or "farmer" if needed

      // Attach profile photo if selected
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
        // Registration successful, show success alert and pop page
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Success"),
                content: const Text("Registration successful. Please log in."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // close success dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ); // pop registration page
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      } else {
        setState(() {
          _errorMessage = "Failed to register: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Background shapes similar to login page
      body: Stack(
        children: [
          // TOP-RIGHT PINK SHAPE
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 220,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5E99),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          // BOTTOM-LEFT PINK SHAPE
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFFFA4D3),
                borderRadius: BorderRadius.only(topRight: Radius.circular(100)),
              ),
            ),
          ),
          // Main Content: Two-step registration using Stepper
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // New text at top
                  const Center(
                    child: Text(
                      "Create an account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Stepper(
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    steps: [
                      Step(
                        title: const Text("Step 1"),
                        isActive: _currentStep >= 0,
                        state:
                            _currentStep > 0
                                ? StepState.complete
                                : StepState.indexed,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: "Name",
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: "Email",
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: "Phone",
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: "Password",
                              ),
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),
                      Step(
                        title: const Text("Step 2"),
                        isActive: _currentStep >= 1,
                        state:
                            _currentStep > 1
                                ? StepState.complete
                                : StepState.indexed,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: "Age",
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Gender",
                              ),
                              value: _selectedGender,
                              items:
                                  _genderOptions
                                      .map(
                                        (gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender.toUpperCase()),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: "Address",
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickProfilePhoto,
                                    icon: const Icon(Icons.image),
                                    label: const Text("Upload Profile Photo"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_profilePhotoPath != null &&
                                _profilePhotoPath!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Selected: ${_profilePhotoPath!.split('/').last}",
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    controlsBuilder: (
                      BuildContext context,
                      ControlsDetails details,
                    ) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep != 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text("Back"),
                            ),
                          TextButton(
                            onPressed: details.onStepContinue,
                            child: Text(_currentStep == 1 ? "Submit" : "Next"),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_errorMessage != null)
                    Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Sign Up Screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign in",
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
