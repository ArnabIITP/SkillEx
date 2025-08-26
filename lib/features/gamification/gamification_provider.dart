import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gamification_model.dart';

class GamificationProvider extends ChangeNotifier {
  Gamification? _gamification;
  final String userId;

  GamificationProvider({required this.userId}) {
    _fetchGamification();
  }

  Gamification? get gamification => _gamification;

  Future<void> _fetchGamification() async {
    final doc = await FirebaseFirestore.instance.collection('gamification').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _gamification = Gamification(
        points: data['points'] ?? 0,
        level: data['level'] ?? 1,
        badges: List<String>.from(data['badges'] ?? []),
      );
    } else {
      _gamification = Gamification(points: 0, level: 1, badges: []);
    }
    notifyListeners();
  }

  Future<void> addPoints(int points) async {
    if (_gamification == null) return;
    _gamification!.points += points;
    // Level up logic (example: every 100 points)
    _gamification!.level = 1 + (_gamification!.points ~/ 100);
    await _save();
    notifyListeners();
  }

  Future<void> addBadge(String badge) async {
    if (_gamification == null) return;
    if (!_gamification!.badges.contains(badge)) {
      _gamification!.badges.add(badge);
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance.collection('gamification').doc(userId).set({
      'points': _gamification!.points,
      'level': _gamification!.level,
      'badges': _gamification!.badges,
    });
  }
}
