import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'become_provider_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProviderModel user; // 1. User object accept karein
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int totalBookings = 0;
  int completedBookings = 0;

  // 2. Late variable banaya taake hum widget.user se initialize kar sakein
  late ProviderModel currentUser;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user; // Initials data pass ho gaya
    _imagePath = currentUser.imageUrl;
    _loadStats();
  }

  // --- Image Pick karne ka function (Professional version) ---
  Future<void> _pickAndSaveImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });

        ProviderModel updatedUser = ProviderModel(
          id: currentUser.id,
          name: currentUser.name,
          email: currentUser.email,
          password: currentUser.password,
          profession: currentUser.profession,
          rating: currentUser.rating,
          pricePerHour: currentUser.pricePerHour,
          imageUrl: image.path,
          about: currentUser.about,
        );

        await StorageService.updateProvider(updatedUser);

        // Local state update taake UI foran refresh ho
        setState(() {
          currentUser = updatedUser;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Picture Updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _loadStats() async {
    final bookings = await StorageService.getBookings();
    setState(() {
      totalBookings = bookings.length;
      completedBookings = bookings.where((b) => b.status == 'Completed').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    String userInitial = currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : "?";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndSaveImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: (_imagePath != null && _imagePath!.isNotEmpty && !(_imagePath!.startsWith('http')))
                                ? FileImage(File(_imagePath!))
                                : (_imagePath != null && _imagePath!.startsWith('http'))
                                ? NetworkImage(_imagePath!) as ImageProvider
                                : null,
                            child: (_imagePath == null || _imagePath!.isEmpty)
                                ? Text(userInitial, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue.shade800))
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text("CUSTOMER", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 8),
                  Text(currentUser.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(currentUser.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    _buildProfileOption(Icons.person_outline, "Edit Profile", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen(user: currentUser)),
                      ).then((_) {
                        // Edit ke baad agar data change ho toh storage se refresh karein
                        // Ya yahan callback logic laga sakte hain
                      });
                    }),
                    _buildProfileDivider(),
                    _buildProfileOption(Icons.history, "Booking History", () {}),
                    _buildProfileDivider(),
                    _buildProfileOption(Icons.notifications_none, "Notifications", () {}),
                    _buildProfileDivider(),
                    _buildProfileOption(Icons.security, "Privacy & Policy", () {}),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BecomeProviderScreen())),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.storefront, color: Colors.white, size: 30),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Earn Money!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Register as a Service Provider", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (r) => false),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: Colors.blueGrey), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey), onTap: onTap);
  }

  Widget _buildProfileDivider() {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 50);
  }
}