import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/view_models/auth_viewmodel.dart';

// DUMMY USER HOME (FOR TESTING)

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Tuning into the AuthViewModel broadcast
    final auth = context.watch<AuthViewModel>();
    final userName = auth.currentUser?.username ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("AuraGains Dashboard"),
        backgroundColor: Colors.blueAccent, // Standard AuraGains blue
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {}, // Profile settings
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.fitness_center, size: 50),
            ),
            const SizedBox(height: 20),
            Text("Hello, $userName!", style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Start Today's Workout"),
            ),
          ],
        ),
      ),
    );
  }
}
