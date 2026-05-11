import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Screens & Models
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/login_screen.dart';
import 'package:handyman_app/screens/main_wrapper.dart';
import 'package:handyman_app/screens/provider_dashboard.dart'; // Isay add karein

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vhvwkoeejcdburoqfbvz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZodndrb2VlamNkYnVyb3FmYnZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgyMzU5MDMsImV4cCI6MjA5MzgxMTkwM30.icVNBiGvIafm6fA3KzT4lP4w7Ky2gtzf5bjql5Rx5yk',
  );

  runApp(const HandyManApp());
}

class HandyManApp extends StatelessWidget {
  const HandyManApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fixify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return FutureBuilder<PostgrestMap?>(
            future: supabase
                .from('users')
                .select()
                .eq('id', session.user.id)
                .maybeSingle(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                // 1. Data model mein load karein
                final userData = ProviderModel.fromMap(
                  userSnapshot.data!,
                );

                // 2. Role fetch karein (Table mein column ka naam 'role' hona chahiye)
                final String role = userSnapshot.data!['role'] ?? 'Customer';

                print("DEBUG: App Start - User Role is: $role");

                // 3. Role ke mutabiq sahi screen par bhejein
                if (role == 'Provider') {
                  return ProviderDashboard(provider: userData);
                } else {
                  return MainWrapper(user: userData);
                }
              }

              // Agar session hai magar DB mein entry nahi mili
              return const LoginScreen();
            },
          );
        }

        // Agar user login nahi hai
        return const LoginScreen();
      },
    );
  }
}