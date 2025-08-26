import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'forum_provider.dart';

class ForumScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = 'currentUserId'; // Replace with actual user ID from auth
    final TextEditingController postController = TextEditingController();
    return ChangeNotifierProvider(
      create: (_) => ForumProvider(),
      child: Consumer<ForumProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(title: Text('Community Forum')),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: postController,
                          decoration: InputDecoration(
                            hintText: 'Share something with the community...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (postController.text.trim().isNotEmpty) {
                            await provider.addPost(userId, postController.text.trim());
                            postController.clear();
                          }
                        },
                        child: Text('Post'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.loading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: provider.posts.length,
                          itemBuilder: (context, idx) {
                            final post = provider.posts[idx];
                            final replyController = TextEditingController();
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.content, style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 4),
                                    Text('By: ${post.authorId}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    SizedBox(height: 8),
                                    if (post.replies.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Replies:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ...post.replies.map((r) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                child: Text('- $r'),
                                              )),
                                        ],
                                      ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: replyController,
                                            decoration: InputDecoration(hintText: 'Reply...'),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.send),
                                          onPressed: () async {
                                            if (replyController.text.trim().isNotEmpty) {
                                              await provider.addReply(post.id, replyController.text.trim());
                                              replyController.clear();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
