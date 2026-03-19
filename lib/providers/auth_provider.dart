import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Email/Password Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _fetchUserData(userCredential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      // Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user exists in Firestore, if not create new user
        await _handleSocialSignIn(userCredential.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Google sign-in error: $e');
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Facebook Sign In (Updated for version 7.1.0)
  Future<bool> signInWithFacebook() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Trigger Facebook login flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get the access token
        final AccessToken accessToken = result.accessToken!;

        // Create a credential from the access token
        final OAuthCredential credential =
        FacebookAuthProvider.credential(accessToken.tokenString);

        // Sign in to Firebase with the Facebook credential
        final UserCredential userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          // Check if user exists in Firestore, if not create new user
          await _handleSocialSignIn(userCredential.user!);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else if (result.status == LoginStatus.cancelled) {
        // User cancelled the login
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (result.status == LoginStatus.failed) {
        // Login failed
        _isLoading = false;
        notifyListeners();
        throw Exception('Facebook login failed: ${result.message}');
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Facebook sign-in error: $e');
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Handle social sign-in (common for Google and Facebook)
  Future<void> _handleSocialSignIn(User firebaseUser) async {
    try {
      // Check if user already exists in Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // Get additional user info for social logins
        String? userName = firebaseUser.displayName;
        String? userEmail = firebaseUser.email;

        // If display name is not available, use email username
        if (userName == null || userName.isEmpty) {
          userName = userEmail?.split('@').first ?? 'User';
        }

        // Create new user in Firestore
        final userMap = {
          'uid': firebaseUser.uid,
          'name': userName,
          'email': userEmail ?? '',
          'age': 0,
          'address': '',
          'latitude': 0.0,
          'longitude': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isSocialLogin': true,
          'photoUrl': firebaseUser.photoURL,
        };

        await _firestore.collection('users').doc(firebaseUser.uid).set(userMap);
        _user = UserModel.fromMap(userMap);
      } else {
        // User exists, fetch data
        _user = UserModel.fromFirestore(userDoc);
      }

      _isAuthenticated = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error handling social sign-in: $e');
      }
      rethrow;
    }
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData(String uid) async {
    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        _user = UserModel.fromFirestore(userDoc);
        _isAuthenticated = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user data: $e');
      }
      rethrow;
    }
  }

  // Registration
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: userData['password'],
      );

      if (userCredential.user != null) {
        // Prepare user data for Firestore
        final userMap = {
          'uid': userCredential.user!.uid,
          'name': userData['name'],
          'email': userData['email'],
          'age': userData['age'],
          'address': userData['address'],
          'latitude': userData['latitude'],
          'longitude': userData['longitude'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isSocialLogin': false,
          'photoUrl': '',
        };

        // Save user data to Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userMap);

        // Update local user state
        _user = UserModel.fromMap(userMap);
        _isAuthenticated = true;

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        await _fetchUserData(currentUser.uid);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();

      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) {
        print('Password reset error: $e');
      }
      rethrow;
    }
  }
}