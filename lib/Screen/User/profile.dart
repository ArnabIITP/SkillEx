import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:untitled/Screen/User/setup.dart';

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
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.indigo.shade100,
                  backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null || user.photoURL!.isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.indigo)
                      : null,
                ),
                const SizedBox(height: 16),

                Text(
                  name,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? "No email",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 28),

                _buildSectionTitle("Skills Offered"),
                _buildSkillPills(skillsOffered),
                const SizedBox(height: 20),

                _buildSectionTitle("Skills Wanted"),
                _buildSkillPills(skillsWanted),
                const SizedBox(height: 20),

                _buildSectionTitle("Availability"),
                _buildAvailabilityPills(availability),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text("Edit Profile", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Logout", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillPills(List<String> skills) {
    if (skills.isEmpty) {
      return const Text("No skills added", style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
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
      spacing: 10,
      runSpacing: 10,
      children: availability
          .map((day) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade300,
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
