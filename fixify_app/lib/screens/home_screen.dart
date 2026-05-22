import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/provider_list_screen.dart';
import 'package:handyman_app/widgets/category_card.dart';
import '../models/service_model.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final ProviderModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ServiceModel> categories = [
    ServiceModel(id: '1', name: 'Plumbing', icon: Icons.plumbing, color: Colors.blue),
    ServiceModel(id: '2', name: 'Electrician', icon: Icons.electrical_services, color: Colors.orange),
    ServiceModel(id: '3', name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.green),
    ServiceModel(id: '4', name: 'Painting', icon: Icons.format_paint, color: Colors.purple),
    ServiceModel(id: '5', name: 'Carpentry', icon: Icons.carpenter, color: Colors.brown),
    ServiceModel(id: '6', name: 'AC Repair', icon: Icons.ac_unit, color: Colors.cyan)
  ];

  String searchQuery = "";

  String currentAddress = "Fetching location...";
  double? customerLat;
  double? customerLng;

  @override
  void initState() {
    super.initState();
    _getCustomerLocation();
  }


  void _showGpsDialog(String title, String message, bool isOpenLocationSettings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.location_off_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (isOpenLocationSettings) {
                  await Geolocator.openLocationSettings();
                } else {
                  await Geolocator.openAppSettings();
                }
                _getCustomerLocation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                isOpenLocationSettings ? "Turn On GPS" : "Grant Permission",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _getCustomerLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => currentAddress = "GPS is off");
        _showGpsDialog(
            "GPS is Disabled",
            "Your mobile GPS is turned off. Please enable it to find the nearest handymen and experts around you.",
            true
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => currentAddress = "Permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => currentAddress = "Permission blocked");
        _showGpsDialog(
            "Location Permission",
            "Location access is permanently blocked. Please enable it from application settings to proceed.",
            false
        );
        return;
      }


      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      customerLat = position.latitude;
      customerLng = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          currentAddress = "${place.subLocality ?? place.street ?? ''}, ${place.locality ?? ''}".trim();
          if (currentAddress.startsWith(',')) {
            currentAddress = currentAddress.substring(1).trim();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching customer location: $e");
      setState(() => currentAddress = "Location not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    String firstName = widget.user.name.split(' ').first;

    final filteredCategories = categories
        .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 80,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Fixify',
              style: GoogleFonts.poppins(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 26
              ),
            ),
            actions: [
              _buildNotificationIcon(),
              const SizedBox(width: 15),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  _buildLocationHeader(),

                  const SizedBox(height: 15),
                  Text("Hello, $firstName! 👋",
                      style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text("What do you need\nfixed today?",
                      style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: Colors.black87
                      )),

                  const SizedBox(height: 25),

                  _buildSearchBar(),

                  const SizedBox(height: 25),

                  _buildDiscountBanner(),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Popular Services",
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                          onPressed: () {},
                          child: Text("See All", style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600))
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: filteredCategories.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text("No service found for '$searchQuery'",
                          style: GoogleFonts.inter(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
                : SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final service = filteredCategories[index];
                  return CategoryCard(
                    service: service,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProviderListScreen(
                              categoryName: service.name,
                              customerLatitude: customerLat,
                              customerLongitude: customerLng,
                            )
                        ),
                      );
                    },
                  );
                },
                childCount: filteredCategories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return GestureDetector(
      onTap: () {

        _getCustomerLocation();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue[50]?.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, color: Colors.blue[700], size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                currentAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 28),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10)
          )
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: "Try 'Plumber' or 'AC Repair'...",
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildDiscountBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("30% OFF",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                const Text("On your first home service",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Claim Coupon", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const Icon(Icons.stars_rounded, size: 85, color: Colors.white24),
        ],
      ),
    );
  }
}