import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/provider_model.dart';

class ProviderDetailScreen extends StatefulWidget {
  final ProviderModel provider;

  const ProviderDetailScreen({super.key, required this.provider});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDateTime()async{
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if(pickedDate != null){
      final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now()
      );
      if(pickedTime !=null){
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
        _showConfirmation();
      }
    }
  }
  void _showConfirmation(){
    String dateStr = DateFormat('EEEE,MMM d').format(_selectedDate!);
    String timeStr = _selectedTime!.format(context);
    showDialog(
        context: context ,
        builder: (ctx)=>AlertDialog(
          title: const Text("Confirm Booking"),
          content: Text(
              "Request ${widget.provider.name} for:\n"
                  "Date: $dateStr\n"
                  "Time: $timeStr"
          ),
          actions: [
            TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text("edit")),
            ElevatedButton(
              onPressed: (){
                Navigator.pop(ctx);
                // Here we would save the booking!
              },
              child: const Text("confirm"),
            ),
          ],
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(widget.provider.imageUrl,fit: BoxFit.cover,),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.provider.name,style: const TextStyle(fontSize: 26,fontWeight: FontWeight.bold),),
                      Text("\$${widget.provider.pricePerHour}/hr",style: const TextStyle(fontSize: 20,color: Colors.blue,fontWeight: FontWeight.bold),)
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Text("Expert ${widget.provider.profession}",style: TextStyle(fontSize: 18,color: Colors.grey[600])),
                  const SizedBox(height: 20,),
                  const Text("About Me",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                  const SizedBox(height: 10,),
                  const Text(
                    "I have 10 years of expereince in this filed. I provide high-quality service with satisfaction guarantee.Available for emregency calls and scheduled maintenance.",
                    style: TextStyle(fontSize: 16,height: 1.5),
                  ),
                  const SizedBox(height: 100,)
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity,50),
            shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
            onPressed: (){
              _pickDateTime();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Booking functionality coming soon"))
              );
            },
            child: const Text("Book Appointment", style: TextStyle(color: Colors.white,fontSize: 18),)),
      ),
    );
  }
}
