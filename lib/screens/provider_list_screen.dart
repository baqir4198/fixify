import 'dart:io';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/provider_detail_screen.dart';
import 'package:handyman_app/services/storage_service.dart';

class ProviderListScreen extends StatefulWidget {
  final String categoryName;
  const ProviderListScreen({super.key, required this.categoryName});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  List<ProviderModel> allProviders = [];
  List<ProviderModel> displayedProviders = [];
  bool isLoading = true;
  String activeSort = "";

  @override
  void initState() {
    super.initState();
    _loadAllProviders();
  }

  Future<void> _loadAllProviders() async {
    setState(() => isLoading = true);
    final savedUsers = await StorageService.getSavedProviders();

    setState(() {
      allProviders = savedUsers.where((p) {
        if (p.profession == "Customer") return false;
        String category = widget.categoryName.toLowerCase().trim();
        String prof = p.profession.toLowerCase().trim();
        bool match = prof.contains(category) || category.contains(prof);
        if (!match && prof.length >= 4 && category.length >= 4) {
          match = prof.substring(0, 4) == category.substring(0, 4);
        }
        return match;
      }).toList();

      displayedProviders = allProviders;
      isLoading = false;
    });
  }

  void _runFilter(String enteredKeyword) {
    List<ProviderModel> results = [];
    if (enteredKeyword.isEmpty) {
      results = allProviders;
    } else {
      results = allProviders
          .where((user) => user.name.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      displayedProviders = results;
    });
  }

  void _sortProviders(String criteria) {
    setState(() {
      activeSort = criteria;
      if (criteria == "Price") {
        displayedProviders.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
      } else if (criteria == "Rating") {
        displayedProviders.sort((a, b) => b.rating.compareTo(a.rating));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text("${widget.categoryName} Experts", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (value) => _runFilter(value),
                  decoration: InputDecoration(
                    hintText: "Search by name...",
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip("Price", Icons.sort_rounded, "Cheapest"),
                      const SizedBox(width: 10),
                      _buildFilterChip("Rating", Icons.star_rounded, "Top Rated"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayedProviders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: displayedProviders.length,
        itemBuilder: (context, index) {
          final person = displayedProviders[index];
          return _buildModernProviderCard(context, person);
        },
      ),
    );
  }

  Widget _buildFilterChip(String criteria, IconData icon, String label) {
    bool isSelected = activeSort == criteria;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _sortProviders(criteria),
      selectedColor: Colors.blue.withOpacity(0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.black54,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.blue : Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildModernProviderCard(BuildContext context, ProviderModel provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProviderDetailScreen(provider: provider)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image Section
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _buildProfileImage(provider.imageUrl, provider.name),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(provider.profession, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        Text(" ${provider.rating}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 15),
                        const Icon(Icons.verified, color: Colors.green, size: 16),
                        const Text(" Verified", style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text("Rs. ${provider.pricePerHour.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const Text("/hr", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NAYA LOGIC: Initials agar image na ho ---
  Widget _buildProfileImage(String url, String name) {
    if (url.isEmpty) {
      return _buildInitialsPlaceholder(name);
    }

    return url.startsWith('http')
        ? Image.network(
      url,
      width: 85, height: 85, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildInitialsPlaceholder(name),
    )
        : Image.file(
      File(url),
      width: 85, height: 85, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildInitialsPlaceholder(name),
    );
  }

  Widget _buildInitialsPlaceholder(String name) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No results found for ${widget.categoryName}", style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
          const Text("Try checking other categories!", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}