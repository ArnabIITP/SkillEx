import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No logged in user");

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return {
        'name': 'Anonymous User',
        'skillsOffered': <String>[],
        'skillsWanted': <String>[],
        'availability': <String>[],
      };
    }

    final data = doc.data()!;
    return {
      'name': data['name'] ?? 'Anonymous User',
      'skillsOffered': List<String>.from(data['skillsOffered'] ?? []),
      'skillsWanted': List<String>.from(data['skillsWanted'] ?? []),
      'availability': List<String>.from(data['availability'] ?? []),
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data!;
            final name = data['name'] as String;
            final skillsOffered = data['skillsOffered'] as List<String>;
            final skillsWanted = data['skillsWanted'] as List<String>;
            final availability = data['availability'] as List<String>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.indigo, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : const AssetImage("assets/avatar_placeholder.png") as ImageProvider,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? "No email",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionTitle("Skills Offered"),
                  _buildSkillPills(skillsOffered),

                  const SizedBox(height: 20),

                  _buildSectionTitle("Skills Wanted"),
                  _buildSkillPills(skillsWanted),

                  const SizedBox(height: 20),

                  _buildSectionTitle("Availability"),
                  _buildAvailabilityPills(availability),

                  const SizedBox(height: 32),

                  // Buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to edit profile screen
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildSkillPills(List<String> skills) {
    if (skills.isEmpty) {
      return const Text("No skills added", style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map((skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          skill,
          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildAvailabilityPills(List<String> availability) {
    if (availability.isEmpty) {
      return const Text("No availability set", style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availability
          .map((day) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          day,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ))
          .toList(),
    );
  }
}
