import 'package:flutter/material.dart';
import 'package:handyman_app/services/storage_service.dart'; // Storage service import karein
import 'become_provider_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int totalBookings = 0;
  int completedBookings = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Booking stats load karne ka function
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

            // --- User Header Section ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text("Hamza Ahmad", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("hamza@email.com", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- NEW: Stats Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard("Total", totalBookings.toString(), Colors.blue),
                  const SizedBox(width: 15),
                  _buildStatCard("Done", completedBookings.toString(), Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // --- Menu Options Section ---
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
                    _buildProfileOption(Icons.person_outline, "Edit Profile", () {}),
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

            // --- Become Provider Card ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BecomeProviderScreen()));
                },
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
              onPressed: () {},
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Stats Card UI Helper
  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildProfileDivider() {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 50);
  }
}