import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/Screen/User/setup.dart';
import 'package:untitled/Screen/User/notification_settings.dart';
import 'package:untitled/Screen/User/privacy_settings.dart';
import 'package:untitled/providers/user_data_provider.dart';
import '../Admin/Admin.dart'; // Ensure correct path to AdminPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Make sure the provider is initialized and refreshed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserDataProvider>(context, listen: false);
      
      // Refresh data from database to ensure it's up-to-date
      userProvider.refreshUserData();
      
      // Set up a periodic refresh to keep duration calculations up-to-date
      Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {
            // This triggers a rebuild to update membership duration in real-time
          });
        } else {
          timer.cancel();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get membership duration - calculated in real-time
  // Format timestamp for display
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Unknown';
    }
    
    // Calculate the difference from now
    final now = DateTime.now();
    final difference = now.difference(date);
    
    // Format based on how recent
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours hour${hours != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days day${days != 1 ? 's' : ''} ago';
    } else {
      // Format as date for older updates
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getMembershipDuration(dynamic memberSince) {
    if (memberSince == null) return '0 days';
    
    DateTime date;
    if (memberSince is DateTime) {
      date = memberSince;
    } else if (memberSince is Timestamp) {
      date = memberSince.toDate();
    } else {
      return '0 days';
    }
    
    // Use current time to always calculate real-time duration
    final now = DateTime.now();
    final difference = now.difference(date);
    final days = difference.inDays;
    
    // Calculate duration in the most appropriate unit
    if (days < 1) {
      final hours = difference.inHours;
      return '$hours hour${hours != 1 ? 's' : ''}';
    } else if (days < 30) {
      return '$days day${days != 1 ? 's' : ''}';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).floor();
      if (remainingMonths > 0) {
        return '$years year${years > 1 ? 's' : ''}, $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Consumer<UserDataProvider>(
      builder: (context, userDataProvider, _) {
        final isLoading = userDataProvider.isLoading;
        final userData = userDataProvider.userData;
        
        // This will automatically update when data changes in Firestore
        // No need to manually refresh

        return Scaffold(
          body: user == null
              ? const Center(child: Text("No user logged in"))
              : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : userData == null
                      ? const Center(child: Text("Failed to load profile"))
                      : Column(
                          children: [
                            // Fixed portion of the screen
                            Container(
                              color: const Color(0xFF6246EA),
                              child: SafeArea(
                                bottom: false,
                                child: Column(
                                  children: [
                                    // App Bar-like header
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'My Profile',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.settings, color: Colors.white),
                                            onPressed: () {
                                              _tabController.animateTo(2); // Switch to settings tab
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Profile header - real-time data
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                                      child: Row(
                                        children: [
                                          // Avatar with real-time name initial
                                          Hero(
                                            tag: 'profile_avatar',
                                            child: CircleAvatar(
                                              radius: 40,
                                              backgroundColor: Colors.white,
                                              child: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: Text(
                                                  userData['name']?.toString().isNotEmpty == true
                                                    ? userData['name']!.toString().substring(0, 1).toUpperCase()
                                                    : 'A',
                                                  key: ValueKey(userData['name']),
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Animated name transition for real-time updates
                                                AnimatedSwitcher(
                                                  duration: const Duration(milliseconds: 300),
                                                  child: Text(
                                                    userData['name']?.toString() ?? 'Anonymous User',
                                                    key: ValueKey(userData['name']),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                // Email from Firebase Auth - always real-time
                                                Text(
                                                  user.email ?? 'No email',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                // Last update timestamp
                                                if (userData['lastUpdated'] != null)
                                                  Text(
                                                    'Last updated: ${_formatTimestamp(userData['lastUpdated'])}',
                                                    style: const TextStyle(
                                                      color: Colors.white60,
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            // Stats Cards - Real-time updates
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'RATING',
                                      // Format to one decimal place
                                      value: (userData['rating'] ?? 0.0) is double 
                                          ? (userData['rating'] as double).toStringAsFixed(1)
                                          : (userData['rating'] ?? 0.0).toString(),
                                      icon: Icons.star,
                                      iconColor: Colors.amber,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'SWAPS',
                                      value: (userData['completedSwaps'] ?? 0).toString(),
                                      icon: Icons.swap_horiz,
                                      iconColor: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'MEMBER FOR',
                                      // Calculate in real-time on every build
                                      value: _getMembershipDuration(userData['memberSince']),
                                      icon: Icons.calendar_month,
                                      iconColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Tab Bar
                            TabBar(
                              controller: _tabController,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Theme.of(context).primaryColor,
                              tabs: const [
                                Tab(text: 'About', icon: Icon(Icons.person)),
                                Tab(text: 'Skills', icon: Icon(Icons.lightbulb)),
                                Tab(text: 'Settings', icon: Icon(Icons.settings)),
                              ],
                            ),
                            // Expand to fill the remaining space
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _AboutTabView(userData: userData),
                                  _SkillsTabView(userData: userData),
                                  _SettingsTabView(userData: userData),
                                ],
                              ),
                            ),
                          ],
                        ),
        );
      },
    );
  }

  // Build a card for showing a statistic - real-time updates
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            // Animated value to show transitions for real-time updates
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(
                begin: 0,
                end: 1,
              ),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Text(
                value,
                key: ValueKey(value), // Key based on value for proper rebuilding
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTabView extends StatefulWidget {
  final Map<String, dynamic> userData;

  const _AboutTabView({required this.userData});

  @override
  State<_AboutTabView> createState() => _AboutTabViewState();
}

class _AboutTabViewState extends State<_AboutTabView> {
  final TextEditingController _bioController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.userData['bio']?.toString() ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  // Update bio in real-time
  Future<void> _saveBio() async {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    
    try {
      await userProvider.updateField('bio', _bioController.text);
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update bio: $e')),
      );
    }
  }
  
  // Show availability dialog for real-time editing
  void _showAvailabilityDialog() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    // Convert to string list 
    List<String> convertToStringList(dynamic data) {
      if (data == null) return [];
      
      if (data is String) {
        return [data];
      } else if (data is List) {
        return data.map((item) => item.toString()).toList();
      } else {
        return [];
      }
    }
    
    // Get current availability
    final List<String> currentAvailability = convertToStringList(widget.userData['availability']);
    
    // Create a map of day selections
    final Map<String, bool> selections = {
      for (var day in days) day: currentAvailability.contains(day)
    };
    
    // Use a StatefulBuilder to manage dialog state
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Availability'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: days.map((day) {
                    return CheckboxListTile(
                      title: Text(day),
                      value: selections[day],
                      onChanged: (bool? value) {
                        setDialogState(() {
                          selections[day] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Get selected days
                    final List<String> updatedAvailability = days
                        .where((day) => selections[day] == true)
                        .toList();
                    
                    // Update in database
                    try {
                      final userProvider = Provider.of<UserDataProvider>(context, listen: false);
                      await userProvider.updateField('availability', updatedAvailability);
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update availability: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update controller text if userData changes
    if (!_isEditing && widget.userData['bio'] != _bioController.text) {
      _bioController.text = widget.userData['bio']?.toString() ?? '';
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (_isEditing) {
                      _saveBio();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isEditing
                ? TextField(
                    controller: _bioController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Write something about yourself...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  )
                : Text(
                    widget.userData['bio']?.toString() ?? 'No bio available',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAvailabilityDialog(),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAvailabilitySchedule(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvailabilitySchedule() {
    // Safe conversion from any type to List<String>
    List<String> convertToStringList(dynamic data) {
      if (data == null) return [];
      
      if (data is String) {
        // If it's a single string, wrap it in a list
        return [data];
      } else if (data is List) {
        // If it's already a list, convert each element to String
        return data.map((item) => item.toString()).toList();
      } else {
        // For any other type, return empty list
        return [];
      }
    }
    
    final List<String> availabilityList = convertToStringList(widget.userData['availability']);
    
    // Get the current day of the week
    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Current day status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: availabilityList.contains(currentDay) 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  availabilityList.contains(currentDay)
                      ? Icons.circle
                      : Icons.circle_outlined,
                  color: availabilityList.contains(currentDay)
                      ? Colors.green
                      : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  availabilityList.contains(currentDay)
                      ? 'Available Today'
                      : 'Not Available Today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: availabilityList.contains(currentDay)
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
          // Weekly schedule
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: days.map((day) {
                final isAvailable = availabilityList.contains(day);
                final isToday = day == currentDay;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        color: isAvailable ? Colors.green : Colors.grey,
                        size: isToday ? 22 : 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        day + (isToday ? ' (Today)' : ''),
                        style: TextStyle(
                          fontSize: isToday ? 17 : 16,
                          fontWeight: isToday || isAvailable ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? Colors.black : (isAvailable ? Colors.black87 : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get day name from weekday number
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}

class _SkillsTabView extends StatefulWidget {
  final Map<String, dynamic> userData;

  const _SkillsTabView({required this.userData});

  @override
  State<_SkillsTabView> createState() => _SkillsTabViewState();
}

class _SkillsTabViewState extends State<_SkillsTabView> {
  final TextEditingController _newSkillController = TextEditingController();
  bool _addingOfferedSkill = true;
  
  @override
  void dispose() {
    _newSkillController.dispose();
    super.dispose();
  }

  // Add a skill in real-time to the database
  Future<void> _addSkill(String skill, bool isOffered) async {
    if (skill.isEmpty) return;
    
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    
    try {
      List<String> convertToStringList(dynamic data) {
        if (data == null) return [];
        
        if (data is String) {
          return [data];
        } else if (data is List) {
          return data.map((item) => item.toString()).toList();
        } else {
          return [];
        }
      }
      
      // Get current skills
      List<String> currentSkills = isOffered 
        ? convertToStringList(widget.userData['skillsOffered'])
        : convertToStringList(widget.userData['skillsWanted']);
      
      // Add new skill if not already present
      if (!currentSkills.contains(skill)) {
        currentSkills.add(skill);
        
        // Update in database
        if (isOffered) {
          await userProvider.updateField('skillsOffered', currentSkills);
        } else {
          await userProvider.updateField('skillsWanted', currentSkills);
        }
      }
      
      // Clear text field
      _newSkillController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add skill: $e')),
      );
    }
  }
  
  // Remove a skill in real-time
  Future<void> _removeSkill(String skill, bool isOffered) async {
    final userProvider = Provider.of<UserDataProvider>(context, listen: false);
    
    try {
      List<String> convertToStringList(dynamic data) {
        if (data == null) return [];
        
        if (data is String) {
          return [data];
        } else if (data is List) {
          return data.map((item) => item.toString()).toList();
        } else {
          return [];
        }
      }
      
      // Get current skills
      List<String> currentSkills = isOffered 
        ? convertToStringList(widget.userData['skillsOffered'])
        : convertToStringList(widget.userData['skillsWanted']);
      
      // Remove the skill
      currentSkills.remove(skill);
      
      // Update in database
      if (isOffered) {
        await userProvider.updateField('skillsOffered', currentSkills);
      } else {
        await userProvider.updateField('skillsWanted', currentSkills);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove skill: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skills I Offer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildSkillPills(
              widget.userData['skillsOffered'] ?? [],
              Theme.of(context).colorScheme.primary,
              true,
            ),
            const SizedBox(height: 16),
            
            // Add skill form
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSkillController,
                    decoration: InputDecoration(
                      hintText: 'Add a new skill...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _addSkill(_newSkillController.text.trim(), _addingOfferedSkill);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_addingOfferedSkill ? 'Add to Offered' : 'Add to Wanted'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Toggle button to switch between adding to offered or wanted
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _addingOfferedSkill = !_addingOfferedSkill;
                  });
                },
                icon: Icon(_addingOfferedSkill 
                  ? Icons.swap_vertical_circle 
                  : Icons.swap_vertical_circle_outlined),
                label: Text('Switch to ${_addingOfferedSkill ? 'Wanted' : 'Offered'} Skills'),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Skills I\'m Looking For',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildSkillPills(
              widget.userData['skillsWanted'] ?? [],
              Theme.of(context).colorScheme.secondary,
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillPills(dynamic skills, Color color, bool isOffered) {
    // Safe conversion from any type to List<String>
    List<String> convertToStringList(dynamic data) {
      if (data == null) return [];
      
      if (data is String) {
        // If it's a single string, wrap it in a list
        return [data];
      } else if (data is List) {
        // If it's already a list, convert each element to String
        return data.map((item) => item.toString()).toList();
      } else {
        // For any other type, return empty list
        return [];
      }
    }
    
    final List<String> skillsList = convertToStringList(skills);
    
    if (skillsList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No skills listed yet'),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skillsList.map((skill) => Chip(
        label: Text(skill),
        backgroundColor: color.withOpacity(0.2),
        labelStyle: TextStyle(color: color.withOpacity(0.8)),
        deleteIcon: const Icon(Icons.cancel, size: 18),
        onDeleted: () => _removeSkill(skill, isOffered),
      )).toList(),
    );
  }
}

class _SettingsTabView extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _SettingsTabView({required this.userData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsButton(
              context,
              icon: Icons.edit,
              title: 'Edit Profile',
              subtitle: 'Update your profile information',
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const ProfileSetupPage())
                );
                // No need to manually refresh as we're using real-time listeners now
              },
            ),
            const SizedBox(height: 16),
            _buildSettingsButton(
              context,
              icon: Icons.notifications,
              title: 'Notification Settings',
              subtitle: 'Manage your notification preferences',
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const NotificationSettingsPage())
                );
                // No need to manually refresh, using real-time listeners
              },
            ),
            const SizedBox(height: 16),
            _buildSettingsButton(
              context,
              icon: Icons.lock,
              title: 'Privacy Settings',
              subtitle: 'Control your privacy preferences',
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const PrivacySettingsPage())
                );
                // No need to manually refresh, using real-time listeners
              },
            ),
            const SizedBox(height: 16),
            // Always show admin panel button (you can adjust this condition as needed)
            _buildSettingsButton(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Admin Panel',
              subtitle: 'Manage users and system settings',
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AdminPage())
                );
              },
            ),
            const SizedBox(height: 16),
            _buildSettingsButton(
              context,
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Log out of your account',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
