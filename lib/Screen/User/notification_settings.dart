import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = false;
  Map<String, dynamic> _notificationSettings = {
    'newMatches': true,
    'messages': true,
    'skillRequests': true,
    'skillUpdates': false,
    'appUpdates': true,
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No logged in user");

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications');
      
      final doc = await docRef.get();
      
      if (doc.exists) {
        setState(() {
          _notificationSettings = {
            'newMatches': doc.data()?['newMatches'] ?? true,
            'messages': doc.data()?['messages'] ?? true,
            'skillRequests': doc.data()?['skillRequests'] ?? true,
            'skillUpdates': doc.data()?['skillUpdates'] ?? false,
            'appUpdates': doc.data()?['appUpdates'] ?? true,
          };
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e'))
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No logged in user");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set(_notificationSettings, SetOptions(merge: true));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e'))
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
        title: const Text('Notification Settings'),
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
              _buildSettingSwitch(
                title: 'New Matches', 
                subtitle: 'Get notified when you match with someone',
                value: _notificationSettings['newMatches'],
                onChanged: (value) {
                  setState(() {
                    _notificationSettings['newMatches'] = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingSwitch(
                title: 'Messages', 
                subtitle: 'Receive notifications for new messages',
                value: _notificationSettings['messages'],
                onChanged: (value) {
                  setState(() {
                    _notificationSettings['messages'] = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingSwitch(
                title: 'Skill Requests', 
                subtitle: 'Get notified when someone requests your skills',
                value: _notificationSettings['skillRequests'],
                onChanged: (value) {
                  setState(() {
                    _notificationSettings['skillRequests'] = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingSwitch(
                title: 'Skill Updates', 
                subtitle: 'Get notified about new skills in your area',
                value: _notificationSettings['skillUpdates'],
                onChanged: (value) {
                  setState(() {
                    _notificationSettings['skillUpdates'] = value;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingSwitch(
                title: 'App Updates', 
                subtitle: 'Stay informed about new app features',
                value: _notificationSettings['appUpdates'],
                onChanged: (value) {
                  setState(() {
                    _notificationSettings['appUpdates'] = value;
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
                onPressed: _saveNotificationSettings,
                child: const Text('Save Changes'),
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
                Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Notification Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Control which notifications you receive from SkillEx. You can toggle each type of notification on or off.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
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
