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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _priceController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedCategory = 'Plumbing';
  final List<String> _categories = [
    'Plumbing', 'Electrical', 'Cleaning', 'Painting', 'Carpentry', 'AC Repair'
  ];

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      // Professional Way: Data ko model mein daalne se pehle trim karna zaroori hai
      final newProvider = ProviderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(), // Email hamesha lowercase mein save karein
        password: _passwordController.text.trim(),
        profession: _selectedCategory,
        rating: 4.5,
        pricePerHour: double.tryParse(_priceController.text.trim()) ?? 0.0,
        imageUrl: '', // Random image removed as requested
        about: _bioController.text.trim(),
      );

      await StorageService.saveProvider(newProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Congratulations! You are now a Provider"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Floating snackbar zyada professional lagta hai
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Service Provider Registration",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tell us about your skills",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text("Fill in the details to start your professional journey.",
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 32),

              _buildTextField(_nameController, "Full Name", Icons.person_outline, "Enter your full name"),
              const SizedBox(height: 20),

              _buildTextField(_emailController, "Email Address", Icons.email_outlined, "name@example.com",
                  isEmail: true), // Enable @ keyboard
              const SizedBox(height: 20),

              _buildTextField(_passwordController, "Password", Icons.lock_outline, "Create a strong password",
                  isObscure: true),
              const SizedBox(height: 24),

              const Text("Select your Expertise",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _categories.map((String category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(_priceController, "Price per Hour (Rs.)", Icons.account_balance_wallet_outlined, "e.g. 1200",
                  isNumber: true),
              const SizedBox(height: 20),

              _buildTextField(_bioController, "Short Bio", Icons.edit_note_rounded, "Describe your experience...",
                  maxLines: 4),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5), // Professional Blue
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _submitData,
                  child: const Text("Complete Registration",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      String hint,
      {bool isNumber = false, bool isEmail = false, bool isObscure = false, int maxLines = 1}
      ) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      obscureText: isObscure,
      maxLines: isObscure ? 1 : maxLines, // Password multi-line nahi ho sakta
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 22, color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "This field is required";
        if (isEmail && !value.contains('@')) return "Enter a valid email";
        return null;
      },
    );
  }
}