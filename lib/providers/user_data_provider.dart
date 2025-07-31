import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';

class UserDataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  
  UserDataProvider() {
    _initUserListener();
  }
  
  // Getters
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  
  // Initialize real-time user data listener
  void _initUserListener() {
    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _userSubscription?.cancel();
    _isLoading = true;
    notifyListeners();
    
    _userSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((docSnapshot) {
          if (docSnapshot.exists) {
            _userData = docSnapshot.data();
            _userData!['id'] = user.uid;
          } else {
            _userData = {
              'name': 'Anonymous User',
              'bio': 'No bio available',
              'skillsOffered': [],
              'skillsWanted': [],
              'availability': [],
              'rating': 0.0,
              'completedSwaps': 0,
              'memberSince': DateTime.now(),
              'id': user.uid
            };
          }
          _isLoading = false;
          notifyListeners();
        }, onError: (e) {
          print('Error getting user data: $e');
          _isLoading = false;
          notifyListeners();
        });
  }
  
  // Helper method to safely convert any data to List<String>
  List<String> convertToStringList(dynamic data) {
    if (data == null) return [];
    
    if (data is String) {
      // If it's a single string, wrap it in a list
      return [data];
    } else if (data is List) {
      // If it's already a list, convert each element to String
      return data.map((item) => item.toString()).toList();
    } else {
      // For any other type, return empty list
      return [];
    }
  }
  
  // Refresh user data (manually trigger)
  void refreshUserData() {
    _initUserListener();
  }
  
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
