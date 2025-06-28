import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyAuthProvider with ChangeNotifier {
  User? _user;
  String? _role;
  bool _isLoading = true;
  bool _isInitialized = false;

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  MyAuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    debugPrint('MyAuthProvider: Initializing auth...');

    try {
      _isLoading = true;
      notifyListeners();

      _user = FirebaseAuth.instance.currentUser;

      if (_user != null) {
        debugPrint('MyAuthProvider: Found existing user: ${_user!.uid}');
        await _fetchAndSetRole(_user!.uid);
      } else {
        debugPrint('MyAuthProvider: No existing user found');
        _role = null;
      }

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();

      // Listen for auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        debugPrint('MyAuthProvider: Auth state changed - User: ${user?.uid}');

        if (_user?.uid != user?.uid) {
          _user = user;

          if (user != null) {
            debugPrint(
                'MyAuthProvider: User authenticated, fetching role for UID: ${user.uid}');
            await _fetchAndSetRole(user.uid);
          } else {
            debugPrint('MyAuthProvider: User signed out, clearing role');
            _role = null;
          }

          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('MyAuthProvider: Error during initialization: $e');
      _user = null;
      _role = null;
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndSetRole(String uid) async {
    try {
      debugPrint('MyAuthProvider: Fetching role for UID: $uid');
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        _role = userDoc.data()?['role'] as String? ?? 'user';
        debugPrint('MyAuthProvider: Role fetched: $_role');
      } else {
        debugPrint(
            'MyAuthProvider: User document does not exist, defaulting to user role');
        _role = 'user';
      }
    } catch (e) {
      debugPrint('MyAuthProvider: Error fetching role: $e');
      _role = 'user';
    }
  }

  Future<String?> getUserRole(String uid) async {
    if (_user == null) {
      debugPrint('MyAuthProvider: No user, returning null role');
      return null;
    }
    if (_role != null) {
      debugPrint('MyAuthProvider: Returning cached role: $_role');
      return _role;
    }
    await _fetchAndSetRole(uid);
    return _role;
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('MyAuthProvider: Signing up user with email: $email');
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        debugPrint(
            'MyAuthProvider: User created, UID: ${credential.user!.uid}');

        // Create user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'email': email,
          'name': name,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'uid': credential.user!.uid,
        });

        _user = credential.user;
        _role = 'user';
        debugPrint('MyAuthProvider: User role set to: $_role');
      }
    } catch (e) {
      debugPrint('MyAuthProvider: Sign-up error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('MyAuthProvider: Logging in user with email: $email');
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      _user = credential.user;
      if (_user != null) {
        await _fetchAndSetRole(_user!.uid);
      }
    } catch (e) {
      debugPrint('MyAuthProvider: Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('MyAuthProvider: Logging out user');
      await FirebaseAuth.instance.signOut();

      // Clear user data
      _user = null;
      _role = null;

      debugPrint('MyAuthProvider: User data cleared');
    } catch (e) {
      debugPrint('MyAuthProvider: Logout error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint(
          'MyAuthProvider: Updating user profile for UID: $uid with data: $data');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(data);

      if (data.containsKey('role')) {
        _role = data['role'] as String?;
        debugPrint('MyAuthProvider: Role updated to: $_role');
      }
    } catch (e) {
      debugPrint('MyAuthProvider: Update profile error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void syncWithFirebaseUser(User user) {
    // Implementation if needed
  }
}
