import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  final ProviderModel currentProvider;
  const EditProfileScreen({super.key, required this.currentProvider});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _aboutController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProvider.name);
    _priceController = TextEditingController(text: widget.currentProvider.pricePerHour.toString());
    _aboutController = TextEditingController(text: widget.currentProvider.about);
    _imagePath = widget.currentProvider.imageUrl;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  // --- Profile Save Logic ---
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Naya Model object banaya jis mein email aur password purane wale hi pass kiye hain
      ProviderModel updatedProvider = ProviderModel(
        id: widget.currentProvider.id,
        name: _nameController.text,
        email: widget.currentProvider.email,       // Model update fix
        password: widget.currentProvider.password, // Model update fix
        profession: widget.currentProvider.profession,
        rating: widget.currentProvider.rating,
        pricePerHour: double.tryParse(_priceController.text) ?? widget.currentProvider.pricePerHour,
        imageUrl: _imagePath ?? widget.currentProvider.imageUrl,
        about: _aboutController.text,
      );

      // Storage mein update kiya
      await StorageService.updateProvider(updatedProvider);

      if (!mounted) return;

      // Wapis Dashboard par naya data bhej diya
      Navigator.pop(context, updatedProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Updated Successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Image Picker ---
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue[50],
                      backgroundImage: _imagePath != null
                          ? (_imagePath!.startsWith('http')
                          ? NetworkImage(_imagePath!)
                          : FileImage(File(_imagePath!)) as ImageProvider)
                          : null,
                      child: (_imagePath == null || _imagePath!.isEmpty)
                          ? const Icon(Icons.person, size: 60, color: Colors.blue)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField("Full Name", _nameController, Icons.person_outline),
              const SizedBox(height: 20),

              _buildTextField("Price per Hour (Rs.)", _priceController, Icons.payments_outlined, isNumber: true),
              const SizedBox(height: 20),

              _buildTextField("About / Experience", _aboutController, Icons.description_outlined, maxLines: 4),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Save Changes",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      validator: (value) => value!.isEmpty ? "This field is required" : null,
    );
  }
}