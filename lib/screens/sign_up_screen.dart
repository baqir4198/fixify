import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Naya package address conversion k liye
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/main_wrapper.dart';
import 'package:handyman_app/screens/provider_dashboard.dart';
import 'package:google_fonts/google_fonts.dart';

final supabase = Supabase.instance.client;

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

  // Naye controllers user k asani k liye
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Background controllers jo database me value bhejein ge
  String _detectedLatitude = "";
  String _detectedLongitude = "";

  String userRole = "Customer";
  String selectedCategory = "Cleaning";
  final List<String> categories = ["Cleaning", "Plumbing", "Electrician", "Painter", "Carpenter", "AC Repair"];

  File? _profileImage;
  File? _cnicImage;
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _costController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- Automatic Location Fetching ---
  Future<void> _autoFetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError("Your device GPS is turned off. Please turn it on or enter address manually.");
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError("Location permission denied.");
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Background variables me save kr lia
      _detectedLatitude = position.latitude.toString();
      _detectedLongitude = position.longitude.toString();

      // Reverse Geocoding: Coordinates se city aur address khud dhoondna
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _cityController.text = place.locality ?? "";
          _addressController.text = "${place.street ?? ''}, ${place.subLocality ?? ''}".trim();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Location & Address fetched automatically!"),
        backgroundColor: Colors.green,
      ));

    } catch (e) {
      _showError("Could not fetch location automatically: $e");
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  // --- Manual Address ko Coordinates me badalna ---
  Future<bool> _convertAddressToCoordinates() async {
    String fullAddress = "${_addressController.text.trim()}, ${_cityController.text.trim()}";
    try {
      List<Location> locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        _detectedLatitude = locations[0].latitude.toString();
        _detectedLongitude = locations[0].longitude.toString();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Geocoding Error: $e");
      return false;
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _cnicImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<String> _uploadToSupabase(File file, String bucket, String fileName) async {
    try {
      final bytes = await file.readAsBytes();
      await supabase.storage.from(bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      if (bucket == 'profiles') {
        return supabase.storage.from(bucket).getPublicUrl(fileName);
      } else {
        return fileName;
      }
    } catch (e) {
      debugPrint("Upload Error in $bucket: $e");
      return "";
    }
  }

  void _handleSignUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();
    String currentRole = userRole;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Please fill all fields!");
      return;
    }
    if (password.length < 6) {
      _showError("Password should be at least 6 characters.");
      return;
    }
    if (password != _confirmPasswordController.text.trim()) {
      _showError("Passwords do not match!");
      return;
    }

    // Provider validations
    if (currentRole == "Provider") {
      if (_cnicImage == null) {
        _showError("Please upload CNIC photo for verification!");
        return;
      }
      if (_cityController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
        _showError("Please fill your City and Address!");
        return;
      }
    }

    setState(() => _isLoading = true);

    double latitude = 0.0;
    double longitude = 0.0;

    if (currentRole == "Provider") {
      // Agar user ne manual text likha tha aur auto GPS pick nahi kiya tha
      if (_detectedLatitude.isEmpty || _detectedLongitude.isEmpty) {
        bool success = await _convertAddressToCoordinates();
        if (!success) {
          setState(() => _isLoading = false);
          _showError("Could not find coordinates for this address. Please write a valid city/area name.");
          return;
        }
      }
      latitude = double.tryParse(_detectedLatitude) ?? 0.0;
      longitude = double.tryParse(_detectedLongitude) ?? 0.0;
    }

    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': currentRole},
      );

      final String? uid = res.user?.id;
      if (uid == null) throw "User registration failed!";

      String profileUrl = "";
      String cnicUrl = "";

      if (_profileImage != null) {
        profileUrl = await _uploadToSupabase(_profileImage!, 'profiles', '$uid-profile.jpg');
      }

      if (currentRole == "Provider" && _cnicImage != null) {
        cnicUrl = await _uploadToSupabase(_cnicImage!, 'cnics', '$uid-cnic.jpg');
      }

      final newUser = ProviderModel(
        id: uid,
        name: name,
        email: email,
        profession: currentRole == "Provider" ? selectedCategory : "Customer",
        pricePerHour: currentRole == "Provider" ? (double.tryParse(_costController.text.trim()) ?? 0.0) : 0.0,
        imageUrl: profileUrl,
        cnicUrl: cnicUrl,
        bio: currentRole == "Provider" ? "Professional $selectedCategory provider." : "Customer Account",
        averageRating: 5.0,
        totalReviews: 0,
        latitude: latitude,
        longitude: longitude,
      );

      final Map<String, dynamic> dataToInsert = newUser.toMap();
      dataToInsert['role'] = currentRole;
      dataToInsert['average_rating'] = 5.0;
      dataToInsert['total_reviews'] = 0;

      // Address string format me save krwane k liye extra columns add kr skte hain bad me
      dataToInsert['latitude'] = latitude;
      dataToInsert['longitude'] = longitude;

      await supabase.from('users').upsert(dataToInsert);

      if (!mounted) return;

      if (currentRole == "Provider") {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ProviderDashboard(provider: newUser)),
                (route) => false
        );
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainWrapper(user: newUser)),
                (route) => false
        );
      }

    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Unexpected Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    bool isProvider = userRole == "Provider";
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create Account", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 30)),
            const SizedBox(height: 25),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[50],
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null ? Icon(Icons.person_add, size: 40, color: Colors.blue[200]) : null,
                    ),
                    Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Colors.blue[700], child: const Icon(Icons.camera_alt, size: 14, color: Colors.white))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(children: [
              _buildRoleOption("Customer", Icons.person_outline),
              const SizedBox(width: 15),
              _buildRoleOption("Provider", Icons.handyman_outlined),
            ]),
            const SizedBox(height: 25),
            _buildTextField(_nameController, "Full Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField(_emailController, "Email", Icons.email_outlined, isEmail: true),
            const SizedBox(height: 15),

            // --- Location Section (Sirf Provider k liye) ---
            if (isProvider) ...[
              const Text("Provider Location Setup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[800],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isFetchingLocation ? null : _autoFetchLocation,
                      icon: _isFetchingLocation
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      label: const Text("Auto GPS Location Pick"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_cityController, "City (e.g. Lahore)", Icons.location_city)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_addressController, "Area / Street Address", Icons.home_outlined)),
                ],
              ),
              const SizedBox(height: 15),

              _buildCategoryDropdown(),
              const SizedBox(height: 15),
              _buildTextField(_costController, "Hourly Rate (Rs.)", Icons.payments_outlined, isNumber: true),
              const SizedBox(height: 20),
              const Text("CNIC Photo (Private)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _cnicImage == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey), Text("Upload ID Photo")])
                      : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_cnicImage!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildTextField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
            const SizedBox(height: 15),
            _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock_reset, isObscure: true),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _handleSignUp,
                child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(String role, IconData icon) {
    bool isSelected = userRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => {
          userRole = role,
          // Role change krne par controllers clear ho jyen ge
          if(role == "Customer") {
            _cityController.clear(),
            _addressController.clear(),
            _detectedLatitude = "",
            _detectedLongitude = ""
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[700] : Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(height: 4),
            Text(role, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          isExpanded: true,
          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false, bool isNumber = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueGrey),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}