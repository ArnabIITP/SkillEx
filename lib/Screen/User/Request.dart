import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/app_state.dart';
import 'chat_page.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> with SingleTickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Mark notifications as read when opening this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.unreadNotifications > 0) {
        appState.markNotificationsAsRead();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _acceptRequest(String docId, Map<String, dynamic> data) async {
    // First create a chat room between the users
    final chatRoomId = _getChatRoomId(currentUserId, data["fromUserId"]);
    
    // Create or update the chat room document
    await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).set({
      'users': [currentUserId, data["fromUserId"]],
      'userNames': {
        currentUserId: FirebaseAuth.instance.currentUser?.displayName ?? "You",
        data["fromUserId"]: data["fromName"],
      },
      'userPhotos': {
        currentUserId: FirebaseAuth.instance.currentUser?.photoURL ?? "",
        data["fromUserId"]: data["fromPhoto"],
      },
      'lastMessage': "Swap request accepted! You can start chatting now.",
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
      'unreadCount': {
        currentUserId: 0,
        data["fromUserId"]: 1,
      },
    }, SetOptions(merge: true));
    
    // Add initial system message
    await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).collection('messages').add({
      'senderId': 'system',
      'text': 'Skill swap matched! ${FirebaseAuth.instance.currentUser?.displayName ?? "User"} accepted the swap request.',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'system',
    });
    
    // Add notification for the other user
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': data["fromUserId"],
      'type': 'request_accepted',
      'message': '${FirebaseAuth.instance.currentUser?.displayName ?? "Someone"} accepted your skill swap request!',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'senderName': FirebaseAuth.instance.currentUser?.displayName ?? "User",
      'senderPhoto': FirebaseAuth.instance.currentUser?.photoURL ?? "",
    });
    
    // Delete the request
    await FirebaseFirestore.instance.collection('swipeRequests').doc(docId).delete();
    
    // Navigate to chat
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomId,
          otherUserName: data["fromName"],
          otherUserPhoto: data["fromPhoto"],
          otherUserId: data["fromUserId"],
        ),
      ),
    );
  }
  
  Future<void> _rejectRequest(String docId) async {
    await FirebaseFirestore.instance.collection('swipeRequests').doc(docId).delete();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request rejected")),
    );
  }
  
  String _getChatRoomId(String userId1, String userId2) {
    // Create a consistent chat room ID regardless of order
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_${userId2}'
        : '${userId2}_${userId1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FB),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: const Text(
          "My Connections",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D2D2D),
            fontSize: 22,
            letterSpacing: 0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6246EA),
              unselectedLabelColor: Colors.grey,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(width: 4.0, color: Color(0xFF6246EA)),
                insets: const EdgeInsets.symmetric(horizontal: 32.0),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [
                Tab(text: "REQUESTS"),
                Tab(text: "CHATS"),
              ],
            ),
          ),
        ),
      ),
      body: currentUserId.isEmpty
          ? const Center(child: Text("Please log in to view requests and chats."))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildChatsTab(),
              ],
            ),
    );
  }
  
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('swipeRequests')
          .where('toUserId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_add_disabled,
            title: "No requests yet",
            message: "When someone wants to swap skills with you, their requests will appear here.",
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final docId = requests[index].id;
            
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null 
                ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                : 'Recently';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CachedNetworkImage(
                          imageUrl: data["fromPhoto"] ?? "",
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data["fromName"] ?? "User",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: Colors.grey[200]),
                    const SizedBox(height: 14),
                    _buildSkillItem("Offers", data["skillsOffered"], Icons.auto_fix_high),
                    const SizedBox(height: 8),
                    _buildSkillItem("Wants", data["skillsWanted"], Icons.search),
                    const SizedBox(height: 8),
                    _buildSkillItem("Available", data["availability"], Icons.access_time),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _rejectRequest(docId),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Decline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _acceptRequest(docId, data),
                          icon: const Icon(Icons.check),
                          label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6246EA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .where('users', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            title: "No chats yet",
            message: "When you connect with someone, your conversations will appear here.",
          );
        }

        final chatRooms = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final data = chatRooms[index].data() as Map<String, dynamic>;
            final chatRoomId = chatRooms[index].id;
            
            // Find the other user ID
            final users = List<String>.from(data['users'] ?? []);
            final otherUserId = users.firstWhere(
              (id) => id != currentUserId,
              orElse: () => "",
            );
            
            if (otherUserId.isEmpty) return const SizedBox.shrink();
            
            final userNames = data['userNames'] as Map<String, dynamic>?;
            final userPhotos = data['userPhotos'] as Map<String, dynamic>?;
            
            final otherUserName = userNames?[otherUserId] ?? "User";
            final otherUserPhoto = userPhotos?[otherUserId] ?? "";
            
            final lastMessage = data['lastMessage'] as String? ?? "No messages yet";
            final lastMessageTime = data['lastMessageTime'] as Timestamp?;
            final formattedTime = lastMessageTime != null
                ? _formatLastMessageTime(lastMessageTime.toDate())
                : "";
                
            final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                leading: CachedNetworkImage(
                  imageUrl: otherUserPhoto,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 26,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                title: Text(
                  otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF2D2D2D)),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadCount > 0 ? const Color(0xFF6246EA) : Colors.grey[700],
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (formattedTime.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6246EA),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatRoomId: chatRoomId,
                        otherUserName: otherUserName,
                        otherUserPhoto: otherUserPhoto,
                        otherUserId: otherUserId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkillItem(String label, dynamic value, IconData icon) {
    final displayValue = value is List ? value.join(', ') : value.toString();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$label:",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.indigo,
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }
}
