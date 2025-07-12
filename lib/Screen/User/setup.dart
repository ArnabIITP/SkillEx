import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Home.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController offeredController = TextEditingController();
  final TextEditingController wantedController = TextEditingController();

  String name = '';
  String bio = '';

  List<String> skillsOffered = [];
  List<String> skillsWanted = [];

  bool isSaving = false;

  Future<void> addSkill(String skillName, bool offered) async {
    if (skillName.trim().isEmpty) return;

    final skill = skillName.trim();

    setState(() {
      if (offered) {
        if (!skillsOffered.contains(skill)) {
          skillsOffered.add(skill);
        }
        offeredController.clear();
      } else {
        if (!skillsWanted.contains(skill)) {
          skillsWanted.add(skill);
        }
        wantedController.clear();
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
          'skillsOffered': skillsOffered,
          'skillsWanted': skillsWanted,
          'updatedAt': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile saved successfully!")),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      }
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }

    setState(() => isSaving = false);
  }

  void removeSkill(bool offered, String skillName) {
    setState(() {
      if (offered) {
        skillsOffered.remove(skillName);
      } else {
        skillsWanted.remove(skillName);
      }
    });
  }

  Widget skillInput({
    required String label,
    required TextEditingController controller,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget skillChips(List<String> skillList, bool offered) {
    return Wrap(
      spacing: 8,
      children: skillList.map((skill) {
        return Chip(
          label: Text(skill),
          labelStyle: const TextStyle(color: Colors.white),
          backgroundColor: Colors.indigo,
          deleteIcon: const Icon(Icons.close, color: Colors.white),
          onDeleted: () => removeSkill(offered, skill),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Complete Your Profile", style: TextStyle(color: Colors.white)),
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
                Text(
                  "Let us know more about you",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
                  controller: offeredController,
                  onAdd: () => addSkill(offeredController.text, true),
                ),
                const SizedBox(height: 10),
                skillChips(skillsOffered, true),

                const SizedBox(height: 24),
                const Text("Skills You Want", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                skillInput(
                  label: "e.g. Python, Excel",
                  controller: wantedController,
                  onAdd: () => addSkill(wantedController.text, false),
                ),
                const SizedBox(height: 10),
                skillChips(skillsWanted, false),
                const SizedBox(height: 30),

                isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Save Profile", style: TextStyle(color: Colors.white)),
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
