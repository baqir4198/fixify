import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../services/storage_service.dart';

class BecomeProviderScreen extends StatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  State<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to get data from text fields
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedCategory = 'Plumbing'; // Default category
  final List<String> _categories = ['Plumbing', 'Electrical', 'Cleaning', 'Painting', 'Carpentry', 'AC Repair'];

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      // 1. Naya Provider object banayein
      final newProvider = ProviderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        profession: _selectedCategory,
        rating: 4.5, // New providers start with a default rating
        pricePerHour: double.parse(_priceController.text),
        imageUrl: 'https://i.pravatar.cc/150?u=${_nameController.text}', about: '', // Random avatar for now
      );

      // 2. Storage mein save karein
      await StorageService.saveProvider(newProvider);

      if (!mounted) return;

      // 3. Success Message aur Screen se wapis jana
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Congratulations! You are now a Provider"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register as Provider"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tell us about your skills", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Fill in the details to start earning.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // Name Field
              _buildTextField(_nameController, "Full Name", Icons.person, "Enter your name"),
              const SizedBox(height: 20),

              // Category Dropdown
              const Text("Select your Expertise", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((String category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Price Field
              _buildTextField(_priceController, "Price per Hour (\$)", Icons.attach_money, "e.g. 25", isNumber: true),
              const SizedBox(height: 20),

              // Bio Field
              _buildTextField(_bioController, "Short Bio", Icons.description, "Tell users about your experience", maxLines: 3),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _submitData,
                  child: const Text("Register Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      validator: (value) => value == null || value.isEmpty ? "This field is required" : null,
    );
  }
}