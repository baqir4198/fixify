import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // REAL DATA: Customer ka naam lene ke liye controller
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- Date and Time Picker Logic ---
  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.blue),
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

  // --- Confirmation Bottom Sheet ---
  void _showConfirmation() {
    String dateStr = DateFormat('EEEE, MMM d').format(_selectedDate!);
    String timeStr = _selectedTime!.format(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 25,
          right: 25,
          top: 30,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 30, // Keyboard ke liye jagah
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 25),
            const Text("Booking Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // REAL DATA INPUT FIELD
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Your Full Name",
                hintText: "Enter name to show on dashboard",
                prefixIcon: const Icon(Icons.person_pin_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildInfoRow(Icons.calendar_today, "Date", dateStr),
            _buildInfoRow(Icons.access_time, "Time", timeStr),
            _buildInfoRow(Icons.payments_outlined, "Price", "Rs. ${widget.provider.pricePerHour}"),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validation: Name lazmi hona chahiye
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter your name first!")),
                        );
                        return;
                      }

                      // NO DUMMY DATA: Customer Name controller se aa raha hai
                      final newBooking = BookingModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        provider: widget.provider,
                        customerName: _nameController.text.trim(),
                        customerId: "REAL_USER_${DateTime.now().second}",
                        date: _selectedDate!,
                        time: timeStr,
                        serviceName: widget.provider.profession,
                        price: widget.provider.pricePerHour.toString(),
                        status: 'Pending',
                      );

                      await StorageService.saveBooking(newBooking);
                      // Booking save hone ke baad auto-message bhej do
                      await StorageService.sendAutoWelcomeMessage(newBooking);

                      if (!mounted) return;
                      Navigator.pop(ctx);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Request sent for ${newBooking.customerName}!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Confirm Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
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
            expandedHeight: 380,
            pinned: true,
            backgroundColor: Colors.blue,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'provider-${widget.provider.id}',
                child: widget.provider.imageUrl.startsWith('http')
                    ? Image.network(widget.provider.imageUrl, fit: BoxFit.cover)
                    : Image.file(File(widget.provider.imageUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.provider.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.provider.profession, style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
                        child: Text("Rs.${widget.provider.pricePerHour.toInt()}/hr", style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(Icons.star, "Rating", "${widget.provider.rating}"),
                        _buildStatItem(Icons.work_history, "Exp.", "5+ Years"),
                        _buildStatItem(Icons.verified, "Jobs", "150+"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text("Service Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    "Professional ${widget.provider.profession} available for high-quality home maintenance. I provide reliable services with focus on detail and customer satisfaction.",
                    style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.6),
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: _pickDateTime,
          child: const Text("Book Appointment Now", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 26),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 15),
          Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 15)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}