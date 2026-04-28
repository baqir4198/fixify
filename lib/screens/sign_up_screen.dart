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

  // --- Dropdown Setup ---
  String selectedCategory = "Cleaning"; // Default value
  final List<String> categories = [
    "Cleaning",
    "Plumbing",
    "Electrician",
    "Painter",
    "Carpenter",
    "AC Repair"
  ];

  @override
  Widget build(BuildContext context) {
    bool isProvider = userRole == "Provider";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
              const Text("Fill your detail to join our community", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              const Text("Register as a:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildRoleOption("Customer", Icons.person),
                  const SizedBox(width: 15),
                  _buildRoleOption("Provider", Icons.handyman),
                ],
              ),
              const SizedBox(height: 25),

              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email Address", Icons.email_outlined),

              // --- Provider Specific Dropdown & Fields ---
              if (isProvider) ...[
                const SizedBox(height: 15),
                const Text("Select Profession", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(15),
                      items: categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField(_costController, "Hourly Rate (Rs.)", Icons.payments_outlined),
              ],

              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_reset_outlined, isObscure: true),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    if (_passwordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
                      return;
                    }

                    if (isProvider) {
                      final newProvider = ProviderModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text,
                        profession: selectedCategory, // Dropdown se category li
                        pricePerHour: double.tryParse(_costController.text) ?? 0.0,
                        rating: 5.0,
                        imageUrl: "https://via.placeholder.com/150",
                        // Agar model mein 'about' required hai toh niche wali line rakhein, warna delete kar dein
                        about: "Expert in $selectedCategory",
                      );

                      await StorageService.saveProvider(newProvider);

                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const ProviderDashboard()),
                            (route) => false,
                      );
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MainWrapper()),
                            (route) => false,
                      );
                    }

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created Successfully!")));
                  },
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
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
              const SizedBox(height: 5),
              Text(role, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          )),
    );
  }
}