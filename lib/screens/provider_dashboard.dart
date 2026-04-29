import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'edit_profile_screen.dart';

class ProviderDashboard extends StatefulWidget {
  final ProviderModel provider;
  const ProviderDashboard({super.key, required this.provider});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  // Toggle State
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

  // Real Data Load karne ka function
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

  // --- Logic Functions ---
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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Edit Profile Icon
          IconButton(
              onPressed: _goToEditProfile,
              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 28)
          ),

          // --- REAL ONLINE/OFFLINE TOGGLE WITH TEXT ---
          Row(
            children: [
              Text(
                isOnline ? "Online" : "Offline",
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Switch(
                value: isOnline,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => isOnline = v),
              ),
            ],
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
              Text("Hi, ${currentProvider.name} 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Manage your services and bookings.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),

              _buildEarningsCard(),
              const SizedBox(height: 25),

              // Stats Row
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

  // --- UI Build Components ---

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [Colors.grey[800]!, Colors.grey[600]!], // Offline hone pe Grey
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: isOnline ? Colors.blue.withOpacity(0.3) : Colors.black12,
              blurRadius: 20,
              offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Earnings", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 5),
          Text("Rs. ${totalEarnings.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 30),
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
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 25, backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.person, color: Colors.blue)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(booking.serviceName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ])),
              Text("Rs.${booking.price}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => declineRequest(booking),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: const Text("Decline", style: TextStyle(color: Colors.red))
                  )
              ),
              const SizedBox(width: 15),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => acceptRequest(booking),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: const Text("Accept", style: TextStyle(color: Colors.white))
                  )
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.1))
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.bolt, color: Colors.green)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(booking.serviceName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          ElevatedButton(
              onPressed: () => completeJob(booking),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              child: const Text("Finish", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5)]
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
  ]);

  Widget _sectionHeader(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
  );

  Widget _emptyState(String msg) => Center(
      child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 15))
      )
  );
}