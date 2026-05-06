import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth add kiya
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_model.dart';
import '../models/booking_model.dart';
import '../services/storage_service.dart';

class ProviderDetailScreen extends StatefulWidget {
  final ProviderModel provider;
  const ProviderDetailScreen({super.key, required this.provider});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _nameController = TextEditingController();
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from current logged in user if possible
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      _nameController.text = user.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- Date and Time Picker ---
  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
        _showConfirmation();
      }
    }
  }

  // --- Confirmation Bottom Sheet ---
  void _showConfirmation() {
    String dateStr = DateFormat('EEEE, MMM d').format(_selectedDate!);
    String timeStr = _selectedTime!.format(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => StatefulBuilder( // Status update ke liye
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 25, right: 25, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Confirm Booking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Your Full Name",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.calendar_today, "Date", dateStr),
              _buildInfoRow(Icons.access_time, "Time", timeStr),
              _buildInfoRow(Icons.payments_outlined, "Estimated", "Rs. ${widget.provider.pricePerHour}"),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : () async {
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your name")));
                      return;
                    }

                    setModalState(() => _isBooking = true);

                    // 1. Get Real User ID from Firebase
                    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "guest_user";

                    // 2. Create Booking Object
                    final newBooking = BookingModel(
                      id: FirebaseFirestore.instance.collection('bookings').doc().id, // Unique ID from Firestore
                      provider: widget.provider,
                      customerName: _nameController.text.trim(),
                      customerId: uid, // REAL ID
                      date: _selectedDate!,
                      time: timeStr,
                      serviceName: widget.provider.profession,
                      price: widget.provider.pricePerHour.toString(),
                      status: 'Pending',
                    );

                    // 3. Save to Firestore
                    await StorageService.saveBooking(newBooking);

                    if (!mounted) return;
                    Navigator.pop(ctx); // Close Sheet
                    Navigator.pop(context); // Back to Home

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Request sent to ${widget.provider.name}!"), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm & Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildTopImage(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.provider.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            Text(widget.provider.profession, style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Text("Rs.${widget.provider.pricePerHour.toInt()}/hr", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildStatsRow(),
                  const SizedBox(height: 30),
                  const Text("About Me", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    widget.provider.about.isEmpty
                        ? "Expert ${widget.provider.profession} with years of experience in providing high-quality service."
                        : widget.provider.about,
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          onPressed: _pickDateTime,
          child: const Text("Book Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTopImage() {
    return widget.provider.imageUrl.startsWith('http')
        ? Image.network(widget.provider.imageUrl, fit: BoxFit.cover)
        : (widget.provider.imageUrl.isNotEmpty
        ? Image.file(File(widget.provider.imageUrl), fit: BoxFit.cover)
        : Container(color: Colors.blue[300], child: const Icon(Icons.person, size: 100, color: Colors.white)));
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.star, "Rating", "${widget.provider.rating}"),
          _statItem(Icons.verified_user, "Status", "Verified"),
          _statItem(Icons.timer, "Exp", "5+ Yrs"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}