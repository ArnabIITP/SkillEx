import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'user_detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = [
    'All', 
    'Design', 
    'Programming', 
    'Music', 
    'Languages',
    'Marketing', 
    'Fitness', 
    'Cooking',
    'Photography',
    'Writing'
  ];
  // Set for multiple category selection, starting with 'All'
  Set<String> selectedCategories = {'All'};
  String searchQuery = '';
  bool isLoading = true;
  List<Map<String, dynamic>> users = [];
  
  final TextEditingController _searchController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .get();
      
      final fetchedUsers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Anonymous',
          'skillsOffered': data['skillsOffered'] ?? [],
          'skillsWanted': data['skillsWanted'] ?? [],
          'availability': data['availability'] ?? [],
          'photoUrl': data['photoUrl'] ?? '',
          'rating': data['rating'] ?? 0.0,
          'completedSwaps': data['completedSwaps'] ?? 0,
          'bio': data['bio'] ?? '',
        };
      }).toList();
      
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    List<Map<String, dynamic>> result = List.from(users);
    
    // Filter by selected categories
    if (!(selectedCategories.contains('All') || selectedCategories.isEmpty)) {
      // Only filter if 'All' is not selected and categories are not empty
      result = result.where((user) {
        final skillsOffered = (user['skillsOffered'] as List<dynamic>)
            .map((skill) => skill.toString().toLowerCase())
            .toList();
        final skillsWanted = (user['skillsWanted'] as List<dynamic>)
            .map((skill) => skill.toString().toLowerCase())
            .toList();
        
        // Match if any selected category is found in user's skills
        return selectedCategories.any((category) {
          final categoryLower = category.toLowerCase();
          return skillsOffered.any((skill) => skill.contains(categoryLower)) ||
                 skillsWanted.any((skill) => skill.contains(categoryLower));
        });
      }).toList();
    }
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((user) {
        final name = user['name'].toString().toLowerCase();
        final bio = user['bio'].toString().toLowerCase();
        final skillsOffered = (user['skillsOffered'] as List<dynamic>)
            .map((skill) => skill.toString().toLowerCase())
            .join(' ');
        final skillsWanted = (user['skillsWanted'] as List<dynamic>)
            .map((skill) => skill.toString().toLowerCase())
            .join(' ');
        
        return name.contains(query) || 
               bio.contains(query) || 
               skillsOffered.contains(query) || 
               skillsWanted.contains(query);
      }).toList();
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final username = FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? '';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              Text(
                '$greeting${username.isNotEmpty ? ', $username' : ''}! 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Find the perfect skill swap match',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),

              // Search bar
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(30),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search skills or users...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6246EA)),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  style: const TextStyle(fontSize: 16),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Filter button
              Row(
                children: [
                  Text(
                    'Filter by skills:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.filter_list, size: 20),
                    label: Text(selectedCategories.contains('All') ? 'All' : '${selectedCategories.length} selected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6246EA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // User count or loading indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: isLoading
                    ? const Text('Loading users...')
                    : Text(
                        '${filteredUsers.length} users found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(height: 10),

              // User cards
              Expanded(
                child: isLoading
                    ? _buildLoadingShimmer()
                    : filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchUsers,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return _buildUserCard(user);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    // Create a temporary set to hold selections during dialog
    Set<String> tempSelectedCategories = Set.from(selectedCategories);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Skills'),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: List.generate(categories.length, (index) {
                      final category = categories[index];
                      final isSelected = tempSelectedCategories.contains(category);
                      
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6246EA),
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setDialogState(() {
                            if (category == 'All') {
                              // When selecting "All", clear all other selections
                              tempSelectedCategories.clear();
                              tempSelectedCategories.add('All');
                            } else {
                              // When selecting others, remove "All"
                              tempSelectedCategories.remove('All');
                              
                              // Toggle the selected category
                              if (isSelected) {
                                tempSelectedCategories.remove(category);
                                // If no categories left, reselect "All"
                                if (tempSelectedCategories.isEmpty) {
                                  tempSelectedCategories.add('All');
                                }
                              } else {
                                tempSelectedCategories.add(category);
                              }
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Apply'),
                onPressed: () {
                  setState(() {
                    selectedCategories = tempSelectedCategories;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final skillsOffered = (user['skillsOffered'] as List<dynamic>)
        .map((skill) => skill.toString())
        .toList();
    final skillsWanted = (user['skillsWanted'] as List<dynamic>)
        .map((skill) => skill.toString())
        .toList();
    final availability = (user['availability'] as List<dynamic>)
        .map((day) => day.toString())
        .toList();
    final rating = (user['rating'] as num).toDouble();
    final completedSwaps = user['completedSwaps'] as int;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailPage(userId: user['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // User photo
                  CachedNetworkImage(
                    imageUrl: user['photoUrl'] ?? '',
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 32,
                      backgroundImage: imageProvider,
                    ),
                    placeholder: (context, url) => CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 32, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 32, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 18),
                  // Name and rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            RatingBar.builder(
                              initialRating: rating,
                              minRating: 0,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 18,
                              ignoreGestures: true,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (_) {},
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($completedSwaps)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 14),
              // Skills section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skills offered
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.auto_fix_high, size: 16, color: Colors.indigo),
                            SizedBox(width: 4),
                            Text(
                              'OFFERS',
                              style: TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: skillsOffered.map((skill) => _buildSkillChip(skill, true)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Skills wanted
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.search, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'WANTS',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: skillsWanted.map((skill) => _buildSkillChip(skill, false)).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Availability
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Available: ${availability.join(", ")}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D2D2D)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill, bool isOffered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOffered ? const Color(0xFF6246EA).withOpacity(0.12) : Colors.orange.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOffered ? const Color(0xFF6246EA).withOpacity(0.25) : Colors.orange.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isOffered ? const Color(0xFF6246EA) : Colors.orange[800],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(height: 180),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search criteria',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}
