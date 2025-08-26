import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_model.dart';

class AnalyticsProvider extends ChangeNotifier {
  List<AnalyticsEvent> _events = [];
  bool _loading = false;

  List<AnalyticsEvent> get events => _events;
  bool get loading => _loading;

  Future<void> logEvent(String eventType, String userId, Map<String, dynamic> details) async {
    final event = AnalyticsEvent(
      eventType: eventType,
      userId: userId,
      timestamp: DateTime.now(),
      details: details,
    );
    await FirebaseFirestore.instance.collection('analytics').add({
      'eventType': event.eventType,
      'userId': event.userId,
      'timestamp': event.timestamp,
      'details': event.details,
    });
  }

  Future<void> fetchEvents({String? userId}) async {
    _loading = true;
    notifyListeners();
    Query query = FirebaseFirestore.instance.collection('analytics').orderBy('timestamp', descending: true);
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    final snapshot = await query.limit(100).get();
    _events = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return AnalyticsEvent(
        eventType: data['eventType'],
        userId: data['userId'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        details: Map<String, dynamic>.from(data['details'] ?? {}),
      );
    }).toList();
    _loading = false;
    notifyListeners();
  }
}
