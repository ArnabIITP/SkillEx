import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  UserModel? _currentUser;
  bool _loading = false;
  String _error = '';
  int _unreadNotifications = 0;

  UserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String get error => _error;
  int get unreadNotifications => _unreadNotifications;

  AppState() {
    initializeUser();
  }

  // Listen to auth state changes and update user accordingly
  void initializeUser() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchUserData(user.uid);
        await _fetchNotificationCount();
      } else {
        _currentUser = null;
        _unreadNotifications = 0;
        notifyListeners();
      }
    });
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, userId);
      } else {
        // Create a basic user record if it doesn't exist
        final User? authUser = _auth.currentUser;
        if (authUser != null) {
          _currentUser = UserModel(
            id: authUser.uid,
            email: authUser.email ?? '',
            name: authUser.displayName ?? 'User',
            photoUrl: authUser.photoURL ?? '',
          );
          
          await _firestore.collection('users').doc(userId).set(_currentUser!.toMap());
        }
      }
    } catch (e) {
      _error = 'Failed to load user data: $e';
      print(_error);
    }

    _loading = false;
    notifyListeners();
  }

  // Fetch unread notification count
  Future<void> _fetchNotificationCount() async {
    if (_currentUser == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUser!.id)
          .where('read', isEqualTo: false)
          .get();
      
      _unreadNotifications = snapshot.docs.length;
      notifyListeners();
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // Mark notifications as read
  Future<void> markNotificationsAsRead() async {
    if (_currentUser == null) return;
    
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUser!.id)
          .where('read', isEqualTo: false)
          .get();
      
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      
      await batch.commit();
      _unreadNotifications = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  // Sign in user
  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up new user
  Future<bool> signUp(String email, String password, String name) async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Update display name
      await credential.user?.updateDisplayName(name);
      
      // Create user in Firestore
      final newUser = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
      );
      
      await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());
      
      _loading = false;
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    if (_currentUser == null) return;
    
    _loading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toMap());
      _currentUser = updatedUser;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      print(_error);
    }

    _loading = false;
    notifyListeners();
  }

  // Upload profile image
  Future<String?> uploadProfileImage(File image) async {
    if (_currentUser == null) return null;
    
    _loading = true;
    notifyListeners();

    try {
      final ref = _storage.ref().child('profile_images/${_currentUser!.id}');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update user photo URL
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(photoUrl: downloadUrl);
        await updateUserProfile(updatedUser);
        
        // Also update in Firebase Auth
        await _auth.currentUser?.updatePhotoURL(downloadUrl);
      }
      
      _loading = false;
      notifyListeners();
      return downloadUrl;
    } catch (e) {
      _error = 'Failed to upload image: $e';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  // Add a new swap request
  Future<bool> sendSwapRequest(Map<String, dynamic> requestData) async {
    if (_currentUser == null) return false;
    
    try {
      await _firestore.collection('swipeRequests').add(requestData);
      
      // Add notification for recipient
      await _firestore.collection('notifications').add({
        'userId': requestData['toUserId'],
        'type': 'swap_request',
        'message': '${_currentUser!.name} wants to swap skills with you',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'senderName': _currentUser!.name,
        'senderPhoto': _currentUser!.photoUrl,
      });
      
      return true;
    } catch (e) {
      _error = 'Failed to send request: $e';
      print(_error);
      return false;
    }
  }

  // Rate a user after skill exchange
  Future<bool> rateUser(String userId, double rating, String review) async {
    if (_currentUser == null) return false;
    
    try {
      // Add the rating document
      await _firestore.collection('ratings').add({
        'fromUserId': _currentUser!.id,
        'toUserId': userId,
        'rating': rating,
        'review': review,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update the user's average rating
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final currentRating = userData['rating'] ?? 0.0;
        final completedSwaps = userData['completedSwaps'] ?? 0;
        
        // Calculate new average rating
        final newRating = ((currentRating * completedSwaps) + rating) / (completedSwaps + 1);
        
        // Update user document
        await _firestore.collection('users').doc(userId).update({
          'rating': newRating,
          'completedSwaps': completedSwaps + 1,
        });
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to rate user: $e';
      print(_error);
      return false;
    }
  }
}
