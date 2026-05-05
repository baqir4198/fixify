import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'edit_profile_screen.dart';
import 'chat_screen.dart';
import 'messages_list_screen.dart';

class ProviderDashboard extends StatefulWidget {
  final ProviderModel provider;
  const ProviderDashboard({super.key, required this.provider});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  bool isOnline = true;
  double totalEarnings = 0.0;
  int jobsDone = 0;
  late ProviderModel currentProvider;

  List<BookingModel> newRequests = [];
  List<BookingModel> activeJobs = [];

  @override
  void initState() {
    super.initState();
    currentProvider = widget.provider;
    _loadRealRequests();
  }

  Future<void> _loadRealRequests() async {
    final allBookings = await StorageService.getBookingsForProvider(currentProvider.id);
    setState(() {
      newRequests = allBookings.where((b) => b.status == 'Pending').toList();
      activeJobs = allBookings.where((b) => b.status == 'Accepted').toList();
      final completed = allBookings.where((b) => b.status == 'Completed').toList();
      jobsDone = completed.length;
      totalEarnings = completed.fold(0, (sum, item) => sum + (double.tryParse(item.price) ?? 0));
    });
  }

  void _goToEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: currentProvider)),
    );
    if (updated == true) {
      final allUsers = await StorageService.getSavedProviders();
      setState(() {
        currentProvider = allUsers.firstWhere((u) => u.id == currentProvider.id);
      });
      await _loadRealRequests();
    }
  }

  void acceptRequest(BookingModel booking) async {
    await StorageService.updateBookingStatus(booking.id, 'Accepted');
    _showSnackBar("Job Accepted!", Colors.blue);
    _loadRealRequests();
  }

  void completeJob(BookingModel booking) async {
    await StorageService.updateBookingStatus(booking.id, 'Completed');
    _showSnackBar("Job Completed! Earnings updated.", Colors.green);
    _loadRealRequests();
  }

  void declineRequest(BookingModel booking) async {
    await StorageService.deleteBooking(booking.id);
    _showSnackBar("Request Declined.", Colors.red);
    _loadRealRequests();
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Dashboard",
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesListScreen(providerId: currentProvider.id))),
            icon: const Icon(Icons.mail_outline_rounded, color: Colors.blue, size: 26),
          ),
          IconButton(
              onPressed: _goToEditProfile,
              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 28)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRealRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildProfileAvatar(currentProvider.imageUrl, currentProvider.name),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi, ${currentProvider.name} 👋",
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        Text(currentProvider.profession,
                            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: isOnline,
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => isOnline = v),
                      ),
                      Text(isOnline ? "Online" : "Offline",
                          style: GoogleFonts.inter(color: isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              _buildEarningsCard(),
              const SizedBox(height: 25),

              Row(
                children: [
                  _buildSmallStatCard("Pending", "${newRequests.length}", Icons.pending_actions, Colors.orange),
                  const SizedBox(width: 15),
                  _buildSmallStatCard("Active", "${activeJobs.length}", Icons.directions_run, Colors.green),
                ],
              ),

              const SizedBox(height: 30),
              _sectionHeader("New Requests"),
              if (newRequests.isEmpty) _emptyState("No new requests found")
              else ...newRequests.map((b) => _buildRequestCard(b)),

              const SizedBox(height: 30),
              _sectionHeader("Active Work"),
              if (activeJobs.isEmpty) _emptyState("No active jobs right now")
              else ...activeJobs.map((b) => _buildActiveJobCard(b)),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String? imageUrl, String name) {
    // Check if the image is valid and not the default pravatar
    bool hasImage = imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.contains("pravatar.cc");

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
        child: !hasImage
            ? Text(name[0].toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800))
            : null,
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOnline
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [Colors.grey[800]!, Colors.grey[600]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isOnline ? Colors.blue.withOpacity(0.3) : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Earnings", style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("Rs. ${totalEarnings.toInt()}",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat("Jobs Done", "$jobsDone"),
              _miniStat("Rating", "${currentProvider.rating} ★"),
              _miniStat("Rate/hr", "Rs.${currentProvider.pricePerHour.toInt()}"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRequestCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFF0F7FF), child: Icon(Icons.person_outline, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(booking.serviceName, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
              ])),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(booking: booking, isProvider: true))),
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blue, size: 22),
              ),
              Text("Rs.${booking.price}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => declineRequest(booking),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: Text("Decline", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600)))
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => acceptRequest(booking),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: Text("Accept", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)))
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFF0FFF4), child: Icon(Icons.bolt_rounded, color: Colors.green, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(booking.serviceName, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
          ])),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(booking: booking, isProvider: true))),
            icon: const Icon(Icons.message_outlined, color: Colors.blue, size: 20),
          ),
          ElevatedButton(
              onPressed: () => completeJob(booking),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16)
              ),
              child: Text("Finish", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
          ])
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
    Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
  ]);

  Widget _sectionHeader(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5))
  );

  Widget _emptyState(String msg) => Center(
      child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(msg, style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500))
      )
  );
}