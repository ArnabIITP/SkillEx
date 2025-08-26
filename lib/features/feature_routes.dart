// Centralized routes for new features
import 'package:flutter/material.dart';
import 'gamification/gamification_screen.dart';
import 'verification/verification_screen.dart';
import 'progress/progress_dashboard.dart';
import 'forum/forum_screen.dart';
import 'analytics/analytics_dashboard.dart';

Map<String, WidgetBuilder> featureRoutes = {
  '/gamification': (context) => GamificationScreen(),
  '/verification': (context) => VerificationScreen(),
  '/progress': (context) => ProgressDashboard(),
  '/forum': (context) => ForumScreen(),
  '/analytics': (context) => AnalyticsDashboard(),
};
