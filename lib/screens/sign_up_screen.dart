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
    // 1. Professional Validation (Trimmed data)
    String name = _nameController.text.trim();
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields!")));
      return;
    }

    if (password != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }

    // 2. Data Preparation
    final newUser = ProviderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
      profession: userRole == "Provider" ? selectedCategory : "Customer",
      pricePerHour: userRole == "Provider" ? (double.tryParse(_costController.text.trim()) ?? 0.0) : 0.0,
      rating: userRole == "Provider" ? 5.0 : 0.0,
      imageUrl: "",
      about: userRole == "Provider" ? "Professional $selectedCategory service provider." : "Customer Account",
    );

    // 3. Save to Storage
    await StorageService.saveProvider(newUser);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account Created Successfully!"), backgroundColor: Colors.green),
    );

    // 4. NAVIGATION WITH DATA (Fixed Logic)
    if (userRole == "Provider") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProviderDashboard(provider: newUser)),
            (route) => false,
      );
    } else {
      // Yahan humne naya user pass kar diya taake MainWrapper ko Baqir wala data na dikhana parray
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainWrapper(user: newUser)),
            (route) => false,
      );
    }
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, letterSpacing: -1)),
              const SizedBox(height: 10),
              const Text("Join us to find or provide services", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 35),

              // Role Selection UI
              Row(children: [
                _buildRoleOption("Customer", Icons.person_outline_rounded),
                const SizedBox(width: 15),
                _buildRoleOption("Provider", Icons.handyman_outlined),
              ]),
              const SizedBox(height: 30),

              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email Address", Icons.email_outlined, isEmail: true),
              const SizedBox(height: 15),

              if (isProvider) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text("Select Expertise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField(_costController, "Hourly Rate (Rs.)", Icons.payments_outlined, isNumber: true),
                const SizedBox(height: 15),
              ],

              _buildTextField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
              const SizedBox(height: 15),
              _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_reset_outlined, isObscure: true),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _handleSignUp,
                  child: const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: 2),
          ),
          child: Column(children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(role, style: TextStyle(color: isSelected ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
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
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
      ),
    );
  }
}