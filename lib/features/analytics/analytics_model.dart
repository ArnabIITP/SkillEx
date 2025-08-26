// Analytics event model
class AnalyticsEvent {
  String eventType;
  String userId;
  DateTime timestamp;
  Map<String, dynamic> details;

  AnalyticsEvent({required this.eventType, required this.userId, required this.timestamp, required this.details});
}
