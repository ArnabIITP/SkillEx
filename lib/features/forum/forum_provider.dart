import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forum_model.dart';

class ForumProvider extends ChangeNotifier {
  List<ForumPost> _posts = [];
  bool _loading = false;

  List<ForumPost> get posts => _posts;
  bool get loading => _loading;

  ForumProvider() {
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    _loading = true;
    notifyListeners();
    final snapshot = await FirebaseFirestore.instance.collection('forum_posts').orderBy('createdAt', descending: true).get();
    _posts = snapshot.docs.map((doc) {
      final data = doc.data();
      return ForumPost(
        id: doc.id,
        authorId: data['authorId'],
        content: data['content'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        replies: List<String>.from(data['replies'] ?? []),
      );
    }).toList();
    _loading = false;
    notifyListeners();
  }

  Future<void> addPost(String authorId, String content) async {
    final post = ForumPost(
      id: '',
      authorId: authorId,
      content: content,
      createdAt: DateTime.now(),
      replies: [],
    );
    await FirebaseFirestore.instance.collection('forum_posts').add({
      'authorId': post.authorId,
      'content': post.content,
      'createdAt': post.createdAt,
      'replies': post.replies,
    });
    await fetchPosts();
  }

  Future<void> addReply(String postId, String reply) async {
    final postRef = FirebaseFirestore.instance.collection('forum_posts').doc(postId);
    await postRef.update({
      'replies': FieldValue.arrayUnion([reply]),
    });
    await fetchPosts();
  }
}
