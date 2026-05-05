import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/view_models/auth_viewmodel.dart';

// DUMMY ADMIN HOME (FOR TESTING)

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Accessing the global auth broadcast
    final auth = context.watch<AuthViewModel>();
    final adminName = auth.currentUser?.username ?? "Admin";

    return Scaffold(
      appBar: AppBar(
        title: const Text("AuraGains Admin"),
        backgroundColor: Colors.redAccent, // Distinct color for Admin
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(), // Uses your ViewModel logout
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $adminName", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Role: System Administrator", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            const Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text("User Management"),
                subtitle: Text("Manage AuraGains members"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text("System Analytics"),
                subtitle: Text("View app performance"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
          ],
        ),
      ),
    );
  }
}