import 'dart:io';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  Future<void> _refreshBookings() async {
    setState(() {});
  }

  // --- NEW: Rating Dialog Function ---
  void _showRatingDialog(BuildContext context, BookingModel booking) {
    double selectedRating = 5.0; // Default stars

    showDialog(
      context: context,
      barrierDismissible: false, // User ko submit ya skip karna hi parega
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rate Service", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How was your experience with", textAlign: TextAlign.center),
            Text(booking.provider.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 20),

            // Star Selection Logic
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
              // 1. Update Booking Status
              await StorageService.updateBookingStatus(booking.id, 'Completed');
              // 2. Update Provider's Rating in Storage
              await StorageService.updateProviderRating(booking.provider.id, selectedRating);

              if (!mounted) return;
              Navigator.pop(context);
              _refreshBookings(); // Refresh UI

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Appointments", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBookings,
        child: FutureBuilder<List<BookingModel>>(
          future: StorageService.getBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.blue));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final bookings = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Dismissible(
                    key: Key(booking.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await StorageService.deleteBooking(booking.id);
                    },
                    child: _buildProfessionalBookingCard(booking),
                  );
                },
              );
            }
            return _buildEmptyState();
          },
        ),
      ),
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
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.blue[50], child: const Icon(Icons.person, color: Colors.blue))),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(booking.provider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          _buildStatusBadge(booking.status),
                        ],
                      ),
                      Text(booking.provider.profession, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_month, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(DateFormat('EEE, MMM d').format(booking.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 15),
                          Icon(Icons.access_time_filled, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(booking.time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Action Buttons (Logic Updated) ---
            if (booking.status == 'Pending') ...[
              const Divider(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await StorageService.updateBookingStatus(booking.id, 'Cancelled');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    label: const Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Status direct update karne ki bajaye Dialog dikhayenge
                      _showRatingDialog(context, booking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text("Complete", style: TextStyle(color: Colors.white)),
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
      case 'Cancelled': badgeColor = Colors.red; break;
      default: badgeColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              const Text("No active bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}