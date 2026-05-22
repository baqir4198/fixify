import 'package:flutter/material.dart';
import '../responsive/responsive_layout.dart';
import '../widgets/side_menu.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentTabIndex = 0;

  // Idhar hum saari screens ki list banayein ge jise switch karna hai
  final List<Widget> _pages = [
    const Center(child: Text("Screen 1: Overview Dashboard", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Screen 2: Service Providers", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Screen 3: Customers", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Screen 4: Bookings", style: TextStyle(fontSize: 24))),
    const Center(child: Text("Screen 5: Categories", style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mobile View ke liye Drawer lagaya hai
      drawer: Drawer(
        child: SideMenu(
          selectedIndex: _currentTabIndex,
          onTabSelected: (index) {
            setState(() => _currentTabIndex = index);
            Navigator.pop(context); // Menu select hote hi mobile drawer close ho jaye
          },
        ),
      ),
      body: ResponsiveLayout(
        // 📱 MOBILE BODY
        mobileBody: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            iconTheme: const IconThemeData(color: Colors.black),
            title: const Text("Fixify Control Room", style: TextStyle(color: Colors.black, fontSize: 16)),
          ),
          body: _pages[_currentTabIndex],
        ),

        // 🖥️ DESKTOP BODY
        desktopBody: Row(
          children: [
            // Left Sidebar fixed wide screen par
            SizedBox(
              width: 260,
              child: SideMenu(
                selectedIndex: _currentTabIndex,
                onTabSelected: (index) {
                  setState(() => _currentTabIndex = index);
                },
              ),
            ),
            // Right Dynamic Content Area
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: _pages[_currentTabIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}