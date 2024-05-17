// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationBloc {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamController<User?> _userController = StreamController<User?>();

  Stream<User?> get user => _userController.stream;

  AuthenticationBloc() {
    _auth.authStateChanges().listen((User? user) {
      _userController.add(user);
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // } catch (e) {
    //   // Handle error
    //   print('Sign in error: $e');
    // }
  }

  Future<void> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      final user = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      await firestore.collection('users').add({
        'username': name,
        'email': email,
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
        'user_id': user.user?.uid,
        // You can add more fields as needed
      });
    } catch (e) {
      // Handle error
      print('Sign up error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Handle error
      print('Sign out error: $e');
    }
  }

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<String?> getCurrentUserName() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = await firestore
        .collection('users')
        .where('user_id', isEqualTo: _auth.currentUser?.uid)
        .get();

    return user.docs[0].data()['username'];
  }

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

  Future<Map<String, dynamic>> getUserDetails() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = await firestore
        .collection('users')
        .where('user_id', isEqualTo: _auth.currentUser?.uid)
        .get();

    return user.docs[0].data();
  }

  Future<Map<String, dynamic>> getUserDetailsById(String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final user = await firestore
        .collection('users')
        .where('user_id', isEqualTo: userId)
        .get();

    return user.docs[0].data();
  }

  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  void dispose() {
    _userController.close();
  }
}
