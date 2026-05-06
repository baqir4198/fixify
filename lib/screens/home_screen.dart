import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/provider_list_screen.dart';
import 'package:handyman_app/widgets/category_card.dart';
import '../models/service_model.dart';
import 'package:google_fonts/google_fonts.dart'; // Styling ke liye

class HomeScreen extends StatefulWidget {
  final ProviderModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Categories List
  final List<ServiceModel> categories = [
    ServiceModel(id: '1', name: 'Plumbing', icon: Icons.plumbing, color: Colors.blue),
    ServiceModel(id: '2', name: 'Electrical', icon: Icons.electrical_services, color: Colors.orange),
    ServiceModel(id: '3', name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.green),
    ServiceModel(id: '4', name: 'Painting', icon: Icons.format_paint, color: Colors.purple),
    ServiceModel(id: '5', name: 'Carpentry', icon: Icons.carpenter, color: Colors.brown),
    ServiceModel(id: '6', name: 'AC Repair', icon: Icons.ac_unit, color: Colors.cyan)
  ];

  // Search Logic ke liye
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    String firstName = widget.user.name.split(' ')[0];

    // Search filter logic
    final filteredCategories = categories
        .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Custom Header
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 80,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Fixify', // App ka naam update kiya
              style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 24),
            ),
            actions: [
              Stack(
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
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 10),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text("Hello, $firstName! 👋", style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text("What do you need\nfixed today?",
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2, color: Colors.black87)),

                  const SizedBox(height: 25),

                  // Functional Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: "Search for services (e.g. AC, Plumber)",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded, color: Colors.blueAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Premium Discount Card
                  _buildDiscountBanner(),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Services", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, child: const Text("See All")),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Grid View
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: filteredCategories.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: Text("No service found!")))
                : SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final service = filteredCategories[index];
                  return CategoryCard(
                    service: service,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProviderListScreen(categoryName: service.name)),
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

  Widget _buildDiscountBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
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
                const Text("30% OFF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                const Text("First Home Service", style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Claim Now", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          // Aap yahan koi service related image ya icon dal sakte hain
          const Icon(Icons.cleaning_services_rounded, size: 80, color: Colors.white24),
        ],
      ),
    );
  }
}