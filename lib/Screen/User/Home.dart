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
  int selectedCategoryIndex = 0;
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
    
    // Filter by category
    if (selectedCategoryIndex != 0) {
      final selectedCategory = categories[selectedCategoryIndex].toLowerCase();
      result = result.where((user) {
        final skillsOffered = (user['skillsOffered'] as List<dynamic>)
            .map((skill) => skill.toString().toLowerCase())
            .toList();
        final skillsWanted = (user['skillsWanted'] as List<dynamic>)
            .map((skill) => skill.toString().toLowerCase())
            .toList();
        
        return skillsOffered.any((skill) => skill.contains(selectedCategory)) ||
               skillsWanted.any((skill) => skill.contains(selectedCategory));
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              Text(
                '$greeting${username.isNotEmpty ? ', $username' : ''}! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find the perfect skill swap match',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search skills or users...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Categories
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == selectedCategoryIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(categories[index]),
                        selected: isSelected,
                        selectedColor: Colors.indigo,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() => selectedCategoryIndex = index);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // User count or loading indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: isLoading
                    ? const Text('Loading users...')
                    : Text(
                        '${filteredUsers.length} users found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const SizedBox(height: 8),

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
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailPage(userId: user['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // User photo
                  CachedNetworkImage(
                    imageUrl: user['photoUrl'] ?? '',
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 30,
                      backgroundImage: imageProvider,
                    ),
                    placeholder: (context, url) => CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Name and rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
                              itemSize: 16,
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
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
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
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: skillsOffered.map((skill) => _buildSkillChip(skill, true)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
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
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: skillsWanted.map((skill) => _buildSkillChip(skill, false)).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Availability
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Available: ${availability.join(", ")}',
                    style: const TextStyle(fontSize: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOffered ? Colors.indigo.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOffered ? Colors.indigo.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: isOffered ? Colors.indigo : Colors.orange[700],
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
