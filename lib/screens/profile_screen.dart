import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'become_provider_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int totalBookings = 0;
  int completedBookings = 0;

  String userName = "Loading...";
  String userEmail = "...";
  String userInitial = "";
  String? _imagePath;
  ProviderModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  // --- User Data aur Saved Image Load Karein ---
  Future<void> _loadUserData() async {
    final users = await StorageService.getSavedProviders();
    if (users.isNotEmpty) {
      currentUser = users.last;
      setState(() {
        userName = currentUser!.name;
        userEmail = currentUser!.email;
        _imagePath = currentUser!.imageUrl;
        userInitial = currentUser!.name.isNotEmpty ? currentUser!.name[0].toUpperCase() : "?";
      });
    }
  }

  // --- Direct Image Pick aur Save karne ka function ---
  Future<void> _pickAndSaveImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

      if (image != null && currentUser != null) {
        // 1. UI update karein
        setState(() {
          _imagePath = image.path;
        });

        // 2. Model update karke storage mein save karein
        ProviderModel updatedUser = ProviderModel(
          id: currentUser!.id,
          name: currentUser!.name,
          email: currentUser!.email,
          password: currentUser!.password,
          profession: currentUser!.profession,
          rating: currentUser!.rating,
          pricePerHour: currentUser!.pricePerHour,
          imageUrl: image.path, // Naya path save ho gaya
          about: currentUser!.about,
        );

        await StorageService.updateProvider(updatedUser);

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

            // --- User Header (Ab Clickable hai) ---
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndSaveImage, // Poore circle ya pencil par click se picker khulega
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
                            // Logic: Agar image path hai toh image dikhao, warna Initials
                            backgroundImage: (_imagePath != null && _imagePath!.isNotEmpty && !(_imagePath!.startsWith('http')))
                                ? FileImage(File(_imagePath!))
                                : (_imagePath != null && _imagePath!.startsWith('http'))
                                ? NetworkImage(_imagePath!) as ImageProvider
                                : null,
                            child: (_imagePath == null || _imagePath!.isEmpty)
                                ? Text(
                              userInitial,
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                            )
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
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "CUSTOMER",
                      style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- Baaki Menu Options ---
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
                        MaterialPageRoute(builder: (context) => EditProfileScreen(user: currentUser!)),
                      ).then((value) => _loadUserData()); // Wapsi par data refresh
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

            // Become Provider Card
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

  // Helper Widgets (BuildStatCard, BuildProfileOption, BuildProfileDivider) - same as before
  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
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