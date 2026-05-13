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
  final String currentUserId = supabase.auth.currentUser?.id ?? "";
  int refreshCounter = 0;

  void _forceRefresh() {
    setState(() {
      refreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          title: const Text("My Appointments",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: StreamBuilder<List<BookingModel>>(
          key: ValueKey(refreshCounter),
          stream: StorageService.getBookingsStream(currentUserId, false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

            final allBookings = snapshot.data ?? [];

            return TabBarView(
              children: [
                _buildBookingList(allBookings, ['pending']),
                // 'finished' yahan hona zaroori hai taake Customer rate kar sakay
                _buildBookingList(allBookings, ['accepted', 'finished']),
                _buildBookingList(allBookings, ['completed', 'cancelled', 'declined']),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> allBookings, List<String> targetStatuses) {
    final filtered = allBookings.where((b) {
      return targetStatuses.contains(b.status.toLowerCase());
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildBookingCard(filtered[index]),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    String status = booking.status.toLowerCase();
    bool isFinished = status == 'finished';
    bool isPending = status == 'pending';
    bool isHistory = status == 'completed' || status == 'cancelled' || status == 'declined';

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
                    child: Text(booking.provider.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ),
                _statusBadge(booking.status),
              ],
            ),
            subtitle: Text(booking.serviceName,
                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
          ),

          if (!isHistory)
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
                  if (isFinished || isPending) const SizedBox(width: 12),

                  if (isFinished)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showRatingDialog(context, booking),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text("Rate & Finish",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  if (isPending)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await StorageService.updateBookingStatus(booking.id, 'Cancelled');
                          _forceRefresh();
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

  void _showRatingDialog(BuildContext context, BookingModel booking) {
    double selectedRating = 5.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: const Text("Rate Service", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How was your experience?"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: isSubmitting
                        ? null
                        : () => setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.orange,
                      size: 40,
                    ),
                  );
                }),
              ),
              if (isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text("Skip")
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                setDialogState(() => isSubmitting = true);
                try {
                  // Customer rating bhej raha hai jo DB mein provider_rating column mein jayegi
                  await StorageService.completeAndRateTask(
                      booking: booking,
                      rating: selectedRating
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    _forceRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Job Completed Successfully!"),
                            backgroundColor: Colors.green
                        )
                    );
                  }
                } catch (e) {
                  print("Rating Submission Error: $e");
                  setDialogState(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
            : Image.network(
            booking.provider.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey)
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    String s = status.toLowerCase();
    Color color;
    if (s == 'accepted') color = Colors.blue;
    else if (s == 'finished') color = Colors.purple;
    else if (s == 'completed') color = Colors.green;
    else if (s == 'cancelled' || s == 'declined') color = Colors.red;
    else color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)
      ),
      child: Text(
          status.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildEmptyState() => const Center(
      child: Text("No appointments found", style: TextStyle(color: Colors.grey))
  );
}