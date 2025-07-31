import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/Screen/User/setup.dart';
import '../Admin/Admin.dart'; // Ensure correct path to AdminPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? userData;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Helper method to safely convert any data to List<String>
  List<String> _convertToStringList(dynamic data) {
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

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No logged in user");

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        userData = {
          'name': 'Anonymous User',
          'bio': 'No bio available',
          'skillsOffered': <String>[],
          'skillsWanted': <String>[],
          'availability': <String>[],
          'rating': 0.0,
          'completedSwaps': 0,
          'memberSince': DateTime.now(),
        };
      } else {
        final data = doc.data()!;
        userData = {
          'name': data['name'] ?? 'Anonymous User',
          'bio': data['bio'] ?? 'No bio available',
          'skillsOffered': _convertToStringList(data['skillsOffered']),
          'skillsWanted': _convertToStringList(data['skillsWanted']),
          'availability': _convertToStringList(data['availability']),
          'rating': data['rating'] ?? 0.0,
          'completedSwaps': data['completedSwaps'] ?? 0,
          'memberSince': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e'))
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : _isLoading
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
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                                          ).then((_) => _fetchUserData());
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Profile header and stats
                                _buildProfileHeader(context, user),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        
                        // Stats cards
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildStatsCards(),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tab Bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: colorScheme.primary,
                            unselectedLabelColor: Colors.grey,
                            indicatorSize: TabBarIndicatorSize.label,
                            indicatorColor: colorScheme.primary,
                            tabs: const [
                              Tab(text: 'About'),
                              Tab(text: 'Skills'),
                              Tab(text: 'Settings'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tab View with Expanded to take remaining space
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              SingleChildScrollView(child: _buildAboutTab()),
                              SingleChildScrollView(child: _buildSkillsTab()),
                              SingleChildScrollView(child: _buildSettingsTab(context)),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
  
  // Removed unused _buildProfileAppBar method

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF6246EA).withOpacity(0.2),
            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null || user.photoURL!.isEmpty
                ? const Icon(Icons.person, size: 40, color: Color(0xFF6246EA))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData!['name'],
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? "No email",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${(userData!['rating'] as double).toStringAsFixed(1)} Rating',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.swap_horiz, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${userData!['completedSwaps']} Swaps',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.emoji_events, 
            value: userData!['completedSwaps'].toString(),
            label: "Swaps",
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.star,
            value: (userData!['rating'] as double).toStringAsFixed(1),
            label: "Rating",
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.calendar_today,
            value: _getMembershipDuration(),
            label: "Member",
            color: Colors.purple.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMembershipDuration() {
    final memberSince = userData!['memberSince'] as DateTime;
    final now = DateTime.now();
    final difference = now.difference(memberSince);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m';
    } else {
      return '${difference.inDays}d';
    }
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6246EA),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userData!['bio'],
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6246EA),
            ),
          ),
          const SizedBox(height: 12),
          _buildAvailabilitySchedule(),
          // Add bottom padding to ensure content isn't cut off
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySchedule() {
    // Get availability as a list of strings, using our helper method to handle different data types
    final List<String> availability = _convertToStringList(userData!['availability']);
    final List<String> allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Column(
      mainAxisSize: MainAxisSize.min, // Use minimum space needed
      children: allDays.map((day) {
        final isAvailable = availability.contains(day);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(
                day,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel_outlined,
                color: isAvailable ? Colors.green.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          const Text(
            'Skills I Offer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6246EA),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkillPills(
            userData!['skillsOffered'], // Type casting is now handled in the method
            Colors.blue.shade600,
            Colors.blue.shade50,
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Skills I Want',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6246EA),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkillPills(
            userData!['skillsWanted'], // Type casting is now handled in the method
            Colors.green.shade600,
            Colors.green.shade50,
          ),
          // Add bottom padding to ensure content isn't cut off
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkillPills(dynamic skillsData, Color textColor, Color bgColor) {
    // Convert the skills data to a List<String> safely
    List<String> skills = [];
    
    if (skillsData == null) {
      // No skills data
    } else if (skillsData is String) {
      // Single string
      skills = [skillsData];
    } else if (skillsData is List) {
      // List of something - convert all to strings
      skills = skillsData.map((item) => item.toString()).toList();
    }
    
    if (skills.isEmpty) {
      return Text("No skills added yet", style: TextStyle(color: Colors.grey.shade500));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills.map((skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          skill,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        children: [
          // Edit Profile Button
          _buildSettingsButton(
            icon: Icons.edit,
            label: "Edit Profile",
            color: const Color(0xFF6246EA),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
              ).then((_) => _fetchUserData());
            },
          ),
          
          const SizedBox(height: 16),
          
          // Admin Panel Button
          _buildSettingsButton(
            icon: Icons.admin_panel_settings,
            label: "Admin Panel",
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPage()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Notifications Settings
          _buildSettingsButton(
            icon: Icons.notifications,
            label: "Notification Settings",
            color: Colors.orange.shade700,
            onTap: () {
              // TODO: Add notifications settings page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notification Settings coming soon!")),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Privacy Settings
          _buildSettingsButton(
            icon: Icons.privacy_tip,
            label: "Privacy Settings",
            color: Colors.teal.shade600,
            onTap: () {
              // TODO: Add privacy settings page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Privacy Settings coming soon!")),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Logout Button
          _buildSettingsButton(
            icon: Icons.logout,
            label: "Logout",
            color: Colors.red.shade600,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          
          // Add bottom padding to ensure content isn't cut off
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildSettingsButton({
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
