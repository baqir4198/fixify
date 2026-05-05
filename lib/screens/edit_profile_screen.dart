import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  final ProviderModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  late TextEditingController _rateController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _isPasswordVisible = false;
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _aboutController = TextEditingController(text: widget.user.about);
    _rateController = TextEditingController(text: widget.user.pricePerHour.toString());
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      String finalPassword = widget.user.password;

      if (_showPasswordFields && _passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red),
          );
          return;
        }
        finalPassword = _passwordController.text.trim();
      }

      // Professional Way: Model update karte waqt saaray fields ko correctly pass karna
      ProviderModel updatedUser = ProviderModel(
        id: widget.user.id,
        name: _nameController.text.trim(),
        email: widget.user.email,
        password: finalPassword,
        profession: widget.user.profession,
        rating: widget.user.rating,
        pricePerHour: double.tryParse(_rateController.text) ?? 0.0,
        imageUrl: widget.user.imageUrl, // Existing image URL ko maintain rakha hai
        about: _aboutController.text.trim(),
      );

      await StorageService.updateProvider(updatedUser);

      if (!mounted) return;

      // Success indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic to check if the user is a provider or customer
    bool isProvider = widget.user.profession != "Customer";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("General Information"),
              _buildTextField("Full Name", _nameController, Icons.person_outline),

              if (isProvider) ...[
                const SizedBox(height: 15),
                _buildTextField("Hourly Rate (Rs.)", _rateController, Icons.payments_outlined, isNumber: true),
                const SizedBox(height: 15),
                _buildTextField("About / Bio", _aboutController, Icons.info_outline, maxLines: 3),
              ],

              const SizedBox(height: 30),

              _sectionHeader("Security"),

              if (!_showPasswordFields)
                TextButton.icon(
                  onPressed: () => setState(() => _showPasswordFields = true),
                  icon: const Icon(Icons.lock_reset, color: Colors.blue),
                  label: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                )
              else ...[
                _buildTextField("New Password", _passwordController, Icons.lock_outline, isPassword: true),
                const SizedBox(height: 15),
                _buildTextField("Confirm New Password", _confirmPasswordController, Icons.lock_reset_outlined, isPassword: true),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showPasswordFields = false;
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: const Text("Cancel Password Change", style: TextStyle(color: Colors.red)),
                ),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _saveChanges,
                  child: const Text("Update Profile", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, bool isNumber = false, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      maxLines: isPassword ? 1 : maxLines,
      obscureText: isPassword ? !_isPasswordVisible : false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ) : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade100)),
      ),
      validator: (value) {
        if (_showPasswordFields && isPassword && (value == null || value.isEmpty)) {
          return "Please fill this field";
        }
        if (!isPassword && (value == null || value.isEmpty)) {
          return "This field is required";
        }
        return null;
      },
    );
  }
}