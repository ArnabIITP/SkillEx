import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<DocumentSnapshot>> _fetchAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs;
  }

  Future<void> _deleteUser(String uid) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Only delete from Auth if the admin is deleting their own account (FirebaseAuth cannot delete other users directly)
      if (_auth.currentUser?.uid == uid) {
        await _auth.currentUser!.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully")),
      );

      setState(() {}); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete user: $e")),
      );
    }
  }

  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete $name's account?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(uid);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final uid = user.id;
              final name = data['name'] ?? 'Unnamed';
              final email = data['email'] ?? 'No email';
              final skills = (data['skillsOffered'] as List?)?.join(", ") ?? 'None';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name),
                  subtitle: Text("Email: $email\nSkills: $skills"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(uid, name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}