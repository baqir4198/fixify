import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // --- Distance nikalne k liye package ---
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/provider_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

final supabase = Supabase.instance.client;

class ProviderListScreen extends StatefulWidget {
  final String categoryName;
  // --- HomeScreen se bhejay gaye coordinates accept krne k liye variables ---
  final double? customerLatitude;
  final double? customerLongitude;

  const ProviderListScreen({
    super.key,
    required this.categoryName,
    this.customerLatitude,
    this.customerLongitude,
  });

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  String _searchQuery = "";
  String _activeSort = "Distance"; // Default sort ab Distance pr set kr dia h

  // Helper function: Distance calculation k liye (Safe Version)
  double _calculateDistance(double providerLat, double providerLng) {
    final double? lat = widget.customerLatitude;
    final double? lng = widget.customerLongitude;

    if (lat == null || lng == null || (providerLat == 0.0 && providerLng == 0.0)) {
      return -1.0;
    }

    double distanceInMeters = Geolocator.distanceBetween(
      lat,
      lng,
      providerLat,
      providerLng,
    );
    return distanceInMeters / 1000; // Kilometers me convert kia
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${widget.categoryName} Experts",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search experts...",
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSortChip("Distance", Icons.location_on_rounded),
                      const SizedBox(width: 10),
                      _buildSortChip("Rating", Icons.star_rounded),
                      const SizedBox(width: 10),
                      _buildSortChip("Price", Icons.payments_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('users').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Unable to load providers."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allData = snapshot.data ?? [];

          // --- SMART & PAKKA FILTER ---
          List<ProviderModel> providers = allData
              .map((map) => ProviderModel.fromMap(map))
              .where((p) {
            String providerProf = p.profession.trim().toLowerCase();
            String categoryProf = widget.categoryName.trim().toLowerCase();

            return providerProf == categoryProf ||
                providerProf.contains(categoryProf) ||
                categoryProf.contains(providerProf);
          }).toList();

          if (_searchQuery.isNotEmpty) {
            providers = providers.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
          }

          // --- ADVANCED SORTING (Distance, Price, Rating) ---
          if (_activeSort == "Price") {
            providers.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          } else if (_activeSort == "Rating") {
            providers.sort((a, b) => b.averageRating.compareTo(a.averageRating));
          } else {
            // Distance sorting logic
            providers.sort((a, b) {
              double distA = _calculateDistance(a.latitude ?? 0.0, a.longitude ?? 0.0);
              double distB = _calculateDistance(b.latitude ?? 0.0, b.longitude ?? 0.0);
              if (distA == -1.0) return 1;
              if (distB == -1.0) return -1;
              return distA.compareTo(distB);
            });
          }

          if (providers.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            itemCount: providers.length,
            itemBuilder: (context, index) => _buildProviderCard(providers[index]),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(String label, IconData icon) {
    bool isSelected = _activeSort == label;
    return GestureDetector(
      onTap: () => setState(() => _activeSort = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel provider) {
    bool isNew = provider.totalReviews < 3;
    double distance = _calculateDistance(provider.latitude ?? 0.0, provider.longitude ?? 0.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDetailScreen(
          provider: provider,
          customerLatitude: widget.customerLatitude,  // Jo List Screen par aaya tha
          customerLongitude: widget.customerLongitude,
        ))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: provider.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _buildProfileImage(provider.imageUrl, provider.name),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                            isNew ? "New" : provider.averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)
                        ),
                        const SizedBox(width: 8),

                        // --- LIVE DISTANCE TAG ---
                        if (distance != -1.0)
                          Text(
                            "• ${distance.toStringAsFixed(1)} km away",
                            style: TextStyle(color: Colors.blueGrey[600], fontSize: 12, fontWeight: FontWeight.w600),
                          )
                        else
                          Text(
                            "• Location N/A",
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("PKR ${provider.pricePerHour.toInt()}/hr",
                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w800, fontSize: 15)),

                        Text("Verified Expert", style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String url, String name) {
    return SizedBox(
      width: 70, height: 70,
      child: url.isEmpty || !url.startsWith('http')
          ? Container(
        color: Colors.blue.shade50,
        child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.blueAccent, fontSize: 24, fontWeight: FontWeight.bold))),
      )
          : Image.network(url, fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (c, e, s) => const Icon(Icons.person, size: 30, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.person_search_rounded, size: 60, color: Colors.blue.shade200),
          ),
          const SizedBox(height: 20),
          Text("No ${widget.categoryName} Experts Found",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text("Try searching with a different name or check back later.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}