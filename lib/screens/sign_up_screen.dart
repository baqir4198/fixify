import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/services/storage_service.dart';
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

  void _handleSignUp() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields!")));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }

    setState(() {}); // Loading state logic yahan add kar sakte hain

    if (userRole == "Provider") {
      final newProvider = ProviderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        profession: selectedCategory,
        pricePerHour: double.tryParse(_costController.text) ?? 0.0,
        rating: 5.0,
        imageUrl: "https://i.pravatar.cc/150",
        about: "Expert $selectedCategory service provider.",
      );

      await StorageService.saveProvider(newProvider);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProviderDashboard(provider: newProvider)),
            (route) => false,
      );
    } else {
      // CUSTOMER SIGNUP LOGIC:
      // Hum Customer ko bhi ProviderModel mein save kar rahe hain ya alag se handle kar sakte hain.
      // Filhaal easy rakhne ke liye hum Storage mein mark kar rahe hain ke ye Customer hai.

      final newCustomer = ProviderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        profession: "Customer", // Role identify karne ke liye
        pricePerHour: 0.0,
        rating: 0.0,
        imageUrl: "https://i.pravatar.cc/150",
        about: "Handyman App User",
      );

      await StorageService.saveProvider(newCustomer);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
            (route) => false,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created Successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    bool isProvider = userRole == "Provider";
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              const SizedBox(height: 30),
              Row(children: [
                _buildRoleOption("Customer", Icons.person),
                const SizedBox(width: 15),
                _buildRoleOption("Provider", Icons.handyman),
              ]),
              const SizedBox(height: 25),
              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email Address", Icons.email_outlined),
              if (isProvider) ...[
                const SizedBox(height: 15),
                _buildTextField(_costController, "Hourly Rate (Rs.)", Icons.payments_outlined, isNumber: true),
              ],
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_reset_outlined, isObscure: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _handleSignUp,
                  child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String role, IconData icon) {
    bool isSelected = userRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => userRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? Colors.blue : Colors.transparent),
          ),
          child: Column(children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 5),
            Text(role, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false, bool isNumber = false}) {
    return TextField(
      controller: controller, obscureText: isObscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(prefixIcon: Icon(icon), hintText: hint, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
    );
  }
}