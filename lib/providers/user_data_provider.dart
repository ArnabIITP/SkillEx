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
    
    // Listen to real-time user data updates
    _userSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((docSnapshot) async {
          if (docSnapshot.exists) {
            _userData = docSnapshot.data();
            _userData!['id'] = user.uid;
            
            // Make sure memberSince is always a timestamp
            if (_userData!['memberSince'] == null) {
              // If memberSince is missing, set it to now
              final timestamp = Timestamp.now();
              await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'memberSince': timestamp});
              _userData!['memberSince'] = timestamp;
            }
            
            // Fetch real-time ratings
            try {
              // Get the average rating from ratings collection
              final ratingsSnapshot = await _firestore
                .collection('ratings')
                .where('userId', isEqualTo: user.uid)
                .get();
              
              if (ratingsSnapshot.docs.isNotEmpty) {
                double totalRating = 0;
                for (var doc in ratingsSnapshot.docs) {
                  totalRating += (doc.data()['rating'] ?? 0).toDouble();
                }
                double averageRating = totalRating / ratingsSnapshot.docs.length;
                
                // Update rating in userData
                _userData!['rating'] = averageRating;
                
                // Also update in Firestore for persistence
                await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .update({'rating': averageRating});
              }
              
              // Fetch completed swaps count
              final swapsSnapshot = await _firestore
                .collection('swaps')
                .where('participants', arrayContains: user.uid)
                .where('status', isEqualTo: 'completed')
                .get();
              
              // Update completed swaps count
              int completedSwapsCount = swapsSnapshot.docs.length;
              _userData!['completedSwaps'] = completedSwapsCount;
              
              // Also update in Firestore for persistence
              await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'completedSwaps': completedSwapsCount});
              
            } catch (e) {
              print('Error fetching real-time metrics: $e');
              // Continue with existing data even if metrics update fails
            }
            
            // Create UserModel with updated data
            _userModel = UserModel.fromMap(_userData!, user.uid);
          } else {
            // Create new user document with current timestamp
            final timestamp = Timestamp.now();
            _userData = {
              'name': user.displayName ?? 'Anonymous User',
              'bio': 'No bio available',
              'skillsOffered': [],
              'skillsWanted': [],
              'availability': [],
              'rating': 0.0,
              'completedSwaps': 0,
              'memberSince': timestamp,
              'id': user.uid
            };
            _userModel = UserModel.fromMap(_userData!, user.uid);
            
            // Create the user document in Firestore
            await _firestore.collection('users').doc(user.uid).set(_userData!);
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
      // Update the field in Firestore
      await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({field: value});
      
      // Add a timestamp for the last update
      await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'lastUpdated': FieldValue.serverTimestamp()});
      
      // Track the change in activity log for analytics
      try {
        await _firestore.collection('activityLogs').add({
          'userId': _auth.currentUser!.uid,
          'action': 'profile_update',
          'field': field,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (logError) {
        // Non-critical error - don't stop execution if logging fails
        print('Error logging activity: $logError');
      }
      
    } catch (e) {
      print('Error updating field $field: $e');
      throw e; // Re-throw to allow UI to handle the error
    }
  }
  
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
