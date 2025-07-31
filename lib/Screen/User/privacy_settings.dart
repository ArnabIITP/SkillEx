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
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: const Color(0xFF6246EA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildProfileVisibilitySelector(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6246EA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _savePrivacySettings,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'Are you sure you want to delete your account? This action cannot be undone.'
                      ),
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
                              const SnackBar(content: Text('Account deletion is not implemented yet'))
                            );
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Delete My Account', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Privacy Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Control what information you share with other users and how your data is used in SkillEx.',
              style: TextStyle(fontSize: 14),
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose who can view your profile',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _privacySettings['profileVisibility'],
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6246EA),
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
