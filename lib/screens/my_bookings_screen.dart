import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/booking_model.dart';
import 'package:handyman_app/services/storage_service.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Appointments",style: TextStyle(color: Colors.black,fontWeight:FontWeight.bold),),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: StorageService.getBookings(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child:CircularProgressIndicator());
          }
          if(snapshot.hasError){
            return const Center(child: Text("Something went Wrong!"),);
          }
          if(!snapshot.hasData){
            final List<BookingModel> bookings = snapshot.data!;
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index){
                final booking = bookings[index];
                return _buildBookingCard(booking);
              },
            );
          }
          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index){
              final item = bookings[index];
              return _buildBookingCard(item);
            },
          );
        },
      )
    );
  }

  Widget _buildEmptyState(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,size: 70,color: Colors.grey[400],),
          const SizedBox(height: 16,),
          const Text("No booking yet",style: TextStyle(fontSize: 16,color: Colors.grey),)
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
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.person,color: Colors.white),
        ),
        title: Text(
          booking.provider.name,
          style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.provider.profession,style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text(
              "📅 ${DateFormat('MMM d').format(booking.date)}   |   ⏰ ${booking.time}",
              style: const TextStyle(color: Colors.blue,fontWeight: FontWeight.w500),
            )
          ],
        ),
        trailing: Chip(
          label: Text(booking.status, style: const TextStyle(fontSize: 10,color: Colors.white)),
          backgroundColor: Colors.orange,
        ),
      ),
    );
  }
}
