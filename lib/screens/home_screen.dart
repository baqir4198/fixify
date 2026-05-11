import 'package:flutter/material.dart';
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
  // Static Categories list (Icons aur Colors ke liye hum yehi use karenge)
  final List<ServiceModel> categories = [
    ServiceModel(id: '1', name: 'Plumbing', icon: Icons.plumbing, color: Colors.blue),
    ServiceModel(id: '2', name: 'Electrical', icon: Icons.electrical_services, color: Colors.orange),
    ServiceModel(id: '3', name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.green),
    ServiceModel(id: '4', name: 'Painting', icon: Icons.format_paint, color: Colors.purple),
    ServiceModel(id: '5', name: 'Carpentry', icon: Icons.carpenter, color: Colors.brown),
    ServiceModel(id: '6', name: 'AC Repair', icon: Icons.ac_unit, color: Colors.cyan)
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Safely handling name parsing
    String firstName = widget.user.name.split(' ').first;

    // Search filter logic
    final filteredCategories = categories
        .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Header with Notification Badge
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

                  // Search Bar with enhanced UI
                  _buildSearchBar(),

                  const SizedBox(height: 25),

                  // Interactive Discount Card
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

          // Dynamic Grid View
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
                            builder: (context) => ProviderListScreen(categoryName: service.name)
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