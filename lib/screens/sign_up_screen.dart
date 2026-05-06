import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/main_wrapper.dart';
import 'package:handyman_app/screens/provider_dashboard.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _costController = TextEditingController();

  String userRole = "Customer";
  String selectedCategory = "Cleaning";
  final List<String> categories = ["Cleaning", "Plumbing", "Electrician", "Painter", "Carpenter", "AC Repair"];

  File? _profileImage;
  File? _cnicImage;
  bool _isLoading = false;

  Future<void> _pickImage(bool isProfile) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Size thora kam rakhein ge taake upload teiz ho
    );
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _cnicImage = File(pickedFile.path);
        }
      });
    }
  }

  void _handleSignUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    // Validations
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Please fill all fields!");
      return;
    }
    if (password != _confirmPasswordController.text.trim()) {
      _showError("Passwords do not match!");
      return;
    }
    if (userRole == "Provider" && _cnicImage == null) {
      _showError("Please upload CNIC photo for verification!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth Account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;
      String profileUrl = "";
      String cnicUrl = "";

      // 2. Upload Profile Picture (DP) if exists
      if (_profileImage != null) {
        var ref = FirebaseStorage.instance.ref().child("profiles/$uid.jpg");
        await ref.putFile(_profileImage!);
        profileUrl = await ref.getDownloadURL();
      }

      // 3. Upload CNIC Image if Provider
      if (userRole == "Provider" && _cnicImage != null) {
        var ref = FirebaseStorage.instance.ref().child("cnics/$uid.jpg");
        await ref.putFile(_cnicImage!);
        cnicUrl = await ref.getDownloadURL();
      }

      // 4. Prepare User Data
      final newUser = ProviderModel(
        id: uid,
        name: name,
        email: email,
        password: "", // Security ke liye khali
        profession: userRole == "Provider" ? selectedCategory : "Customer",
        pricePerHour: userRole == "Provider" ? (double.tryParse(_costController.text.trim()) ?? 0.0) : 0.0,
        rating: userRole == "Provider" ? 5.0 : 0.0,
        imageUrl: profileUrl, // DP
        cnicUrl: cnicUrl,    // New field for verification
        about: userRole == "Provider" ? "Professional $selectedCategory provider." : "Customer",
      );

      // 5. Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser.toMap());

      if (!mounted) return;

      // 6. Navigation
      if (userRole == "Provider") {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => ProviderDashboard(provider: newUser)), (route) => false);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MainWrapper(user: newUser)), (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Registration Failed");
    } catch (e) {
      _showError("Something went wrong: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    bool isProvider = userRole == "Provider";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
              const SizedBox(height: 25),

              // --- DP SELECTION ---
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.blue[50],
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null ? Icon(Icons.person_add_alt_1, size: 45, color: Colors.blue[200]) : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: Colors.blue[700], child: const Icon(Icons.edit, size: 15, color: Colors.white))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Role Selection
              Row(children: [
                _buildRoleOption("Customer", Icons.person_outline),
                const SizedBox(width: 15),
                _buildRoleOption("Provider", Icons.handyman_outlined),
              ]),
              const SizedBox(height: 25),

              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email", Icons.email_outlined, isEmail: true),
              const SizedBox(height: 15),

              if (isProvider) ...[
                // Category Dropdown
                _buildCategoryDropdown(),
                const SizedBox(height: 15),
                _buildTextField(_costController, "Hourly Rate (Rs.)", Icons.payments_outlined, isNumber: true),
                const SizedBox(height: 20),

                // --- CNIC UPLOAD ---
                const Text("CNIC / ID Card Photo (Required)", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _cnicImage == null
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey), Text("Upload ID Photo")])
                        : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_cnicImage!, fit: BoxFit.cover)),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildTextField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_reset, isObscure: true),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _handleSignUp,
                  child: const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Widgets
  Widget _buildRoleOption(String role, IconData icon) {
    bool isSelected = userRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => userRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: 2),
          ),
          child: Column(children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            Text(role, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false, bool isNumber = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}