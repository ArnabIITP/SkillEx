// Forum post model
class ForumPost {
  String id;
  String authorId;
  String content;
  DateTime createdAt;
  List<String> replies;

  ForumPost({required this.id, required this.authorId, required this.content, required this.createdAt, required this.replies});
}
