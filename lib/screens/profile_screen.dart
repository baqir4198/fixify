import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'become_provider_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20,),
          const CircleAvatar(radius: 50,child: Icon(Icons.person,size: 50,),),
          const SizedBox(height: 20,),
          const Text("Hamza Ahmad",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          const Text("Hamza@email.com",style: TextStyle(color: Colors.grey),),
          const Divider(height: 40),
          _buildProfileOption(Icons.edit,"Edit Profile",(){}),
          _buildProfileOption(Icons.history,"Booking History",(){}),


          _buildProfileOption(
            Icons.storefront,
            "Become Service Provider",
              (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BecomeProviderScreen()),
                );
              },
            color:Colors.blue
          ),
          const Spacer(),
          _buildProfileOption(Icons.logout,"Logout",(){},color:Colors.red),
          const SizedBox(height: 20,)
        ],
      ),
    );
  }
  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap,{Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black),
      title: Text(title, style: TextStyle(color: color ?? Colors.black),),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
