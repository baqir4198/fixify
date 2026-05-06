import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import '../models/booking_model.dart';
import 'become_provider_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ProviderModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProviderModel currentUser;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  // --- Image Pick & Upload Logic ---
  Future<void> _updateProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() => _isUploading = true);

      try {
        // Note: Yahan aap Firebase Storage use kar sakte hain, filhal path update kar rahe hain
        // Professional tareeqa ye hai ke image Firebase Storage pe upload ho aur uska URL aaye.
        String newImageUrl = image.path;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.id)
            .update({'imageUrl': newImageUrl});

        setState(() {
          currentUser.imageUrl = newImageUrl;
          _isUploading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Picture Updated!")));
      } catch (e) {
        setState(() => _isUploading = false);
        debugPrint("Upload Error: $e");
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (r) => false);
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Firestore se live data suno taake Edit Profile ke baad khud refresh ho jaye
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            currentUser = ProviderModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isUploading ? null : _updateProfileImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: (currentUser.imageUrl.isNotEmpty)
                                  ? (currentUser.imageUrl.startsWith('http')
                                  ? NetworkImage(currentUser.imageUrl)
                                  : FileImage(File(currentUser.imageUrl)) as ImageProvider)
                                  : null,
                              child: (currentUser.imageUrl.isEmpty && !_isUploading)
                                  ? Text(userInitial, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue.shade800))
                                  : _isUploading ? const CircularProgressIndicator() : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(currentUser.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(currentUser.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Stats Section (Live from Firestore)
                StreamBuilder<List<BookingModel>>(
                    stream: StorageService.getBookingsStream(currentUser.id, false),
                    builder: (context, bookingSnap) {
                      int total = bookingSnap.data?.length ?? 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard("Total Bookings", total.toString()),
                          _buildStatCard("Member Since", "2024"),
                        ],
                      );
                    }
                ),

                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        _buildProfileOption(Icons.person_outline, "Edit Profile", () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: currentUser)));
                        }),
                        _buildProfileDivider(),
                        _buildProfileOption(Icons.history, "Booking History", () {}),
                        _buildProfileDivider(),
                        _buildProfileOption(Icons.support_agent, "Help & Support", () {}),
                      ],
                    ),
                  ),
                ),

                // Become Provider Button (Only for Customers)
                if (currentUser.profession == "Customer")
                  Padding(
                    padding: const EdgeInsets.all(20),
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
                                  Text("Earn Money!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("Register as a Service Provider", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: Colors.blueGrey), title: Text(title), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: onTap);
  }

  Widget _buildProfileDivider() => Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 50);
}