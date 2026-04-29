import 'package:flutter/material.dart';
import 'package:handyman_app/screens/provider_list_screen.dart';
import 'package:handyman_app/widgets/category_card.dart';
import 'package:handyman_app/services/storage_service.dart'; // Storage Service add kiya
import '../models/service_model.dart';

class HomeScreen extends StatefulWidget { // Ise StatefulWidget kar diya taake naam load ho sakay
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";

  final List<ServiceModel> categories = [
    ServiceModel(id: '1', name: 'Plumbing', icon: Icons.plumbing, color: Colors.blue),
    ServiceModel(id: '2', name: 'Electrical', icon: Icons.electrical_services, color: Colors.orange),
    ServiceModel(id: '3', name: 'Cleaning', icon: Icons.cleaning_services, color: Colors.green),
    ServiceModel(id: '4', name: 'Painting', icon: Icons.format_paint, color: Colors.purple),
    ServiceModel(id: '5', name: 'Carpentry', icon: Icons.carpenter, color: Colors.brown),
    ServiceModel(id: '6', name: 'AC Repair', icon: Icons.ac_unit, color: Colors.cyan)
  ];

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  // --- Login user ka naam load karne ke liye ---
  Future<void> _loadName() async {
    final users = await StorageService.getSavedProviders();
    if (users.isNotEmpty) {
      setState(() {
        // Last register/login user ka naam uthaya
        userName = users.last.name.split(' ')[0]; // Sirf First Name dikhane ke liye
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              title: const Text(
                'HandyMan',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $userName! 👋", // Ab asli naam ayega
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "What service do\nyou need today?",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "Search for services...",
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.blueAccent],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("30% OFF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                              Text("On your first home cleaning", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Book Now"),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "All Categories",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final service = categories[index];
                  return CategoryCard(
                    service: service,
                    onTap: () {
                      // Yahan se hum category name bhej rahe hain
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderListScreen(categoryName: service.name),
                        ),
                      );
                    },
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}