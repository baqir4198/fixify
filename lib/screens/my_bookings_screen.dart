import 'dart:io';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

final supabase = Supabase.instance.client;

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // Supabase current user ID (UUID format)
  final String currentUserId = supabase.auth.currentUser?.id ?? "";

  void _showRatingDialog(BuildContext context, BookingModel booking) {
    double selectedRating = 5.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Rate the Experience",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How was your service from", textAlign: TextAlign.center),
            Text(booking.provider.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 20),
            StatefulBuilder(
              builder: (context, setDialogState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.orange,
                      size: 40,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Skip", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () async {
              try {
                // StorageService mein method updateBookingStatus use ho raha hai
                await StorageService.updateBookingStatus(booking.id, 'Completed');
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Feedback submitted! Job completed."))
                  );
                }
              } catch (e) {
                print("Error completing booking: $e");
              }
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
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          title: const Text("My Appointments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey[400],
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: Colors.blue),
              insets: EdgeInsets.symmetric(horizontal: 20),
            ),
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: StreamBuilder<List<BookingModel>>(
          // StorageService.getBookingsStream ab UUID ke liye generic hai
          // isProvider = false kyunki ye Customer ki screen hai
          stream: StorageService.getBookingsStream(currentUserId, false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

            final allBookings = snapshot.data ?? [];

            return TabBarView(
              children: [
                _buildBookingList(allBookings, 'Pending'),
                _buildBookingList(allBookings, 'Accepted'),
                _buildBookingList(allBookings, ['Completed', 'Cancelled']),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> allBookings, dynamic status) {
    final filtered = allBookings.where((b) {
      if (status is List) return status.contains(b.status);
      return b.status == status;
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildBookingCard(filtered[index]),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: _buildAvatar(booking),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(
                        booking.provider.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    )
                ),
                _statusBadge(booking.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    booking.serviceName,
                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(DateFormat('MMM d, yyyy').format(booking.date),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 15),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(booking.time, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Buttons logic (Chat, Complete, Cancel)
          if (booking.status == 'Accepted' || booking.status == 'Pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen(booking: booking))
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text("Message"),
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (booking.status == 'Accepted')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showRatingDialog(context, booking),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text("Complete", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  if (booking.status == 'Pending')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await StorageService.updateBookingStatus(booking.id, 'Cancelled');
                        },
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BookingModel booking) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.blue[50]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: booking.provider.imageUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.blue, size: 30)
            : (booking.provider.imageUrl.startsWith('http')
            ? Image.network(
          booking.provider.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
        )
            : Image.file(
          File(booking.provider.imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
        )),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == 'Accepted' ? Colors.blue : (status == 'Completed' ? Colors.green : Colors.orange);
    if (status == 'Cancelled') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("No appointments found", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}