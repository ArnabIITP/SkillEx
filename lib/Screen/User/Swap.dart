import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';

class Swap extends StatefulWidget {
  const Swap({Key? key}) : super(key: key);

  @override
  State<Swap> createState() => _SwapState();
}

class _SwapState extends State<Swap> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  int _currentIndex = 0;
  Color _backgroundColor = Colors.white;
  bool _isLoading = true;
  bool _sendingRequest = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _cardKey = GlobalKey();
  Offset _dragStart = Offset.zero;
  double _dragX = 0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    
    _loadUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      if (currentUserId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Get current user data to match interests
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
          
      List<String> userSkillsWanted = [];
      if (currentUserDoc.exists) {
        final currentUserData = currentUserDoc.data()!;
        userSkillsWanted = List<String>.from(currentUserData['skillsWanted'] ?? []);
      }
      
      // Get all users
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .get();
      
      // Get users already requested
      final requestedSnapshot = await FirebaseFirestore.instance
          .collection('swipeRequests')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();
          
      final requestedUserIds = requestedSnapshot.docs
          .map((doc) => (doc.data()['toUserId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      
      // Filter and sort users
      final allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        final userId = doc.id;
        final skillsOffered = List<String>.from(data['skillsOffered'] ?? []);
        
        // Calculate match score based on skills offered that match current user's wanted skills
        int matchScore = 0;
        for (final skill in skillsOffered) {
          if (userSkillsWanted.contains(skill)) {
            matchScore++;
          }
        }
        
        return {
          'id': userId,
          'name': data['name'] ?? 'Anonymous',
          'skillsOffered': skillsOffered,
          'skillsWanted': List<String>.from(data['skillsWanted'] ?? []),
          'availability': List<String>.from(data['availability'] ?? []),
          'photoUrl': data['photoUrl'] ?? '',
          'bio': data['bio'] ?? '',
          'rating': data['rating'] ?? 0.0,
          'completedSwaps': data['completedSwaps'] ?? 0,
          'matchScore': matchScore,
        };
      })
      .where((user) => !requestedUserIds.contains(user['id']))
      .toList();
      
      // Sort by match score
      allUsers.sort((a, b) => (b['matchScore'] as int).compareTo(a['matchScore'] as int));
      
      setState(() {
        _users = allUsers;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _likeUser() async {
    if (_currentIndex >= _users.length || _sendingRequest) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to send requests")),
      );
      return;
    }
    
    setState(() => _sendingRequest = true);
    
    try {
      final toUser = _users[_currentIndex];
      
      // Get current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (!currentUserDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete your profile first")),
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
        'toUserId': toUser["id"],
        'toUserName': toUser["name"],
        'skillsOffered': currentUserData['skillsOffered'] ?? [],
        'skillsWanted': currentUserData['skillsWanted'] ?? [],
        'availability': currentUserData['availability'] ?? [],
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Add notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': toUser["id"],
        'type': 'swap_request',
        'message': '${currentUser.displayName ?? "Someone"} wants to swap skills with you',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'senderName': currentUser.displayName ?? "Anonymous",
        'senderPhoto': currentUser.photoURL ?? "",
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request sent to ${toUser["name"]}")),
      );
      
      _nextUser();
    } catch (e) {
      print("Error sending request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request: $e")),
      );
    } finally {
      setState(() => _sendingRequest = false);
    }
  }

  void _rejectUser() {
    _nextUser();
  }

  void _nextUser() {
    if (_currentIndex < _users.length - 1) {
      setState(() {
        _currentIndex++;
        _backgroundColor = Colors.white;
        _dragX = 0;
      });
    } else {
      // No more users, show empty state
      setState(() {
        _backgroundColor = Colors.white;
        _dragX = 0;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX = details.globalPosition.dx - _dragStart.dx;
      
      if (_dragX > 0) {
        _backgroundColor = Color.lerp(
          Colors.white, 
          Colors.green.shade100,
          _dragX.abs() / 150,
        )!;
      } else if (_dragX < 0) {
        _backgroundColor = Color.lerp(
          Colors.white, 
          Colors.red.shade100,
          _dragX.abs() / 150,
        )!;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final cardWidth = MediaQuery.of(context).size.width * 0.7;
    
    if (_dragX.abs() > cardWidth * 0.4 || velocity.abs() > 800) {
      if (_dragX > 0) {
        // Swipe right - Like
        _animateCardOut(true);
      } else {
        // Swipe left - Reject
        _animateCardOut(false);
      }
    } else {
      // Return to center
      setState(() {
        _dragX = 0;
        _backgroundColor = Colors.white;
      });
    }
  }
  
  void _animateCardOut(bool isRight) {
    // Animate card out of screen
    _animationController.forward(from: 0).whenComplete(() {
      if (isRight) {
        _likeUser();
      } else {
        _rejectUser();
      }
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor == Colors.white ? const Color(0xFFF6F6FB) : _backgroundColor,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: const Text(
          "Skill Match",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D2D2D),
            fontSize: 22,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6246EA)),
            onPressed: _isLoading ? null : _loadUsers,
            tooltip: 'Refresh matches',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _users.isEmpty || _currentIndex >= _users.length
              ? _buildEmptyState()
              : _buildSwipeCard(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Finding potential matches...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              "No more matches found",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We've run out of potential skill matches. Check back later or update your profile to find more matches!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeCard() {
    if (_currentIndex >= _users.length) return _buildEmptyState();
    
    final user = _users[_currentIndex];
    final skillsOffered = List<String>.from(user['skillsOffered'] ?? []);
    final skillsWanted = List<String>.from(user['skillsWanted'] ?? []);
    final availability = List<String>.from(user['availability'] ?? []);
    final rating = (user['rating'] as num).toDouble();
    final completedSwaps = user['completedSwaps'] as int;
    final matchScore = user['matchScore'] as int;
    
    final cardTransform = Matrix4.identity()
      ..translate(_dragX + (_animation.value * MediaQuery.of(context).size.width * (_dragX > 0 ? 1 : -1)));
    
    return Column(
      children: [
        const SizedBox(height: 18),
        // Match quality indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Match Quality: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 15,
                ),
              ),
              ...List.generate(5, (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  index < matchScore ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 22,
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Swipe card
        Expanded(
          child: GestureDetector(
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: Center(
              child: Transform(
                transform: cardTransform,
                alignment: Alignment.center,
                child: Card(
                  key: _cardKey,
                  elevation: 10,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.87,
                    height: MediaQuery.of(context).size.height * 0.62,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CachedNetworkImage(
                          imageUrl: user["photoUrl"] ?? '',
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 64,
                            backgroundImage: imageProvider,
                          ),
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.grey[300],
                            ),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            radius: 64,
                            backgroundColor: Colors.grey[300],
                            child: const Icon(Icons.person, size: 64, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          user["name"] ?? 'Anonymous',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 22),
                        Divider(height: 1, color: Colors.grey[200]),
                        const SizedBox(height: 18),
                        // Skills section
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSkillSection('Skills Offered', skillsOffered, Icons.auto_fix_high, Colors.indigo),
                                const SizedBox(height: 18),
                                _buildSkillSection('Skills Wanted', skillsWanted, Icons.search, Colors.orange[700]!),
                                const SizedBox(height: 18),
                                _buildAvailabilitySection(availability),
                                if (user['bio'] != null && user['bio'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  const Text(
                                    'About',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Color(0xFF2D2D2D),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    user['bio'].toString(),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Swipe hint text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'Swipe right to connect, left to pass',
            style: TextStyle(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: _sendingRequest ? null : _rejectUser,
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                elevation: 5,
                mini: false,
                heroTag: 'reject',
                child: const Icon(Icons.close, size: 34),
              ),
              const SizedBox(width: 36),
              FloatingActionButton(
                onPressed: _sendingRequest ? null : _likeUser,
                backgroundColor: _sendingRequest ? Colors.grey : const Color(0xFF6246EA),
                foregroundColor: Colors.white,
                elevation: 5,
                heroTag: 'like',
                child: _sendingRequest
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check, size: 34),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSkillSection(String title, List<String> skills, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        skills.isEmpty
            ? Text(
                'None specified',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[500]),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                )).toList(),
              ),
      ],
    );
  }
  
  Widget _buildAvailabilitySection(List<String> availability) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.access_time, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Availability',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        availability.isEmpty
            ? Text(
                'None specified',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[500]),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availability.map((day) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    day,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                )).toList(),
              ),
      ],
    );
  }
}
