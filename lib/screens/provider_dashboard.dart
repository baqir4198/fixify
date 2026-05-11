import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'edit_profile_screen.dart';
import 'messages_list_screen.dart'; // Ab isay uncomment kar diya hai

final supabase = Supabase.instance.client;

class ProviderDashboard extends StatefulWidget {
  final ProviderModel provider;
  const ProviderDashboard({super.key, required this.provider});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  bool isOnline = true;
  late ProviderModel currentProvider;

  @override
  void initState() {
    super.initState();
    currentProvider = widget.provider;
  }

  void acceptRequest(BookingModel booking) async {
    await StorageService.updateBookingStatus(booking.id, 'Accepted');
    _showSnackBar("Job Accepted!", Colors.blue);
  }

  void completeJob(BookingModel booking) async {
    await StorageService.updateBookingStatus(booking.id, 'Completed');
    _showSnackBar("Job Completed! Earnings updated.", Colors.green);
  }

  void declineRequest(BookingModel booking) async {
    await StorageService.updateBookingStatus(booking.id, 'Declined');
    _showSnackBar("Request Declined.", Colors.red);
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
        title: Text("Fixify Dashboard",
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesListScreen(providerId: currentProvider.id)));
            },
            icon: const Icon(Icons.mail_outline_rounded, color: Colors.blue, size: 26),
          ),
          IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(user: currentProvider))),
              icon: const Icon(Icons.settings_outlined, color: Colors.blue, size: 26)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<BookingModel>>(
          stream: StorageService.getBookingsStream(currentProvider.id, true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allBookings = snapshot.data ?? [];
            final newRequests = allBookings.where((b) => b.status == 'Pending').toList();
            final activeJobs = allBookings.where((b) => b.status == 'Accepted').toList();
            final completedJobs = allBookings.where((b) => b.status == 'Completed').toList();

            double totalEarnings = completedJobs.fold(0, (sum, item) => sum + (double.tryParse(item.price) ?? 0));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  _buildEarningsCard(totalEarnings, completedJobs.length),
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
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: currentProvider.imageUrl.isEmpty
              ? null
              : (currentProvider.imageUrl.startsWith('http')
              ? NetworkImage(currentProvider.imageUrl)
              : FileImage(File(currentProvider.imageUrl)) as ImageProvider),
          child: currentProvider.imageUrl.isEmpty
              ? Text(currentProvider.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))
              : null,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hi, ${currentProvider.name} 👋",
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(currentProvider.profession,
                  style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
        Switch(
          value: isOnline,
          activeColor: Colors.green,
          onChanged: (v) => setState(() => isOnline = v),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(double earnings, int jobs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: isOnline
                ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
                : [Colors.grey.shade700, Colors.blueGrey]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Earnings", style: GoogleFonts.inter(color: Colors.white70)),
          Text("Rs. ${earnings.toInt()}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat("Jobs Done", "$jobs"),
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.person, color: Colors.blue)
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Text(booking.serviceName, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
              ])),
              Text("Rs.${booking.price}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: OutlinedButton(
                  onPressed: () => declineRequest(booking),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: const Text("Decline"))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                  onPressed: () => acceptRequest(booking),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  child: const Text("Accept"))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
      ),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.bolt, color: Colors.white)),
        title: Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(booking.serviceName, style: const TextStyle(fontSize: 12)),
        trailing: ElevatedButton(
            onPressed: () => completeJob(booking),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: const Text("Finish")),
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _emptyState(String msg) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(msg, style: const TextStyle(color: Colors.grey))));
}