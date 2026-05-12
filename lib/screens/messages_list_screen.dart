import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/models/message_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class MessagesListScreen extends StatefulWidget {
  final String providerId;

  const MessagesListScreen({super.key, required this.providerId});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Inbox",
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      // REAL-TIME BOOKINGS STREAM (Using our generic StorageService method)
      body: StreamBuilder<List<BookingModel>>(
        // isProvider = true kyunki provider inbox dekh raha hai
        stream: StorageService.getBookingsStream(widget.providerId, true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // Hum sirf un bookings ko dikhayenge jo Cancelled nahi hain
          final chatBookings = (snapshot.data ?? [])
              .where((b) => b.status != 'Cancelled')
              .toList();

          if (chatBookings.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: chatBookings.length,
            separatorBuilder: (context, index) => const Divider(height: 24, color: Colors.black12, indent: 70),
            itemBuilder: (context, index) {
              final booking = chatBookings[index];
              return _buildChatTile(context, booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, BookingModel booking) {
    // Last Message dikhane ke liye real-time chat stream
    return StreamBuilder<List<MessageModel>>(
      stream: StorageService.getChatStream(booking.id),
      builder: (context, snapshot) {
        String lastMsg = "Tap to start conversation";
        String time = "";

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          // Supabase se messages order ho kar aate hain, last one pick karein
          final lastMessageObj = snapshot.data!.last;
          if (lastMessageObj.type == MessageType.audio) {
            lastMsg = "🎤 Voice message";
          } else {
            lastMsg = lastMessageObj.content;
          }
          time = _getFormattedTime(lastMessageObj.timestamp);
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(booking: booking,isProvider: true,),
              ),
            );
          },
          onLongPress: () => _confirmDelete(context, booking),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        booking.customerName.isNotEmpty ? booking.customerName[0].toUpperCase() : "?",
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ),
                    if (booking.status == 'Accepted')
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(booking.customerName,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                          Text(time, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: lastMsg == "Tap to start conversation" ? Colors.blue.shade300 : Colors.grey.shade600,
                          fontWeight: lastMsg == "Tap to start conversation" ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFormattedTime(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day && now.month == date.month && now.year == date.year) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('MMM d').format(date);
  }

  void _confirmDelete(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Clear Chat?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text("Is customer ke sath honay wali tamaam baate'n delete ho jayengi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              try {
                // StorageService mein ye method bhi hona chahiye messages delete karne ke liye
                await supabase.from('messages').delete().eq('booking_id', booking.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat cleared!")));
                }
              } catch (e) {
                print("Delete Error: $e");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, elevation: 0),
            child: const Text("Clear", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 20),
          Text("Inbox is empty", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54)),
          const SizedBox(height: 8),
          Text("Active service chats will appear here.", style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}