import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore integration
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/provider_detail_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final String categoryName;
  const ProviderListScreen({super.key, required this.categoryName});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  String _searchQuery = "";
  String _activeSort = "Rating"; // Default sort by rating

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("${widget.categoryName} Experts",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search by name...",
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Sort Chips
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSortChip("Rating", Icons.star_rounded),
                    const SizedBox(width: 12),
                    _buildSortChip("Price", Icons.payments_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Real-time Database Stream
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('profession', isEqualTo: widget.categoryName) // Database level filtering
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Data conversion from Firestore
          List<ProviderModel> providers = snapshot.data!.docs.map((doc) {
            return ProviderModel.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Client-side Filter (Search)
          if (_searchQuery.isNotEmpty) {
            providers = providers.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
          }

          // Client-side Sort
          if (_activeSort == "Price") {
            providers.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
          } else {
            providers.sort((a, b) => b.rating.compareTo(a.rating));
          }

          if (providers.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: providers.length,
            itemBuilder: (context, index) => _buildProviderCard(providers[index]),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(String label, IconData icon) {
    bool isSelected = _activeSort == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) { if(val) setState(() => _activeSort = label); },
      selectedColor: Colors.blue[100],
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.blue : Colors.grey),
      labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildProviderCard(ProviderModel provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDetailScreen(provider: provider))),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _buildProfileImage(provider.imageUrl, provider.name),
        ),
        title: Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 16),
                Text(" ${provider.rating} • 5+ Years Exp", style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text("Rs. ${provider.pricePerHour.toInt()}/hr",
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildProfileImage(String url, String name) {
    return SizedBox(
      width: 70, height: 70,
      child: url.isEmpty
          ? Container(
        color: Colors.blue[600],
        child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
      )
          : (url.startsWith('http')
          ? Image.network(url, fit: BoxFit.cover)
          : Image.file(File(url), fit: BoxFit.cover)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No ${widget.categoryName}s available right now.",
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}