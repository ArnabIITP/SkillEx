import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<DocumentSnapshot> _allUsers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupRealtimeUpdates();
    _fetchAdminStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _usersSubscription?.cancel();
    super.dispose();
  }

  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  
  // Method to start listening to real-time updates
  void _setupRealtimeUpdates() {
    // Cancel any existing subscription
    _usersSubscription?.cancel();
    
    // Set up real-time listener
    _usersSubscription = _firestore.collection('users').snapshots().listen((snapshot) {
      setState(() {
        _allUsers = snapshot.docs;
        _isLoading = false;
      });
      
      // Also update stats when users change
      _fetchAdminStats();
    }, onError: (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error in real-time updates: $e")),
      );
    });
  }
  
  // Legacy method - now just initiates loading state
  Future<void> _fetchAllUsers() async {
    setState(() => _isLoading = true);
    // Real-time updates will handle the actual data loading
    _setupRealtimeUpdates();
  }
  
  Future<void> _fetchAdminStats() async {
    try {
      // Get total number of users
      final userCount = await _firestore.collection('users').count().get();
      
      // Get total number of swaps (assuming a swaps collection)
      final swapsCount = await _firestore.collection('swaps').count().get();
      
      // Get active skills (unique)
      final users = await _firestore.collection('users').get();
      Set<String> uniqueSkills = {};
      int totalSkillsOffered = 0;
      
      for (var doc in users.docs) {
        final data = doc.data();
        final skills = List<String>.from(data['skillsOffered'] ?? []);
        uniqueSkills.addAll(skills);
        totalSkillsOffered += skills.length;
      }
      
      setState(() {
        _stats = {
          'userCount': userCount.count,
          'swapsCount': swapsCount.count,
          'uniqueSkillsCount': uniqueSkills.length,
          'totalSkillsOffered': totalSkillsOffered,
        };
      });
    } catch (e) {
      print("Error fetching admin stats: $e");
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Only delete from Auth if the admin is deleting their own account (FirebaseAuth cannot delete other users directly)
      if (_auth.currentUser?.uid == uid) {
        await _auth.currentUser!.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User deleted successfully")),
      );

      _fetchAllUsers(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete user: $e")),
      );
    }
  }

  void _confirmDelete(String uid, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete $name's account?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(uid);
            },
          ),
        ],
      ),
    );
  }

  List<DocumentSnapshot> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    
    return _allUsers.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final skills = (data['skillsOffered'] as List?)?.join(" ").toLowerCase() ?? '';
      
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query) || skills.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: false,
            backgroundColor: const Color(0xFF6246EA),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1557683311-eac922347aa1?ixlib=rb-4.0.3',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  _fetchAllUsers();
                  _fetchAdminStats();
                },
              ),
            ],
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
        ],
        body: Column(
          children: [
            // Dashboard Stats Cards
            if (!_isLoading) _buildStatsSection(),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name, email or skills',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  Tab(text: 'Users'),
                  Tab(text: 'Skills'),
                  Tab(text: 'Reports'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(),
                  _buildSkillsTab(),
                  _buildReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          _showAddSkillDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6246EA),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.people,
                value: _stats['userCount']?.toString() ?? '0',
                label: 'Total Users',
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.swap_horiz,
                value: _stats['swapsCount']?.toString() ?? '0',
                label: 'Total Swaps',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.lightbulb,
                value: _stats['uniqueSkillsCount']?.toString() ?? '0',
                label: 'Unique Skills',
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Icons.auto_awesome,
                value: _stats['totalSkillsOffered']?.toString() ?? '0',
                label: 'Skills Offered',
                color: Colors.purple,
              ),
            ],
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
                fontSize: 22,
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

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_allUsers.isEmpty) {
      return const Center(child: Text("No users found"));
    }
    
    final filteredUsers = _filteredUsers;
    
    if (filteredUsers.isEmpty) {
      return const Center(child: Text("No matching users found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final data = user.data() as Map<String, dynamic>;
        final uid = user.id;
        final name = data['name'] ?? 'Unnamed';
        final email = data['email'] ?? 'No email';
        final skills = (data['skillsOffered'] as List?)?.join(", ") ?? 'None';
        final photoUrl = data['photoUrl'] as String?;
        final rating = (data['rating'] ?? 0.0) as double;
        final isAdmin = (data['isAdmin'] ?? false) as bool;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6246EA).withOpacity(0.1),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 30, color: Color(0xFF6246EA))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      if (skills != 'None')
                        Text(
                          'Skills: $skills',
                          style: const TextStyle(fontSize: 14),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${rating.toStringAsFixed(1)} Rating'),
                            ],
                          ),
                          Row(
                            children: [
                              _buildUserActionButton(
                                icon: Icons.edit,
                                color: Colors.blue,
                                onTap: () {
                                  // TODO: Implement user edit functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Edit user feature coming soon")),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildUserActionButton(
                                icon: Icons.block,
                                color: Colors.orange,
                                onTap: () {
                                  // TODO: Implement block user functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Block user feature coming soon")),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildUserActionButton(
                                icon: Icons.delete,
                                color: Colors.red,
                                onTap: () => _confirmDelete(uid, name),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUserActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
  
  Widget _buildSkillsTab() {
    // Extract all skills and count their occurrences
    Map<String, int> skillCounts = {};
    for (final user in _allUsers) {
      final data = user.data() as Map<String, dynamic>;
      final skills = List<String>.from(data['skillsOffered'] ?? []);
      for (final skill in skills) {
        skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
      }
    }
    
    // Sort skills by count
    final sortedSkills = skillCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedSkills.isEmpty) {
      return const Center(child: Text("No skills found in the system"));
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Most Popular Skills',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6246EA),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Skill"),
                onPressed: () => _showAddSkillDialog(),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sortedSkills.length,
            itemBuilder: (context, index) {
              final skill = sortedSkills[index].key;
              final count = sortedSkills[index].value;
              
              final percentage = (count / _allUsers.length) * 100;
              
              // Generate a color based on the skill name
              final hue = (skill.hashCode % 360).toDouble();
              final color = HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.auto_awesome, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '$count ${count == 1 ? "user" : "users"} (${percentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              // TODO: Implement skill edit functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Edit skill feature coming soon")),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: count / _allUsers.length,
                          backgroundColor: Colors.grey.shade200,
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildReportsTab() {
    // This would typically show user reports, system notifications, etc.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Detailed Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6246EA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comprehensive analytics and reports coming soon',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reports feature coming soon")),
              );
            },
            icon: const Icon(Icons.info_outline),
            label: const Text('Learn More'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAddSkillDialog() {
    final TextEditingController skillNameController = TextEditingController();
    final TextEditingController skillDescriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Skill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: skillNameController,
              decoration: const InputDecoration(
                labelText: 'Skill Name',
                hintText: 'e.g., Piano Teaching',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: skillDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Skill Description (Optional)',
                hintText: 'Provide details about this skill',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement adding skill to firestore
              final skillName = skillNameController.text.trim();
              if (skillName.isNotEmpty) {
                // Add skill to a 'skills' collection in Firestore
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Skill '$skillName' added successfully")),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Add Skill'),
          ),
        ],
      ),
    );
  }
}