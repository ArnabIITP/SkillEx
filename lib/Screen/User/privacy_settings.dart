import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _isLoading = false;
  Map<String, dynamic> _privacySettings = {
    'profileVisibility': 'public',
    'showEmail': false,
    'shareSkills': true,
    'shareAvailability': true,
    'allowDataCollection': true,
    'hideLocation': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No logged in user");

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('privacy');
      
      final doc = await docRef.get();
      
      if (doc.exists) {
        setState(() {
          _privacySettings = {
            'profileVisibility': doc.data()?['profileVisibility'] ?? 'public',
            'showEmail': doc.data()?['showEmail'] ?? false,
            'shareSkills': doc.data()?['shareSkills'] ?? true,
            'shareAvailability': doc.data()?['shareAvailability'] ?? true,
            'allowDataCollection': doc.data()?['allowDataCollection'] ?? true,
            'hideLocation': doc.data()?['hideLocation'] ?? false,
          };
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading privacy settings: $e'))
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No logged in user");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('privacy')
          .set(_privacySettings, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy settings saved'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving privacy settings: $e'))
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FB),
      appBar: AppBar(
        title: const Text('Privacy Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6246EA),
        elevation: 1.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF6246EA)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                _buildInfoCard(),
                const SizedBox(height: 28),
                _buildProfileVisibilitySelector(),
                const SizedBox(height: 18),
                _buildSettingSwitch(
                  title: 'Show Email',
                  subtitle: 'Allow other users to see your email address',
                  value: _privacySettings['showEmail'],
                  onChanged: (value) {
                    setState(() {
                      _privacySettings['showEmail'] = value;
                    });
                  },
                ),
                _buildDivider(),
                _buildSettingSwitch(
                  title: 'Share Skills',
                  subtitle: 'Make your skills visible to other users',
                  value: _privacySettings['shareSkills'],
                  onChanged: (value) {
                    setState(() {
                      _privacySettings['shareSkills'] = value;
                    });
                  },
                ),
                _buildDivider(),
                _buildSettingSwitch(
                  title: 'Share Availability',
                  subtitle: 'Allow others to see when you are available',
                  value: _privacySettings['shareAvailability'],
                  onChanged: (value) {
                    setState(() {
                      _privacySettings['shareAvailability'] = value;
                    });
                  },
                ),
                _buildDivider(),
                _buildSettingSwitch(
                  title: 'Hide Location',
                  subtitle: 'Don\'t show your approximate location to others',
                  value: _privacySettings['hideLocation'],
                  onChanged: (value) {
                    setState(() {
                      _privacySettings['hideLocation'] = value;
                    });
                  },
                ),
                _buildDivider(),
                _buildSettingSwitch(
                  title: 'Allow Data Collection',
                  subtitle: 'Help us improve by sharing anonymous usage data',
                  value: _privacySettings['allowDataCollection'],
                  onChanged: (value) {
                    setState(() {
                      _privacySettings['allowDataCollection'] = value;
                    });
                  },
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6246EA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    elevation: 0,
                  ),
                  onPressed: _savePrivacySettings,
                  child: const Text('Save Changes'),
                ),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                              'Are you sure you want to delete your account? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement account deletion
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account deletion is not implemented yet')));
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Delete My Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.privacy_tip, color: Color(0xFF6246EA), size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Privacy Preferences',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Control what information you share with other users and how your data is used in SkillEx.',
              style: TextStyle(fontSize: 15, color: Color(0xFF555555)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Visibility',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6246EA),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose who can view your profile',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF6246EA), width: 1.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _privacySettings['profileVisibility'],
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              items: [
                DropdownMenuItem(
                  value: 'public',
                  child: const Text('Public - Anyone can view'),
                ),
                DropdownMenuItem(
                  value: 'matches',
                  child: const Text('Matches Only - Only users you\'ve matched with'),
                ),
                DropdownMenuItem(
                  value: 'private',
                  child: const Text('Private - Only you'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _privacySettings['profileVisibility'] = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6246EA),
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: Colors.grey.shade300,
        height: 1,
      ),
    );
  }
}
