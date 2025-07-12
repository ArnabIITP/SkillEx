import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = '';
  String bio = '';
  String newOfferedSkill = '';
  String newWantedSkill = '';

  List<Map<String, dynamic>> skillsOffered = [];
  List<Map<String, dynamic>> skillsWanted = [];

  bool isSaving = false;

  Future<int> _getOrCreateSkill(String skillName) async {
    skillName = skillName.trim();

    final existing = await _firestore
        .collection('skills')
        .where('name', isEqualTo: skillName)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first['id'];
    }

    final allSkills = await _firestore
        .collection('skills')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    final newId = allSkills.docs.isEmpty ? 1 : allSkills.docs.first['id'] + 1;

    await _firestore.collection('skills').add({
      'id': newId,
      'name': skillName,
    });

    return newId;
  }

  Future<void> addSkill(String skillName, bool offered) async {
    if (skillName.trim().isEmpty) return;

    final id = await _getOrCreateSkill(skillName);

    setState(() {
      final skillMap = {'id': id, 'name': skillName.trim()};

      if (offered) {
        if (!skillsOffered.any((s) => s['id'] == id)) {
          skillsOffered.add(skillMap);
        }
        newOfferedSkill = '';
      } else {
        if (!skillsWanted.any((s) => s['id'] == id)) {
          skillsWanted.add(skillMap);
        }
        newWantedSkill = '';
      }
    });
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          'name': name,
          'bio': bio,
          'skillsOffered': skillsOffered.map((s) => s['id']).toList(),
          'skillsWanted': skillsWanted.map((s) => s['id']).toList(),
          'updatedAt': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile saved successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }

    setState(() => isSaving = false);
  }

  void removeSkill(bool offered, int id) {
    setState(() {
      if (offered) {
        skillsOffered.removeWhere((s) => s['id'] == id);
      } else {
        skillsWanted.removeWhere((s) => s['id'] == id);
      }
    });
  }

  Widget skillInput({
    required String label,
    required String value,
    required Function(String) onChanged,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          child: const Text("Add"),
        ),
      ],
    );
  }

  Widget skillChips(List<Map<String, dynamic>> skillList, bool offered) {
    return Wrap(
      spacing: 8,
      children: skillList.map((skill) {
        return Chip(
          label: Text(skill['name']),
          labelStyle: const TextStyle(color: Colors.white),
          backgroundColor: Colors.indigo,
          deleteIcon: const Icon(Icons.close, color: Colors.white),
          onDeleted: () => removeSkill(offered, skill['id']),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text("Let us know more about you",
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter your bio' : null,
                  onChanged: (val) => bio = val,
                ),
                const SizedBox(height: 24),

                const Text("Skills You Offer", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                skillInput(
                  label: "e.g. Java, Photoshop",
                  value: newOfferedSkill,
                  onChanged: (val) => newOfferedSkill = val,
                  onAdd: () => addSkill(newOfferedSkill, true),
                ),
                const SizedBox(height: 10),
                skillChips(skillsOffered, true),

                const SizedBox(height: 24),
                const Text("Skills You Want", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                skillInput(
                  label: "e.g. Python, Excel",
                  value: newWantedSkill,
                  onChanged: (val) => newWantedSkill = val,
                  onAdd: () => addSkill(newWantedSkill, false),
                ),
                const SizedBox(height: 10),
                skillChips(skillsWanted, false),
                const SizedBox(height: 30),

                isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
