import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user_model.dart';

class UserDataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _userData;
  UserModel? _userModel;
  bool _isLoading = true;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  
  UserDataProvider() {
    _initUserListener();
  }
  
  // Getters
  Map<String, dynamic>? get userData => _userData;
  UserModel? get userModel => _userModel;
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
            // Also create a UserModel object for easier access to typed data
            _userModel = UserModel.fromMap(_userData!, user.uid);
          } else {
            // Default data for new users
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
            _userModel = UserModel.fromMap(_userData!, user.uid);
            
            // Create the user document in Firestore
            _firestore.collection('users').doc(user.uid).set(_userData!);
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
  
  // Update user profile data in real-time
  Future<void> updateUserProfile({
    String? name,
    String? bio,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    List<String>? availability,
    String? photoUrl,
  }) async {
    if (_auth.currentUser == null || _userData == null) return;
    
    final Map<String, dynamic> updates = {};
    
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (skillsOffered != null) updates['skillsOffered'] = skillsOffered;
    if (skillsWanted != null) updates['skillsWanted'] = skillsWanted;
    if (availability != null) updates['availability'] = availability;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    
    if (updates.isNotEmpty) {
      try {
        await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updates);
        
        // Data will be automatically updated via the listener
      } catch (e) {
        print('Error updating user data: $e');
        // Could handle error notification here if needed
      }
    }
  }
  
  // Update a single field in real-time
  Future<void> updateField(String field, dynamic value) async {
    if (_auth.currentUser == null) return;
    
    try {
      await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({field: value});
    } catch (e) {
      print('Error updating field $field: $e');
    }
  }
  
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
