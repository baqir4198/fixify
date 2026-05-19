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
  final double? customerLatitude;
  final double? customerLongitude;

  const ProviderDetailScreen({
    super.key,
    required this.provider,
    this.customerLatitude,
    this.customerLongitude,
  });

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
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          String dateStr = DateFormat('EEEE, MMM d').format(_selectedDate!);
          String timeStr = _selectedTime!.format(context);

          return Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                ),
                const SizedBox(height: 25),
                Text(
                    "Confirm Your Booking",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: "Confirm Your Name",
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.person_pin_rounded, color: Colors.blueAccent),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoContainer(dateStr, timeStr),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : () async {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please confirm your name"))
                        );
                        return;
                      }

                      setModalState(() => _isBooking = true);

                      try {
                        final String uid = supabase.auth.currentUser?.id ?? "";
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
                          customerAverageRating: ratingData['average_rating'],
                          customerTotalReviews: ratingData['total_reviews'],
                          customerLatitude: widget.customerLatitude,
                          customerLongitude: widget.customerLongitude,
                        );

                        await StorageService.saveBooking(newBooking);

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white),
                                const SizedBox(width: 10),
                                Text("Booking request sent to ${widget.provider.name}!"),
                              ],
                            ),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } catch (e) {
                        setModalState(() => _isBooking = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent)
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isBooking
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                        "Confirm & Send Request",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.35),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildTopImage(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                widget.provider.name,
                                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  widget.provider.profession,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.blueAccent[700], fontWeight: FontWeight.w600)
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16)
                        ),
                        child: Column(
                          children: [
                            Text(
                                "Rs.${widget.provider.pricePerHour.toInt()}",
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent[700])
                            ),
                            Text(
                                "per hour",
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  Text(
                      "About Provider",
                      style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.provider.bio.isEmpty ? "No description available." : widget.provider.bio,
                    style: GoogleFonts.inter(color: Colors.grey[700], height: 1.6, fontSize: 14.5),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
            border: const Border(top: BorderSide(color: Color(0xFFF1F5F9)))
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent[700],
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _pickDateTime,
            child: Text(
                "Book Appointment",
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
            ),
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
            : Container(
            color: Colors.blue[50],
            child: Icon(Icons.person_rounded, size: 110, color: Colors.blueAccent.withOpacity(0.4))
        ),
        Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.55)
                    ]
                )
            )
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    bool isNew = widget.provider.totalReviews < 3;
    return Row(
      children: [
        _statBox(
            Icons.star_rounded,
            isNew ? "New" : widget.provider.averageRating.toStringAsFixed(1),
            "Rating",
            Colors.amber.shade700
        ),
        const SizedBox(width: 12),
        _statBox(Icons.verified_user_rounded, "Verified", "Identity", Colors.green.shade600),
        const SizedBox(width: 12),
        _statBox(Icons.bolt_rounded, "Active", "Status", Colors.blue.shade700),
      ],
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9))
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContainer(String date, String time) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.08))
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_month_rounded, "Scheduled Date", date),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFE2E8F0))),
          _buildInfoRow(Icons.watch_later_rounded, "Arrival Time", time),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFE2E8F0))),
          _buildInfoRow(Icons.payments_rounded, "Estimated Rate", "Rs. ${widget.provider.pricePerHour.toInt()}/hr", isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent[700]),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13.5, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}