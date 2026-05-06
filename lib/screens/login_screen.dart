import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/main_wrapper.dart';
import 'package:handyman_app/screens/sign_up_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// Note: ProviderDashboard ka import agar aapke paas file hai toh rehne dein
// import 'package:handyman_app/screens/provider_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // Password toggle ke liye
  String userRole = "Customer"; // Default role

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth Login
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // 2. Firestore se User ka Data nikalna
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw "User record not found in database!";
      }

      // 3. Map ko Model mein convert karna (Safely)
      final userData = userDoc.data() as Map<String, dynamic>;
      final matchingUser = ProviderModel.fromMap(userData, docId: uid);

      if (!mounted) return;

      // 4. Role Based Validation
      // Customer login kar raha hai lekin database mein wo 'Provider' hai
      if (userRole == "Customer" && (userData['profession'] != "Customer" && userData['profession'] != null)) {
        await FirebaseAuth.instance.signOut();
        throw "This account is registered as a Provider. Please login as Provider.";
      }

      // Provider login kar raha hai lekin database mein wo 'Customer' hai
      if (userRole == "Provider" && userData['profession'] == "Customer") {
        await FirebaseAuth.instance.signOut();
        throw "This account is registered as a Customer. Please login as Customer.";
      }

      // 5. Success Navigation (Passing the 'user' object)
      if (userRole == "Provider") {
        // Agar aapne ProviderDashboard banayi hai toh wahan bhejain
        /* Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProviderDashboard(provider: matchingUser))
        ); */
        _showError("Provider Dashboard is under development");
      } else {
        // YAHAN HUM 'user' PASS KAR RHE HAIN JO ERROR FIX KAREGA
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainWrapper(user: matchingUser))
        );
      }

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication Failed");
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                "Welcome Back",
                style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                "Login to continue your Fixify journey",
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Role Selector
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _buildRoleButton("Customer"),
                    _buildRoleButton("Provider"),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // Email Input
              _buildTextField(
                controller: _emailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              // Password Input with Visibility Toggle
              _buildTextField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.blue)),
                ),
              ),

              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                    child: Text(
                      "Create One",
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
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
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                : null,
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