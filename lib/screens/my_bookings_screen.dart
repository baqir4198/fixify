import 'dart:io';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {

  // Ab setState ki zaroorat nahi padegi refresh ke liye, lekin function rakh lete hain compatibility ke liye
  Future<void> _refreshBookings() async {
    setState(() {});
  }

  // --- Rating Dialog Function (Same as before) ---
  void _showRatingDialog(BuildContext context, BookingModel booking) {
    double selectedRating = 5.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rate Service", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How was your experience with", textAlign: TextAlign.center),
            Text(booking.provider.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 20),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.orange,
                      size: 35,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Skip", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await StorageService.updateBookingStatus(booking.id, 'Completed');
              await StorageService.updateProviderRating(booking.provider.id, selectedRating);
              if (!mounted) return;
              Navigator.pop(context);
              // Refresh karne ki zaroorat nahi, Stream khud hi detect kar legi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thanks for your feedback!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("My Appointments", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        // --- STREAMBUILDER LOGIC YAHAN HAI ---
        body: StreamBuilder<List<BookingModel>>(
          stream: StorageService.getBookingsStream(), // Naya Stream function use ho raha hai
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.blue));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final allBookings = snapshot.data ?? [];

            return TabBarView(
              children: [
                _buildBookingList(allBookings, 'Pending'),
                _buildBookingList(allBookings, 'Accepted'),
                _buildBookingList(allBookings, 'Completed'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> allBookings, String status) {
    final filteredBookings = allBookings.where((b) => b.status == status).toList();

    if (filteredBookings.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return Dismissible(
          key: Key(booking.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) async {
            await StorageService.deleteBooking(booking.id);
          },
          child: _buildProfessionalBookingCard(booking),
        );
      },
    );
  }

  Widget _buildProfessionalBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: booking.provider.imageUrl.startsWith('http')
                      ? Image.network(booking.provider.imageUrl, width: 70, height: 70, fit: BoxFit.cover)
                      : Image.file(File(booking.provider.imageUrl), width: 70, height: 70, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.blue[50], child: const Icon(Icons.person, color: Colors.blue))),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Provider Name
                          Expanded(
                            child: Text(
                              booking.provider.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // --- CHAT ICON ADDED HERE ---
                          if (booking.status == 'Pending' || booking.status == 'Accepted')
                            IconButton(
                              onPressed: () {
                                // TODO: Navigate to ChatScreen
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(booking: booking)));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Opening chat with ${booking.provider.name}...")),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blue, size: 22),
                              constraints: const BoxConstraints(), // Padding kam karne ke liye
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),

                          _buildStatusBadge(booking.status),
                        ],
                      ),
                      Text(booking.provider.profession, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(DateFormat('EEE, MMM d').format(booking.date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time_filled, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(booking.time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.status != 'Completed' && booking.status != 'Cancelled') ...[
              const Divider(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (booking.status == 'Pending')
                    TextButton.icon(
                      onPressed: () async {
                        await StorageService.updateBookingStatus(booking.id, 'Cancelled');
                      },
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      label: const Text("Cancel", style: TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(width: 10),
                  if (booking.status == 'Accepted')
                    ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(context, booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      label: const Text("Complete & Rate", style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'Completed': badgeColor = Colors.green; break;
      case 'Accepted': badgeColor = Colors.blue; break;
      case 'Cancelled': badgeColor = Colors.red; break;
      default: badgeColor = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text("No $status bookings", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          Text("Your $status requests will appear here", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}