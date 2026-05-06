import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/provider_model.dart';

class BecomeProviderScreen extends StatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  State<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedCategory = 'Plumbing';
  final List<String> _categories = [
    'Plumbing', 'Electrical', 'Cleaning', 'Painting', 'Carpentry', 'AC Repair'
  ];

  File? _profileImage;
  File? _cnicImage;
  bool _isLoading = false;

  Future<void> _pickImage(bool isProfile) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        if (isProfile) _profileImage = File(pickedFile.path);
        else _cnicImage = File(pickedFile.path);
      });
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_cnicImage == null) {
        _showSnackBar("Please upload CNIC photo for verification", Colors.red);
        return;
      }

      setState(() => _isLoading = true);

      try {
        final String uid = FirebaseAuth.instance.currentUser!.uid;
        String profileUrl = "";
        String cnicUrl = "";

        // 1. Upload Profile Photo if selected
        if (_profileImage != null) {
          var ref = FirebaseStorage.instance.ref().child("profiles/$uid.jpg");
          await ref.putFile(_profileImage!);
          profileUrl = await ref.getDownloadURL();
        }

        // 2. Upload CNIC Photo (Mandatory for Provider)
        var cnicRef = FirebaseStorage.instance.ref().child("cnics/$uid.jpg");
        await cnicRef.putFile(_cnicImage!);
        cnicUrl = await cnicRef.getDownloadURL();

        // 3. Prepare Data for Firestore
        final providerData = ProviderModel(
          id: uid,
          name: _nameController.text.trim(),
          email: FirebaseAuth.instance.currentUser!.email ?? "",
          password: "", // Auth handle kar raha hai
          profession: _selectedCategory,
          rating: 5.0,
          pricePerHour: double.tryParse(_priceController.text.trim()) ?? 0.0,
          imageUrl: profileUrl,
          cnicUrl: cnicUrl,
          about: _bioController.text.trim(),
        );

        // 4. Update Firestore Document
        await FirebaseFirestore.instance.collection('users').doc(uid).set(providerData.toMap(), SetOptions(merge: true));

        if (!mounted) return;
        _showSnackBar("Congratulations! You are now a Provider", Colors.green);
        Navigator.pop(context);

      } catch (e) {
        _showSnackBar("Error: $e", Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Become a Provider", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- DP SELECTION ---
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey) : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(_nameController, "Full Name", Icons.person_outline, "Your name"),
              const SizedBox(height: 24),

              const Text("Select Expertise", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              _buildDropdown(),
              const SizedBox(height: 24),

              _buildTextField(_priceController, "Price per Hour (Rs.)", Icons.payments_outlined, "e.g. 1200", isNumber: true),
              const SizedBox(height: 24),

              _buildTextField(_bioController, "Short Bio", Icons.edit_note_rounded, "Tell us about your experience", maxLines: 3),
              const SizedBox(height: 24),

              // --- CNIC UPLOAD ---
              const Text("CNIC Photo (Verification)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _cnicImage == null
                      ? const Icon(Icons.upload_file, size: 40, color: Colors.grey)
                      : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_cnicImage!, fit: BoxFit.cover)),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submitData,
                  child: const Text("Complete Registration", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }
}