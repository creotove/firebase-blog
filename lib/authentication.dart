import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationBloc {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamController<User?> _userController = StreamController<User?>();

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

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
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

  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  void dispose() {
    _userController.close();
  }
}
