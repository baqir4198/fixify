import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Aapke model aur screens ke sahi imports
import 'package:handyman_app/models/provider_model.dart';
import 'package:handyman_app/screens/login_screen.dart';
import 'package:handyman_app/screens/main_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      // App start hote hi AuthWrapper check karega ke user login hai ya nahi
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase Auth state check kar raha hai
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Agar loading ho rahi hai
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Agar User Logged In hai
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            // Firestore se user ka data fetch karna
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                // Map se ProviderModel banana
                final userData = ProviderModel.fromMap(
                  userSnapshot.data!.data() as Map<String, dynamic>,
                  docId: snapshot.data!.uid,
                );

                // YAHAN ERROR FIX HUA: 'user' parameter pass ho gaya
                return MainWrapper(user: userData);
              }

              // Agar user login hai par data nahi mila (rare case)
              return const LoginScreen();
            },
          );
        }

        // 3. Agar User Login nahi hai
        return const LoginScreen();
      },
    );
  }
}