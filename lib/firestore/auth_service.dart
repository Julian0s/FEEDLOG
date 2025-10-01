import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication service for Firebase Auth
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
      await user.reload();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      await user.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateWithCredential(String email, String password) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in anonymously (for guest access)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions and convert to user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Invalid password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error'}';
    }
  }
}

/// Provider wrapper for AuthService
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  String? get currentUserId => _authService.currentUserId;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthProvider() {
    // Listen to auth state changes and notify listeners
    _authService.authStateChanges.listen((_) => notifyListeners());
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) =>
      _authService.signInWithEmailAndPassword(email, password);

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) =>
      _authService.createUserWithEmailAndPassword(email, password);

  Future<void> signOut() => _authService.signOut();

  Future<void> sendPasswordResetEmail(String email) => 
      _authService.sendPasswordResetEmail(email);

  Future<void> updateUserProfile({String? displayName, String? photoURL}) =>
      _authService.updateUserProfile(displayName: displayName, photoURL: photoURL);

  Future<void> deleteAccount() => _authService.deleteAccount();

  Future<void> reauthenticateWithCredential(String email, String password) =>
      _authService.reauthenticateWithCredential(email, password);

  Future<UserCredential?> signInAnonymously() => _authService.signInAnonymously();
}