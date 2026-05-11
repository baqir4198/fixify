import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/home_screen.dart';
import 'package:handyman_app/screens/profile_screen.dart';
import 'package:handyman_app/screens/messages_list_screen.dart';
import 'my_bookings_screen.dart';

class MainWrapper extends StatefulWidget {
  final ProviderModel user;
  const MainWrapper({super.key, required this.user});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Pages ko list ke bajaye function se lein taake data hamesha fresh rahe
  List<Widget> _getPages() {
    return [
      HomeScreen(user: widget.user),
      const MyBookingsScreen(),
      MessagesListScreen(providerId: widget.user.id),
      ProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // build ke andar pages ko call karein
    final pages = _getPages();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -2),
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
          unselectedItemColor: Colors.blueGrey.shade300,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined, size: 26),
              activeIcon: Icon(Icons.explore, size: 26),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined, size: 26),
              activeIcon: Icon(Icons.calendar_month, size: 26),
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 26),
              activeIcon: Icon(Icons.chat_bubble_rounded, size: 26),
              label: "Messages",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 26),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}