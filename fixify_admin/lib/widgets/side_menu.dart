import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B), // Premium Dark Slate Color
      child: Column(
        children: [
          const SizedBox(height: 30),
          // App Logo / Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_rounded, color: Colors.blue, size: 30),
              const SizedBox(width: 10),
              const Text(
                "Fixify Admin",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),

          // Menu Items
          _menuTile(index: 0, title: "Overview Dashboard", icon: Icons.dashboard_rounded),
          _menuTile(index: 1, title: "Service Providers", icon: Icons.engineering_rounded),
          _menuTile(index: 2, title: "Customers List", icon: Icons.people_alt_rounded),
          _menuTile(index: 3, title: "Bookings & Jobs", icon: Icons.assignment_rounded),
          _menuTile(index: 4, title: "Manage Categories", icon: Icons.category_rounded),

          const Spacer(),
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              // Idhar baad mein Supabase signout laga denge
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuTile({required int index, required String title, required IconData icon}) {
    bool isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        selected: isSelected,
        selectedColor: Colors.blue,
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey.shade400),
        title: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.blue : Colors.grey.shade300, fontSize: 14),
        ),
        onTap: () => onTabSelected(index),
      ),
    );
  }
}