import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  final ProviderModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _rateController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _isPasswordVisible = false;
  bool _showPasswordFields = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _rateController = TextEditingController(text: widget.user.pricePerHour.toString());
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _rateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_showPasswordFields && _passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw "Passwords do not match!";
        }
        await supabase.auth.updateUser(UserAttributes(
          password: _passwordController.text.trim(),
        ));
      }

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'price_per_hour': double.tryParse(_rateController.text) ?? 0.0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('users')
          .update(updateData)
          .eq('id', widget.user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);

    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to sign out from your account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep Logging In")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      await supabase.auth.signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isProvider = widget.user.profession != "Customer";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Edit Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout_rounded, color: Colors.redAccent)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("PERSONAL DETAILS"),
              _buildTextField("Full Name", _nameController, Icons.person_rounded),

              if (isProvider) ...[
                const SizedBox(height: 16),
                _buildTextField("Hourly Rate (PKR)", _rateController, Icons.monetization_on_rounded, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField("Bio / Professional Summary", _bioController, Icons.description_rounded, maxLines: 4),
              ],

              const SizedBox(height: 32),
              _sectionHeader("ACCOUNT SECURITY"),

              if (!_showPasswordFields)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2))
                  ),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showPasswordFields = true),
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text("Update Password", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )
              else ...[
                _buildTextField("New Password", _passwordController, Icons.vpn_key_rounded, isPassword: true),
                const SizedBox(height: 16),
                _buildTextField("Confirm New Password", _confirmPasswordController, Icons.lock_clock_rounded, isPassword: true),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _showPasswordFields = false),
                    child: const Text("Cancel Change", style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent[700],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveChanges,
                  child: Text("Save All Changes", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1.1)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, bool isNumber = false, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      maxLines: isPassword ? 1 : maxLines,
      obscureText: isPassword ? !_isPasswordVisible : false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: Colors.blueAccent),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ) : null,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
      validator: (value) {
        if (_showPasswordFields && isPassword && (value == null || value.isEmpty)) return "Please enter password";
        if (value == null || value.isEmpty) return "Required field";
        return null;
      },
    );
  }
}