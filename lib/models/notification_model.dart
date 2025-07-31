class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String message;
  final DateTime timestamp;
  final bool read;
  final String senderName;
  final String senderPhoto;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.read,
    required this.senderName,
    required this.senderPhoto,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      senderName: data['senderName'] ?? '',
      senderPhoto: data['senderPhoto'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'message': message,
      'timestamp': timestamp,
      'read': read,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
    };
  }
}
