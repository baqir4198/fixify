import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<BookingModel> dummyBookings = [];
    // We will simulate data here for now
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Appointments",style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: dummyBookings.isEmpty
        ? _buildEmptyState()
          :ListView.builder(
        itemCount: dummyBookings.length,
        itemBuilder: (context, index){
          final booking = dummyBookings[index];
          return _buildBookingCard(booking);
        }
      ),
    );
  }
  Widget _buildEmptyState(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today,size: 80,color: Colors.grey[400],),
          const SizedBox(height: 16,),
          const Text("No booking yet",style: TextStyle(fontSize: 18,color: Colors.grey),)
        ],
      ),
    );
  }
  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.handyman,color: Colors.blue),
        ),
        title: Text(
          booking.provider.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.provider.profession),
            const SizedBox(height: 4),
            Text(
              "${DateFormat('EEE, MMM d').format(booking.date)} at ${booking.time}",
              style: const TextStyle(color: Colors.blue,fontWeight: FontWeight.w500),
            )
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12,vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(20)
          ),
          child: Text(
            booking.status,
            style: const TextStyle(color: Colors.orange,fontWeight: FontWeight.bold,fontSize: 12),
          ),
        ),
      ),
    );
  }
}
