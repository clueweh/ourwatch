import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/registration_codes.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // A blank registration code registers a resident; only the responder code
  // grants responder permissions. Validate it before creating the Auth account.
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    String? registrationCode,
  }) async {
    final String role;
    if (registrationCode == null || registrationCode.isEmpty) {
      role = 'resident';
    } else if (registrationCode == RegistrationCodes.responder) {
      role = 'responder';
    } else {
      return 'Invalid registration code.';
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password provided is too weak.';
        default:
          return e.message ?? 'An unknown registration error occurred.';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Sign in user
  Future<String?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your email and password or register first.';
        case 'invalid-email':
          return 'The email address format is invalid.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user's role from Firestore ("resident" or "responder").
  // Returns "resident" if the profile doc is missing for any reason, so
  // the app fails safe (never accidentally grants responder powers).
  Future<String> getCurrentUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'resident';

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['role'] as String? ?? 'resident';
    } catch (_) {
      return 'resident';
    }
  }

  // Get current user's barangayId, for tagging new reports with their
  // community. Returns null if unavailable (e.g. an older account created
  // before barangay codes existed).
  Future<String?> getCurrentUserBarangayId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['barangayId'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}