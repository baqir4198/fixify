import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/main_wrapper.dart';
import 'package:handyman_app/screens/provider_dashboard.dart';
import 'package:handyman_app/screens/sign_up_screen.dart';
import 'package:handyman_app/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String userRole = "Customer";

  void _handleLogin() async {
    String emailInput = _emailController.text.trim();
    String passwordInput = _passwordController.text.trim();

    if (emailInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter credentials")));
      return;
    }

    setState(() => _isLoading = true);

    // 1. Storage se saare users uthaye
    List<ProviderModel> allUsers = await StorageService.getSavedProviders();

    try {
      // 2. Email aur Password se user dhoondo
      final matchingUser = allUsers.firstWhere(
            (u) => u.email == emailInput && u.password == passwordInput,
      );

      if (!mounted) return;

      // 3. ROLE VERIFICATION LOGIC
      if (userRole == "Customer" && matchingUser.profession != "Customer") {
        throw "This email is registered as a Provider. Please login as Provider.";
      }

      if (userRole == "Provider" && matchingUser.profession == "Customer") {
        throw "This email is registered as a Customer. Please login as Customer.";
      }

      // 4. SESSION MANAGEMENT: Login hotay hi user ko save karein (IMPORTANT)
      // Note: StorageService mein saveProvider ya koi specific current user function call karein
      // Agar aapne session management implement ki hai toh yahan call hogi.

      // 5. NAVIGATION WITH DATA (Sab se aham change)
      if (userRole == "Provider") {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProviderDashboard(provider: matchingUser))
        );
      } else {
        // MainWrapper ko 'matchingUser' pass kar diya gaya hai
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainWrapper(user: matchingUser))
        );
      }

    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString().replaceAll("Exception: ", "");
      if (e is StateError) errorMsg = "Invalid Email or Password!";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              // Role Selector UI
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                child: Row(
                    children: [
                      _buildRoleButton("Customer"),
                      _buildRoleButton("Provider")
                    ]
                ),
              ),
              const SizedBox(height: 30),
              _buildInputField(_emailController, "Email Address", Icons.email_outlined),
              const SizedBox(height: 20),
              _buildInputField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account?"),
                TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                    child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold))
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    bool isSelected = userRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => userRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(role, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.blue[700] : Colors.grey)),
        ),
      ),
    );
  }
}