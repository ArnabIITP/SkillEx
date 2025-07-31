import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_state.dart';
import '../../models/user_model.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Profile data
  late String name;
  late String bio;
  File? _profileImage;
  List<String> skillsOffered = [];
  List<String> skillsWanted = [];
  List<String> availability = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _newSkillController = TextEditingController();
  final TextEditingController _newWantedSkillController = TextEditingController();
  final TextEditingController _newAvailabilityController = TextEditingController();

  bool isSaving = false;
  String availabilityType = 'Weekdays';
  List<String> customDays = [];

  @override
  void initState() {
    super.initState();
    // Initialize with user data
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    
    if (user != null) {
      _nameController.text = user.name;
      _bioController.text = user.bio;
      skillsOffered = List.from(user.skillsOffered);
      skillsWanted = List.from(user.skillsWanted);
      availability = List.from(user.availability);
      
      if (availability.contains('Weekdays')) {
        availabilityType = 'Weekdays';
      } else if (availability.contains('Weekends')) {
        availabilityType = 'Weekends';
      } else {
        availabilityType = 'Custom';
        customDays = List.from(availability);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _newSkillController.dispose();
    _newWantedSkillController.dispose();
    _newAvailabilityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser;
      
      if (currentUser != null) {
        // Create an updated user model
        final updatedUser = UserModel(
          id: currentUser.id,
          email: currentUser.email,
          name: _nameController.text,
          bio: _bioController.text,
          photoUrl: currentUser.photoUrl,
          skillsOffered: skillsOffered,
          skillsWanted: skillsWanted,
          availability: availabilityType == 'Custom' ? customDays : [availabilityType],
          isAdmin: currentUser.isAdmin,
        );
        
        // Update the user profile
        await appState.updateUserProfile(updatedUser);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile saved successfully!")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      print("Error saving profile: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }

    setState(() => isSaving = false);
  }

  void _addSkill(String skillName, bool offered) {
    if (skillName.trim().isEmpty) return;

    final skill = skillName.trim();

    setState(() {
      if (offered) {
        if (!skillsOffered.contains(skill)) {
          skillsOffered.add(skill);
        }
        _newSkillController.clear();
      } else {
        if (!skillsWanted.contains(skill)) {
          skillsWanted.add(skill);
        }
        _newWantedSkillController.clear();
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

  Widget skillChips(List<String> skillList) {
    return Wrap(
      spacing: 8,
      children: skillList.map((skill) {
        return Chip(
          label: Text(skill),
          labelStyle: const TextStyle(color: Colors.white),
          backgroundColor: Colors.indigo,
          onDeleted: () {
            setState(() {
              skillList.remove(skill);
            });
          },
          deleteIconColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  Widget availabilitySelector() {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final shortNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Availability", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: availabilityType,
          items: ['Weekdays', 'Weekends', 'Custom']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            setState(() {
              availabilityType = val!;
              customDays = []; // reset on change
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        if (availabilityType == 'Custom') ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final isSelected = customDays.contains(shortNames[i]);
              return ChoiceChip(
                label: Text(days[i]),
                selected: isSelected,
                selectedColor: Colors.indigo,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      customDays.add(shortNames[i]);
                    } else {
                      customDays.remove(shortNames[i]);
                    }
                  });
                },
              );
            }),
          ),
        ],
      ],
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

                // Profile Picture
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.indigo.withOpacity(0.2),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (Provider.of<AppState>(context).currentUser?.photoUrl.isNotEmpty == true
                                ? NetworkImage(Provider.of<AppState>(context).currentUser!.photoUrl) as ImageProvider
                                : null),
                        child: _profileImage == null && 
                               (Provider.of<AppState>(context).currentUser?.photoUrl.isEmpty ?? true)
                            ? Icon(Icons.person, size: 60, color: Colors.indigo)
                            : null,
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    hintText: 'Tell us about yourself...'
                  ),
                  onChanged: (val) => bio = val,
                ),
                const SizedBox(height: 24),

                const Text("Skills You Offer", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                skillInput(
                  label: "e.g. Java, Photoshop",
                  controller: _newSkillController,
                  onAdd: () => _addSkill(_newSkillController.text, true),
                ),
                const SizedBox(height: 10),
                skillChips(skillsOffered),

                const SizedBox(height: 24),
                const Text("Skills You Want", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                skillInput(
                  label: "e.g. Python, Excel",
                  controller: _newWantedSkillController,
                  onAdd: () => _addSkill(_newWantedSkillController.text, false),
                ),
                const SizedBox(height: 10),
                skillChips(skillsWanted),

                const SizedBox(height: 24),
                availabilitySelector(),
                const SizedBox(height: 30),

                isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Save Profile", style: TextStyle(fontSize: 16, color: Colors.white)),
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
