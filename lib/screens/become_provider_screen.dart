import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:handyman_app/models/provider_model.dart';

import '../services/storage_service.dart';

class BecomeProviderScreen extends StatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  State<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  final _formkey = GlobalKey<FormState>();
  String _selectedProfession = 'Plumbing';
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _professions = ['Plumbing','Electrical','Cleaning','Painting','Carpentry','AC Repair'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register as Provider")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formkey,
          child: ListView(
            children: [
              const Text("Enter your professional Details",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (value)=>value!.isEmpty? "Please Enter Name": null,
              ),
              const SizedBox(height: 15,),
              DropdownButtonFormField(
                value: _selectedProfession,
                decoration: const InputDecoration(labelText: "Select Profession",border: OutlineInputBorder()),
                items: _professions.map((p)=>DropdownMenuItem(value: p,child: Text(p))).toList(),
                onChanged: (val)=> setState(()=>_selectedProfession = val.toString()),
              ),
              const SizedBox(height: 30,),
              ElevatedButton(
                onPressed:() async{
                  if(_formkey.currentState!.validate()){
                    final newProvider = ProviderModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      profession: _selectedProfession,
                      rating: 5.0,
                      pricePerHour: double.parse(_priceController.text),
                      imageUrl: "https://i.pravatar.cc/150?u=${_nameController.text}",
                    );
                    await StorageService.saveProvider(newProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Congratulation! You are now a Provider."))
                    );
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                child: const Text("Submit Application"),
              )
            ],
          ),
        ),
      ),
    );

  }
}
