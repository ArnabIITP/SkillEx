import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String otherUserPhoto;
  final String otherUserId;

  const ChatPage({
    Key? key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _showRatingDialog = false;
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() async {
    if (currentUser == null) return;
    
    // Update unread count to 0 for current user
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .update({
      'unreadCount.${currentUser!.uid}': 0,
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Add message to the chat room's messages collection
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUser!.uid,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update the chat room document with the last message info
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
        // Increment unread count for other user
        'unreadCount.${widget.otherUserId}': FieldValue.increment(1),
      });
      
      // Add a delay before scrolling to ensure the message is rendered
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }
  
  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    try {
      // Add rating document
      await FirebaseFirestore.instance.collection('ratings').add({
        'fromUserId': currentUser!.uid,
        'toUserId': widget.otherUserId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update user's average rating
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final currentRating = userData['rating'] ?? 0.0;
        final completedSwaps = userData['completedSwaps'] ?? 0;
        
        // Calculate new average rating
        final newRating = ((currentRating * completedSwaps) + _rating) / (completedSwaps + 1);
        
        // Update user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.otherUserId)
            .update({
          'rating': newRating,
          'completedSwaps': completedSwaps + 1,
        });
      }
      
      // Add system message about the rating
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'text': '${currentUser!.displayName} rated this skill exchange ${_rating.toStringAsFixed(1)} stars',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'rating',
        'rating': _rating,
      });
      
      // Reset rating dialog state
      setState(() {
        _showRatingDialog = false;
        _rating = 0;
        _reviewController.clear();
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your rating!')),
      );
    } catch (e) {
      print('Error submitting rating: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CachedNetworkImage(
              imageUrl: widget.otherUserPhoto,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 18,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) => CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 18, color: Colors.grey),
              ),
              errorWidget: (context, url, error) => CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.otherUserName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rate),
            tooltip: 'Rate this user',
            onPressed: () {
              setState(() {
                _showRatingDialog = true;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Rating Dialog
          if (_showRatingDialog)
            _buildRatingDialog(),
            
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start a conversation!'),
                  );
                }

                final messages = snapshot.data!.docs;
                
                // Scroll to bottom when messages are loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final senderId = message['senderId'] as String;
                    final isCurrentUser = senderId == currentUser?.uid;
                    final messageType = message['type'] as String? ?? 'text';
                    
                    // Handle different message types
                    if (messageType == 'system' || messageType == 'rating') {
                      return _buildSystemMessage(message);
                    } else {
                      return _buildChatMessage(message, isCurrentUser);
                    }
                  },
                );
              },
            ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.indigo),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message, bool isCurrentUser) {
    final text = message['text'] as String;
    final timestamp = message['timestamp'] as Timestamp?;
    final time = timestamp != null
        ? DateFormat.jm().format(timestamp.toDate())
        : '';

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: isCurrentUser ? Colors.indigo.shade100 : Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> message) {
    final text = message['text'] as String;
    final type = message['type'] as String? ?? 'system';
    final rating = type == 'rating' ? (message['rating'] ?? 0.0) : 0.0;

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (type == 'rating')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RatingBar.builder(
                    initialRating: rating.toDouble(),
                    minRating: 1,
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
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildRatingDialog() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Rate Your Experience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showRatingDialog = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'How was your skill exchange with ${widget.otherUserName}?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              hintText: 'Write a review (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitRating,
              child: const Text('Submit Rating'),
            ),
          ),
        ],
      ),
    );
  }
}
