import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Swap extends StatefulWidget {
  const Swap({Key? key}) : super(key: key);

  @override
  State<Swap> createState() => _SwapState();
}

class _SwapState extends State<Swap> {
  final List<Map<String, String>> users = [
    {
      "uid": "user_001",
      "name": "Aryan Singh",
      "skillsOffered": "Flutter, UI/UX",
      "skillsWanted": "Photoshop",
      "availability": "Weekends",
      "photoUrl": "https://via.placeholder.com/100"
    },
    {
      "uid": "user_002",
      "name": "Sneha Roy",
      "skillsOffered": "Python, ML",
      "skillsWanted": "Guitar",
      "availability": "Evenings",
      "photoUrl": "https://via.placeholder.com/100"
    },
    {
      "uid": "user_003",
      "name": "John Doe",
      "skillsOffered": "Public Speaking",
      "skillsWanted": "Web Design",
      "availability": "Anytime",
      "photoUrl": "https://via.placeholder.com/100"
    },
  ];

  int currentIndex = 0;
  Color backgroundColor = Colors.white;

  void _likeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("User not logged in");
      return;
    }

    final toUser = users[currentIndex];

    await FirebaseFirestore.instance.collection('swipeRequests').add({
      'fromUserId': currentUser.uid,
      'fromName': currentUser.displayName ?? "Anonymous",
      'fromPhoto': currentUser.photoURL ?? "",
      'toUserId': toUser["uid"] ?? "",
      'toUserName': toUser["name"],
      'skillsOffered': toUser["skillsOffered"],
      'skillsWanted': toUser["skillsWanted"],
      'availability': toUser["availability"],
      'photoUrl': toUser["photoUrl"],
      'timestamp': FieldValue.serverTimestamp(),
    });

    _nextUser();
  }

  void _rejectUser() {
    _nextUser();
  }

  void _nextUser() {
    setState(() {
      currentIndex++;
      backgroundColor = Colors.white;
    });
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    setState(() {
      if (details.delta.dx > 0) {
        backgroundColor = Colors.green.shade100;
      } else if (details.delta.dx < 0) {
        backgroundColor = Colors.red.shade100;
      }
    });
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (backgroundColor == Colors.green.shade100) {
      _likeUser();
    } else if (backgroundColor == Colors.red.shade100) {
      _rejectUser();
    } else {
      setState(() => backgroundColor = Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= users.length) {
      return Scaffold(
        appBar: AppBar(title: const Text("Swap"), backgroundColor: Colors.indigo),
        body: const Center(child: Text("No more users to swap")),
      );
    }

    final user = users[currentIndex];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Swap"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: _handleSwipeUpdate,
              onPanEnd: _handleSwipeEnd,
              child: Center(
                child: Card(
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 420,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(user["photoUrl"]!),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user["name"]!,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text("🛠️ Offers: ${user["skillsOffered"]}"),
                        Text("🎯 Wants: ${user["skillsWanted"]}"),
                        Text("⏰ ${user["availability"]}"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => backgroundColor = Colors.red.shade100);
                    Future.delayed(const Duration(milliseconds: 200), _rejectUser);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => backgroundColor = Colors.green.shade100);
                    Future.delayed(const Duration(milliseconds: 200), _likeUser);
                  },
                  icon: const Icon(Icons.favorite),
                  label: const Text("Accept"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
