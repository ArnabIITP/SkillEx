import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _reviews = [];
  bool _sendingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _userData!['id'] = widget.userId;
        });
      }
      
      // Load reviews
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('toUserId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
          
      final reviewsList = <Map<String, dynamic>>[];
      
      for (final doc in reviewsSnapshot.docs) {
        final reviewData = doc.data();
        
        // Get reviewer name and photo
        try {
          final reviewerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(reviewData['fromUserId'])
              .get();
          
          if (reviewerDoc.exists) {
            final reviewerData = reviewerDoc.data()!;
            reviewData['reviewerName'] = reviewerData['name'] ?? 'Anonymous';
            reviewData['reviewerPhoto'] = reviewerData['photoUrl'] ?? '';
          } else {
            reviewData['reviewerName'] = 'Anonymous';
            reviewData['reviewerPhoto'] = '';
          }
        } catch (e) {
          reviewData['reviewerName'] = 'Anonymous';
          reviewData['reviewerPhoto'] = '';
        }
        
        reviewsList.add(reviewData);
      }
      
      setState(() {
        _reviews = reviewsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSwapRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null || _userData == null) return;
    
    setState(() => _sendingRequest = true);
    
    try {
      // Get current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (!currentUserDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete your profile first')),
        );
        setState(() => _sendingRequest = false);
        return;
      }
      
      final currentUserData = currentUserDoc.data()!;
      
      // Create swap request
      await FirebaseFirestore.instance.collection('swipeRequests').add({
        'fromUserId': currentUser.uid,
        'fromName': currentUser.displayName ?? "Anonymous",
        'fromPhoto': currentUser.photoURL ?? "",
        'toUserId': widget.userId,
        'toUserName': _userData!['name'] ?? "User",
        'skillsOffered': currentUserData['skillsOffered'] ?? [],
        'skillsWanted': currentUserData['skillsWanted'] ?? [],
        'availability': currentUserData['availability'] ?? [],
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Add notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.userId,
        'type': 'swap_request',
        'message': '${currentUser.displayName ?? "Someone"} wants to swap skills with you',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'senderName': currentUser.displayName ?? "Anonymous",
        'senderPhoto': currentUser.photoURL ?? "",
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swap request sent successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error sending swap request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
      setState(() => _sendingRequest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF6F6FB),
    body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _userData == null
        ? const Center(child: Text('User not found'))
        : _buildUserProfile(),
  );
  }

  Widget _buildUserProfile() {
    final skillsOffered = List<String>.from(_userData!['skillsOffered'] ?? []);
    final skillsWanted = List<String>.from(_userData!['skillsWanted'] ?? []);
    final availability = List<String>.from(_userData!['availability'] ?? []);
    final rating = (_userData!['rating'] ?? 0.0).toDouble();
    final completedSwaps = _userData!['completedSwaps'] ?? 0;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = currentUserId == widget.userId;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 2,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: const Color(0xFF6246EA),
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: _userData!['photoUrl'] ?? '',
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 70,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => CircleAvatar(
                    radius: 70,
                    backgroundColor: const Color(0xFF6246EA).withOpacity(0.2),
                    child: const Icon(Icons.person, size: 70, color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: 70,
                    backgroundColor: const Color(0xFF6246EA).withOpacity(0.2),
                    child: const Icon(Icons.person, size: 70, color: Colors.white),
                  ),
                ),
              ),
            ),
            title: Container(
              color: const Color(0xFF6246EA).withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Text(
                _userData!['name'] ?? 'Anonymous',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            centerTitle: true,
          ),
        ),
        // User Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating and completed swaps
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 24,
                      ignoreGestures: true,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (_) {},
                    ),
                    const SizedBox(width: 10),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    '$completedSwaps completed skill swaps',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
                const SizedBox(height: 18),
                // Bio
                if (_userData!['bio'] != null && _userData!['bio'].isNotEmpty) ...[
                  const Text(
                    'About Me',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6246EA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_userData!['bio'], style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 22),
                ],
                // Skills Section
                Row(
                  children: const [
                    Icon(Icons.auto_fix_high, color: Color(0xFF6246EA)),
                    SizedBox(width: 8),
                    Text(
                      'Skills Offered',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6246EA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSkillsList(skillsOffered),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Skills Wanted',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSkillsList(skillsWanted, isOffered: false),
                const SizedBox(height: 20),
                // Availability
                Row(
                  children: const [
                    Icon(Icons.access_time, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Availability',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availability.map((day) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(day, style: const TextStyle(fontSize: 13, color: Colors.green)),
                  )).toList(),
                ),
                const SizedBox(height: 22),
                // Swap button (if not current user)
                if (!isCurrentUser) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _sendingRequest ? null : _sendSwapRequest,
                      icon: const Icon(Icons.swap_horiz, color: Colors.white),
                      label: _sendingRequest
                          ? const Text('Sending...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
                          : const Text('Send Swap Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6246EA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                // Reviews section
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6246EA),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        // Reviews list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (_reviews.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No reviews yet', style: TextStyle(fontSize: 15)),
                  ),
                );
              }
              final review = _reviews[index];
              final reviewerName = review['reviewerName'] ?? 'Anonymous';
              final reviewerPhoto = review['reviewerPhoto'] ?? '';
              final rating = (review['rating'] ?? 0.0).toDouble();
              final reviewText = review['review'] ?? '';
              final timestamp = review['timestamp'] as Timestamp?;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CachedNetworkImage(
                            imageUrl: reviewerPhoto,
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              radius: 22,
                              backgroundImage: imageProvider,
                            ),
                            placeholder: (context, url) => CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.person, size: 22, color: Colors.grey),
                            ),
                            errorWidget: (context, url, error) => CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.person, size: 22, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reviewerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (timestamp != null)
                                Text(
                                  _formatDate(timestamp.toDate()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                      if (reviewText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(reviewText, style: const TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                ),
              );
            },
            childCount: _reviews.isEmpty ? 1 : _reviews.length,
          ),
        ),
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 36),
        ),
      ],
    );
  }

  Widget _buildSkillsList(List<String> skills, {bool isOffered = true}) {
    if (skills.isEmpty) {
      return Text(
        isOffered ? 'No skills offered' : 'No skills wanted',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey[600],
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOffered 
              ? Colors.indigo.withOpacity(0.1) 
              : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOffered
                ? Colors.indigo.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Text(
          skill,
          style: TextStyle(
            color: isOffered ? Colors.indigo : Colors.orange[700],
          ),
        ),
      )).toList(),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
