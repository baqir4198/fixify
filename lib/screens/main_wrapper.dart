import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart'; // Model import lazmi hai
import 'package:handyman_app/screens/home_screen.dart';
import 'package:handyman_app/screens/my_bookings_screen.dart';
import 'package:handyman_app/screens/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  final ProviderModel user; // 1. User data receive karne ke liye variable
  const MainWrapper({super.key, required this.user}); // 2. Constructor update kiya

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // 3. Pages ko late list banaya taake widget.user ko use kar sakein
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 4. Screens ko widget.user pass kar diya
    _pages = [
      HomeScreen(user: widget.user), // Home ko user pass kiya
      const MyBookingsScreen(),
      ProfileScreen(user: widget.user), // Profile ko user pass kiya
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            )
          ],
        ),
      ),
    );
  }
}