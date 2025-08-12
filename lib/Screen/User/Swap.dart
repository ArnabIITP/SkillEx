import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' show pi;

class Swap extends StatefulWidget {
  const Swap({Key? key}) : super(key: key);

  @override
  State<Swap> createState() => _SwapState();
}

class _SwapState extends State<Swap> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _swipedUsers = [];
  int _currentIndex = 0;
  Color _backgroundColor = Colors.white;
  bool _isLoading = true;
  bool _isProcessingAction = false;
  late AnimationController _animationController;
  Offset _dragStart = Offset.zero;
  double _dragX = 0;
  double _dragY = 0;
  double _dragRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
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
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      List<String> userSkillsWanted = [];
      if (currentUserDoc.exists) {
        final currentUserData = currentUserDoc.data()!;
        userSkillsWanted =
        List<String>.from(currentUserData['skillsWanted'] ?? []);
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .get();
      final requestedSnapshot = await FirebaseFirestore.instance
          .collection('swipeRequests')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();
      final requestedUserIds = requestedSnapshot.docs
          .map((doc) => (doc.data()['toUserId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        final userId = doc.id;
        final skillsOffered = List<String>.from(data['skillsOffered'] ?? []);
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
      }).where((user) => !requestedUserIds.contains(user['id'])).toList();
      allUsers.sort((a, b) =>
          (b['matchScore'] as int).compareTo(a['matchScore'] as int));

      if (mounted) {
        setState(() {
          _users = allUsers;
          _swipedUsers = [];
          _currentIndex = 0;
          _isLoading = false;
          _dragX = 0;
          _dragRotation = 0.0;
          _dragY = 0.0;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendLikeRequest(Map<String, dynamic> toUser) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!currentUserDoc.exists) return;
      final currentUserData = currentUserDoc.data()!;
      await FirebaseFirestore.instance.collection('swipeRequests').add({
        'fromUserId': currentUser.uid,
        'fromName': currentUserData['name'] ?? "Anonymous",
        'fromPhoto': currentUserData['photoUrl'] ?? "",
        'toUserId': toUser["id"],
        'toUserName': toUser["name"],
        'skillsOffered': currentUserData['skillsOffered'] ?? [],
        'skillsWanted': currentUserData['skillsWanted'] ?? [],
        'availability': currentUserData['availability'] ?? [],
        'timestamp': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': toUser["id"],
        'type': 'swap_request',
        'message':
        '${currentUserData['name'] ?? "Someone"} wants to swap skills with you',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'senderId': currentUser.uid,
        'senderName': currentUserData['name'] ?? "Anonymous",
        'senderPhoto': currentUserData['photoUrl'] ?? "",
      });
    } catch (e) {
      print("Error sending request (background): $e");
    }
  }

  Future<void> _addToFavoritesBackend(Map<String, dynamic> favUser) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('favorites').add({
        'userId': currentUser.uid,
        'favoriteUserId': favUser['id'],
        'favoriteUserName': favUser['name'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding favorite (background): $e");
    }
  }

  void _nextUser() {
    if (_currentIndex < _users.length) {
      _swipedUsers.add(_users[_currentIndex]);
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
      }
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (_isProcessingAction) return;
    _dragStart = details.globalPosition;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isProcessingAction) return;
    setState(() {
      _dragX = details.globalPosition.dx - _dragStart.dx;
      _dragY = details.globalPosition.dy - _dragStart.dy;
      _dragRotation =
          _dragX / (MediaQuery.of(context).size.width * 0.8) * 0.2;
      final screenWidth = MediaQuery.of(context).size.width;
      final dragPercentageX = _dragX / screenWidth;
      final dragPercentageY = _dragY / MediaQuery.of(context).size.height;
      final redColor = Color.lerp(
          Colors.white, Colors.red.shade100, -dragPercentageX.clamp(-1.0, 0.0))!;
      final greenColor = Color.lerp(
          Colors.white, Colors.green.shade100, dragPercentageX.clamp(0.0, 1.0))!;
      final blueColor = Color.lerp(
          Colors.white, Colors.blue.shade100, -dragPercentageY.clamp(-1.0, 0.0))!;
      if (_dragY.abs() > _dragX.abs() && _dragY < -8) {
        _backgroundColor = blueColor;
      } else if (_dragX > 0) {
        _backgroundColor = greenColor;
      } else if (_dragX < 0) {
        _backgroundColor = redColor;
      } else {
        _backgroundColor = Colors.white;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isProcessingAction) return;
    final velocity = details.velocity.pixelsPerSecond;
    final cardWidth = MediaQuery.of(context).size.width * 0.7;
    final cardHeight = MediaQuery.of(context).size.height * 0.4;
    if (_dragX.abs() > cardWidth * 0.4 || velocity.dx.abs() > 800) {
      _animateCardOut(_dragX > 0);
      return;
    }
    if (_dragY < -cardHeight * 0.2 || velocity.dy < -800) {
      _animateCardUp();
      return;
    }
    _animateCardBack();
  }

  void _animateCardOut(bool isRight) {
    if (_currentIndex >= _users.length) return;
    setState(() => _isProcessingAction = true);
    final screenWidth = MediaQuery.of(context).size.width;
    final startX = _dragX;
    final startRotation = _dragRotation;
    final endX = isRight ? screenWidth * 1.5 : -screenWidth * 1.5;
    final endRotation = isRight ? startRotation + 0.5 : startRotation - 0.5;
    _animationController.reset();
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    animation.addListener(() {
      setState(() {
        _dragX = startX + (endX - startX) * animation.value;
        _dragRotation =
            startRotation + (endRotation - startRotation) * animation.value;
      });
    });
    _animationController.forward(from: 0).whenComplete(() {
      final targetUser = _users[_currentIndex];
      if (isRight) {
        Future.microtask(() => _sendLikeRequest(targetUser));
      }
      _nextUser();
      if (mounted) {
        setState(() {
          _dragX = 0;
          _dragY = 0;
          _dragRotation = 0.0;
          _backgroundColor = Colors.white;
          _isProcessingAction = false;
        });
      }
    });
  }

  void _animateCardUp() {
    if (_currentIndex >= _users.length) return;
    setState(() => _isProcessingAction = true);
    final screenHeight = MediaQuery.of(context).size.height;
    final startY = _dragY;
    final endY = -screenHeight * 1.5;
    final startRotation = _dragRotation;
    _animationController.reset();
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    animation.addListener(() {
      setState(() {
        _dragY = startY + (endY - startY) * animation.value;
        _dragRotation = startRotation * (1 - animation.value);
      });
    });
    _animationController.forward(from: 0).whenComplete(() {
      final targetUser = _users[_currentIndex];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Added ${targetUser['name']} to favorites")),
        );
      }
      Future.microtask(() => _addToFavoritesBackend(targetUser));
      _nextUser();
      if (mounted) {
        setState(() {
          _dragX = 0;
          _dragY = 0;
          _dragRotation = 0.0;
          _backgroundColor = Colors.white;
          _isProcessingAction = false;
        });
      }
    });
  }

  void _animateCardBack() {
    setState(() => _isProcessingAction = true);
    final startX = _dragX;
    final startY = _dragY;
    final startRotation = _dragRotation;
    _animationController.reset();
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    animation.addListener(() {
      setState(() {
        _dragX = startX * (1 - animation.value);
        _dragY = startY * (1 - animation.value);
        _dragRotation = startRotation * (1 - animation.value);
      });
    });
    _animationController.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() {
          _dragX = 0;
          _dragY = 0;
          _dragRotation = 0.0;
          _backgroundColor = Colors.white;
          _isProcessingAction = false;
        });
      }
    });
  }

  void _onRewind() {
    if (_swipedUsers.isNotEmpty && !_isProcessingAction && _currentIndex > 0) {
      final lastSwipedUser = _swipedUsers.removeLast();
      setState(() {
        _currentIndex--;
        _users.insert(_currentIndex, lastSwipedUser);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rewinded to the previous card")),
      );
    } else if (_swipedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No cards to rewind")),
      );
    }
  }

  void _onDislike() {
    if (_isLoading || _isProcessingAction || _currentIndex >= _users.length) return;
    _animateCardOut(false);
  }

  void _onFavorite() {
    if (_isLoading || _isProcessingAction || _currentIndex >= _users.length) return;
    _animateCardUp();
  }

  void _onLike() {
    if (_isLoading || _isProcessingAction || _currentIndex >= _users.length) return;
    _animateCardOut(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // Calculate progress from 0.0 to 1.0 based on how far the card is dragged
          final likeProgress = (_dragX / (screenWidth * 0.5)).clamp(0.0, 1.0);
          final dislikeProgress = (-_dragX / (screenWidth * 0.5)).clamp(0.0, 1.0);
          final favoriteProgress = (-_dragY / (screenHeight * 0.4)).clamp(0.0, 1.0);

          return _isLoading
              ? _buildLoadingState()
              : _users.isEmpty || _currentIndex >= _users.length
              ? _buildEmptyState()
              : Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentIndex + 1 < _users.length)
                      _buildSwipeCard(
                        _users[_currentIndex + 1],
                        isBackCard: true,
                      ),
                    _buildSwipeCard(_users[_currentIndex]),
                  ],
                ),
              ),
              _buildActionButtons(
                likeProgress: likeProgress,
                dislikeProgress: dislikeProgress,
                favoriteProgress: favoriteProgress,
              ),
            ],
          );
        },
      ),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "We've run out of potential skill matches. Check back later or update your profile to find more!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons({
    required double likeProgress,
    required double dislikeProgress,
    required double favoriteProgress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            actionColor: Colors.amber,
            icon: Icons.undo,
            onPressed: _onRewind,
          ),
          _buildCircleButton(
            actionColor: Colors.red,
            icon: Icons.close,
            onPressed: _onDislike,
            scale: 1.0 + (0.25 * dislikeProgress),
            activationProgress: dislikeProgress,
          ),
          _buildCircleButton(
            actionColor: Colors.blue,
            icon: Icons.star,
            onPressed: _onFavorite,
            scale: 1.0 + (0.25 * favoriteProgress),
            activationProgress: favoriteProgress,
          ),
          _buildCircleButton(
            actionColor: Colors.green,
            icon: Icons.favorite,
            onPressed: _onLike,
            scale: 1.0 + (0.25 * likeProgress),
            activationProgress: likeProgress,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color actionColor,
    required VoidCallback onPressed,
    double scale = 1.0,
    double activationProgress = 0.0,
  }) {
    // Interpolate colors based on the activation progress
    final Color backgroundColor =
    Color.lerp(Colors.white, actionColor, activationProgress)!;
    final Color iconColor =
    Color.lerp(actionColor, Colors.white, activationProgress)!;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: 64,
        height: 64,
        // This container is for sizing and shadow
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // The Material widget handles the color and the ink splash effect
        child: Material(
          color: backgroundColor, // Set the dynamic color HERE
          shape: const CircleBorder(),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                color: iconColor, // Use the dynamic icon color
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeCard(Map<String, dynamic> user, {bool isBackCard = false}) {
    final dragPercentageX =
        _dragX.abs() / (MediaQuery.of(context).size.width * 0.4);
    final dragPercentageY =
        _dragY.abs() / (MediaQuery.of(context).size.height * 0.4);
    final dragPercentage = (dragPercentageX + dragPercentageY).clamp(0.0, 1.0);
    final scale = 0.9 + (0.1 * (1 - dragPercentage));
    final backCardTransform = Matrix4.identity()..scale(scale);
    final currentCardTransform = Matrix4.identity()
      ..translate(_dragX, _dragY)
      ..rotateZ(_dragRotation);
    final showFavoriteOverlay =
        _dragY.abs() > _dragX.abs() && _dragY < -8;

    Widget card = _buildCardContent(user);

    if (isBackCard) {
      return Transform(
        key: ValueKey("back_${user['id']}"),
        transform: backCardTransform,
        alignment: Alignment.center,
        child: card,
      );
    }

    return GestureDetector(
      key: ValueKey(user['id']),
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onVerticalDragEnd: _handleDragEnd,
      child: Transform(
        transform: currentCardTransform,
        alignment: Alignment.center,
        child: Stack(
          children: [
            card,
            if (_dragX > 0) _buildLikeOverlay(),
            if (_dragX < 0) _buildDislikeOverlay(),
            if (showFavoriteOverlay) _buildFavoriteOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeOverlay() {
    final opacity =
    (_dragX / (MediaQuery.of(context).size.width * 0.4)).clamp(0.0, 1.0);
    return Positioned(
      top: 40,
      left: 20,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: -pi / 12.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.7)),
            child: const Text(
              "LIKE",
              style: TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDislikeOverlay() {
    final opacity =
    (-_dragX / (MediaQuery.of(context).size.width * 0.4)).clamp(0.0, 1.0);
    return Positioned(
      top: 40,
      right: 20,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: pi / 12.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.7)),
            child: const Text(
              "NOPE",
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteOverlay() {
    final opacity =
    (_dragY.abs() / (MediaQuery.of(context).size.height * 0.3))
        .clamp(0.0, 1.0);
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.7)),
            child: const Text(
              "FAVORITE",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(Map<String, dynamic> user) {
    final skillsOffered = List<String>.from(user['skillsOffered'] ?? []);
    final skillsWanted = List<String>.from(user['skillsWanted'] ?? []);
    final availability = List<String>.from(user['availability'] ?? []);
    final rating = (user['rating'] as num).toDouble();
    final completedSwaps = user['completedSwaps'] as int;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.87,
      height: MediaQuery.of(context).size.height * 0.62,
      child: Card(
        elevation: 10,
        shadowColor: Colors.black12,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
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
                  child:
                  const Icon(Icons.person, size: 64, color: Colors.grey),
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
                textAlign: TextAlign.center,
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkillSection('Skills Offered', skillsOffered,
                          Icons.auto_fix_high, Colors.indigo),
                      const SizedBox(height: 18),
                      _buildSkillSection('Skills Wanted', skillsWanted,
                          Icons.search, Colors.orange[700]!),
                      const SizedBox(height: 18),
                      _buildAvailabilitySection(availability),
                      if (user['bio'] != null &&
                          user['bio'].toString().isNotEmpty) ...[
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
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            height: 1.4,
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
    );
  }

  Widget _buildSkillSection(
      String title, List<String> skills, IconData icon, Color color) {
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
          style: TextStyle(
              fontStyle: FontStyle.italic, color: Colors.grey[500]),
        )
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map((skill) => Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              skill,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ))
              .toList(),
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
          style: TextStyle(
              fontStyle: FontStyle.italic, color: Colors.grey[500]),
        )
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availability
              .map((day) => Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              day,
              style: const TextStyle(
                  color: Colors.green, fontSize: 12),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}