import 'package:fixify_admin/screens/admin_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vhvwkoeejcdburoqfbvz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZodndrb2VlamNkYnVyb3FmYnZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgyMzU5MDMsImV4cCI6MjA5MzgxMTkwM30.icVNBiGvIafm6fA3KzT4lP4w7Ky2gtzf5bjql5Rx5yk',
  );

  runApp(const FixifyAdminApp());
}

class FixifyAdminApp extends StatelessWidget {
  const FixifyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixify Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Modern Light Grey Background
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        primarySwatch: Colors.blue,
      ),
      home: const AdminLoginScreen(), // Pehle login screen khulegi
    );
  }
}