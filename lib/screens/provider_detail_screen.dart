import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provider_model.dart';
import '../models/booking_model.dart';
import '../services/storage_service.dart';
import 'package:google_fonts/google_fonts.dart';

final supabase = Supabase.instance.client;

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
    final user = supabase.auth.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? "";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.blueAccent)),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

  void _showConfirmation() {
    String dateStr = DateFormat('EEEE, MMM d').format(_selectedDate!);
    String timeStr = _selectedTime!.format(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 25, right: 25, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              Text("Confirm Your Booking", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Confirm Your Name",
                  prefixIcon: const Icon(Icons.person_pin_rounded, color: Colors.blueAccent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoContainer(dateStr, timeStr),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : () async {
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please confirm your name")));
                      return;
                    }

                    setModalState(() => _isBooking = true);

                    try {
                      final String uid = supabase.auth.currentUser?.id ?? "";

                      // --- NAYA KAAM: Customer ki current rating fetch karna ---
                      final ratingData = await StorageService.getCustomerRatingData(uid);

                      final newBooking = BookingModel(
                        id: '',
                        provider: widget.provider,
                        customerName: _nameController.text.trim(),
                        customerId: uid,
                        date: _selectedDate!,
                        time: timeStr,
                        serviceName: widget.provider.profession,
                        price: widget.provider.pricePerHour.toString(),
                        status: 'Pending',
                        // In fields se provider dashboard pe "New Client" check chalega
                        customerAverageRating: ratingData['average_rating'],
                        customerTotalReviews: ratingData['total_reviews'],
                      );

                      await StorageService.saveBooking(newBooking);

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Booking request sent to ${widget.provider.name}!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      setModalState(() => _isBooking = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Confirm & Send Request", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.blueAccent,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.provider.id,
                child: _buildTopImage(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.provider.name, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
                          Text(widget.provider.profession, style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text("Rs.${widget.provider.pricePerHour.toInt()}/hr", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatsRow(), // Rating yahan show hogi
                  const SizedBox(height: 32),
                  Text("About Provider", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    widget.provider.bio.isEmpty ? "No description available." : widget.provider.bio,
                    style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 15),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent[700],
              minimumSize: const Size(double.infinity, 58),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _pickDateTime,
            child: const Text("Continue to Booking", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildTopImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.provider.imageUrl.startsWith('http')
            ? Image.network(widget.provider.imageUrl, fit: BoxFit.cover)
            : Container(color: Colors.blue[100], child: const Icon(Icons.person, size: 100, color: Colors.white)),
        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.5)]))),
      ],
    );
  }

  Widget _buildStatsRow() {
    // Check if new provider or old
    bool isNew = widget.provider.totalReviews < 3;
    return Row(
      children: [
        _statBox(
            Icons.star_rounded,
            isNew ? "New" : widget.provider.averageRating.toStringAsFixed(1),
            "Rating",
            Colors.orange
        ),
        const SizedBox(width: 12),
        _statBox(Icons.verified_rounded, "Verified", "Identity", Colors.green),
        const SizedBox(width: 12),
        _statBox(Icons.work_history_rounded, "5+ Yrs", "Exp.", Colors.blue),
      ],
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContainer(String date, String time) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.1))),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_month_rounded, "Scheduled Date", date),
          const Divider(height: 20),
          _buildInfoRow(Icons.watch_later_rounded, "Arrival Time", time),
          const Divider(height: 20),
          _buildInfoRow(Icons.payments_rounded, "Estimated Rate", "Rs. ${widget.provider.pricePerHour}/hr", isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}