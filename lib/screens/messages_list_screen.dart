import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/models/message_model.dart'; // Message type ke liye
import 'package:handyman_app/services/storage_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class MessagesListScreen extends StatefulWidget {
  final String providerId;

  const MessagesListScreen({super.key, required this.providerId});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  // Page refresh karne ke liye helper
  void _refresh() => setState(() {});

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
      body: FutureBuilder<List<BookingModel>>(
        future: StorageService.getBookingsForProvider(widget.providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final chatBookings = snapshot.data!
              .where((b) => b.status == 'Accepted' || b.status == 'Completed')
              .toList();

          if (chatBookings.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chatBookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    return StreamBuilder<List<MessageModel>>(
      stream: StorageService.getChatStream(booking.id),
      builder: (context, snapshot) {
        String lastMsg = "Tap to start chatting";
        String time = "";

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final lastMessageObj = snapshot.data!.last;
          if (lastMessageObj.type == MessageType.audio) {
            lastMsg = "🎤 Voice message";
          } else {
            lastMsg = lastMessageObj.content;
          }
          time = DateFormat('hh:mm a').format(lastMessageObj.timestamp);
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                booking.customerName[0].toUpperCase(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(booking.customerName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            subtitle: Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen(booking: booking, isProvider: true)),
              ).then((_) => _refresh());
            },
            // DELETE LOGIC ON LONG PRESS
            onLongPress: () => _confirmDelete(context, booking),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Delete Conversation?"),
        content: const Text("Ye chat aur iska poora record hamesha ke liye delete ho jaye ga. Kya aap sure hain?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              // AB YE POORI CONVERSATION URRAYE GA
              await StorageService.deleteFullConversation(booking.id);
              Navigator.pop(context);
              _refresh(); // List update ho jaye gi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Conversation deleted permanently"), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No messages yet", style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}