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
    
    // Make sure the provider is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserDataProvider>(context, listen: false);
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get membership duration
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
    
    final now = DateTime.now();
    final difference = now.difference(date);
    final days = difference.inDays;
    
    if (days < 30) {
      return '$days days';
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
                                    
                                    // Profile header
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 40,
                                            backgroundColor: Colors.white,
                                            child: Text(
                                              userData['name']?.toString().substring(0, 1).toUpperCase() ?? 'A',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userData['name']?.toString() ?? 'Anonymous User',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  user.email ?? 'No email',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
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
                            // Stats Cards
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      label: 'RATING',
                                      value: (userData['rating'] ?? 0.0).toString(),
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

  // Build a card for showing a statistic
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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

class _AboutTabView extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _AboutTabView({required this.userData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Me',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userData['bio']?.toString() ?? 'No bio available',
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Availability',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAvailabilitySchedule(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvailabilitySchedule() {
    final availability = userData['availability'] as List<dynamic>? ?? [];
    final List<String> availabilityList = availability.map((item) => item.toString()).toList();
    
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: days.map((day) {
            final isAvailable = availabilityList.contains(day);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isAvailable ? Icons.check_circle : Icons.cancel,
                    color: isAvailable ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                      color: isAvailable ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SkillsTabView extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _SkillsTabView({required this.userData});

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
              userData['skillsOffered'] ?? [],
              Theme.of(context).colorScheme.primary,
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
              userData['skillsWanted'] ?? [],
              Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillPills(List<dynamic> skills, Color color) {
    final List<String> skillsList = skills.map((item) => item.toString()).toList();
    
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
                ).then((_) => Provider.of<UserDataProvider>(context, listen: false).refreshUserData());
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
                ).then((_) => Provider.of<UserDataProvider>(context, listen: false).refreshUserData());
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
                ).then((_) => Provider.of<UserDataProvider>(context, listen: false).refreshUserData());
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
