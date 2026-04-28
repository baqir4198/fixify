import 'package:flutter/material.dart';
import 'package:handyman_app/screens/main_wrapper.dart';
import 'package:handyman_app/screens/sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Isse pata chalega ke user kaun hai
  String userRole = "Customer";

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
              // --- Header ---
              const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text("Login to continue your journey", style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 40),

              // --- Role Selection (Toggle) ---
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    _buildRoleButton("Customer"),
                    _buildRoleButton("Provider"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- Input Fields ---
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Email Address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text("Forgot Password?")),
              ),

              const SizedBox(height: 20),

              // --- Login Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // Yahan logic check hoga
                    if (userRole == "Customer") {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainWrapper()));
                    } else {
                      // Filhal Provider ka dashboard nahi bana, toh yahan alert dikha dete hain
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Provider Dashboard coming soon!")),
                      );
                    }
                  },
                  child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 30),

              // --- Signup Link ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpScreen())
                        );
                      },
                   child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Role Switcher Button Helper
  Widget _buildRoleButton(String role) {
    bool isSelected = userRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => userRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            role,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue[700] : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}