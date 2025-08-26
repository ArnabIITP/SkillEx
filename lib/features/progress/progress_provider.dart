import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'progress_model.dart';

class ProgressProvider extends ChangeNotifier {
  Progress? _progress;
  final String userId;

  ProgressProvider({required this.userId}) {
    _fetchProgress();
  }

  Progress? get progress => _progress;

  Future<void> _fetchProgress() async {
    final doc = await FirebaseFirestore.instance.collection('progress').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _progress = Progress(
        totalSessions: data['totalSessions'] ?? 0,
        totalMessages: data['totalMessages'] ?? 0,
        totalTasks: data['totalTasks'] ?? 0,
        skills: (data['skills'] as List<dynamic>? ?? []).map((s) => SkillProgress(
          skillName: s['skillName'],
          sessionsCompleted: s['sessionsCompleted'] ?? 0,
          avgQuizScore: (s['avgQuizScore'] ?? 0).toDouble(),
          streakDays: s['streakDays'] ?? 0,
          peerRating: (s['peerRating'] ?? 0).toDouble(),
        )).toList(),
      );
    } else {
      _progress = Progress(totalSessions: 0, totalMessages: 0, totalTasks: 0, skills: []);
    }
    notifyListeners();
  }

  Future<void> updateSkill(String skill, {int? sessionInc, double? quizScore, double? peerRating}) async {
    if (_progress == null) return;
    var skillProg = _progress!.skills.firstWhere(
      (s) => s.skillName == skill,
      orElse: () => SkillProgress(skillName: skill, sessionsCompleted: 0, avgQuizScore: 0, streakDays: 0, peerRating: 0),
    );
    if (!_progress!.skills.contains(skillProg)) {
      _progress!.skills.add(skillProg);
    }
    if (sessionInc != null) skillProg.sessionsCompleted += sessionInc;
    if (quizScore != null) skillProg.avgQuizScore = (skillProg.avgQuizScore + quizScore) / 2;
    if (peerRating != null) skillProg.peerRating = (skillProg.peerRating + peerRating) / 2;
    // Streak logic: increment if session today, else reset
    skillProg.streakDays = (sessionInc != null && sessionInc > 0) ? skillProg.streakDays + 1 : 0;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance.collection('progress').doc(userId).set({
      'totalSessions': _progress!.totalSessions,
      'totalMessages': _progress!.totalMessages,
      'totalTasks': _progress!.totalTasks,
      'skills': _progress!.skills.map((s) => {
        'skillName': s.skillName,
        'sessionsCompleted': s.sessionsCompleted,
        'avgQuizScore': s.avgQuizScore,
        'streakDays': s.streakDays,
        'peerRating': s.peerRating,
      }).toList(),
    });
  }
}
