// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationBloc {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //  Stream controller for any changes in the user
  final StreamController<User?> _userController = StreamController<User?>();

  // Stream for the user
  Stream<User?> get user => _userController.stream;

  // Constructor for the AuthenticationBloc
  AuthenticationBloc() {
    _auth.authStateChanges().listen((User? user) {
      _userController.add(user);
    });
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final user = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Add the user details to the Firestore to the users collection
      await firestore.collection('users').add({
        'username': name,
        'email': email,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
        'user_id': user.user?.uid,
      });
    } catch (e) {
      print('Sign up error: $e');
    }
  }

  // Sign out the user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Get the current user id
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  // Get the current user name who is logged in
  Future<String?> getCurrentUserName() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = await firestore
        .collection('users')
        .where('user_id', isEqualTo: _auth.currentUser?.uid)
        .get();

    return user.docs[0].data()['username'];
  }

  // Update the user details(basic information)
  Future<bool> updateUserDetails(
      {required String name,
      required DateTime dob,
      required String gender}) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final user = await firestore
          .collection('users')
          .where('user_id', isEqualTo: _auth.currentUser?.uid)
          .get();
      await firestore.collection('users').doc(user.docs[0].id).update({
        'username': name,
        'dob': dob,
        'gender': gender,
        'updated_at': DateTime.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get the user details who is logged in
  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final user = await firestore
          .collection('users')
          .where('user_id', isEqualTo: _auth.currentUser?.uid)
          .get();

      return user.docs[0].data();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  // Get the user details by user id
  Future<Map<String, dynamic>> getUserDetailsById(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = await firestore
        .collection('users')
        .where('user_id', isEqualTo: userId)
        .get();

    return user.docs[0].data();
  }

  // Check if the user is authenticated
  // Generally used to check if the user is logged in or not
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Dispose the stream controller
  void dispose() {
    _userController.close();
  }
}
