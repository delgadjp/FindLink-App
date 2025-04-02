import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Add this line

  // Login function
  Future<void> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacementNamed(context, '/home'); // Replace with your home route
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user found for that email.')),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong password provided.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
    }
  }

  // Updated Google Sign In
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Add the user to Firestore
      await addUserToFirestore(userCredential.user!, userCredential.user!.email ?? '');
      
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign In failed: $e')),
      );
    }
  }

  // Modified method with custom document ID format
  Future<void> addUserToFirestore(User user, String email) async {
    try {
      // Create a formatted custom ID: USER_YYYYMMDD_XXXXX
      final now = DateTime.now();
      final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

      // Create a unique part based on user info and timestamp
      String uniquePart;
      if (email.isNotEmpty) {
        // Use first 3 chars of email + timestamp segment for uniqueness
        String emailPrefix = email.split('@')[0].substring(0, email.split('@')[0].length > 3 ? 3 : email.split('@')[0].length).toUpperCase();
        uniquePart = "${emailPrefix}${now.millisecondsSinceEpoch.toString().substring(7)}";
      } else {
        // Fallback if no email
        uniquePart = now.millisecondsSinceEpoch.toString().substring(5);
      }

      final customDocId = "USER_${datePart}_$uniquePart";

      // Store user data with the custom document ID
      await _firestore.collection('users').doc(customDocId).set({
        'uid': user.uid, // Store the Firebase Auth UID as a field
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? email.split('@')[0], // Fallback display name
        'photoURL': user.photoURL,
        'role': 'user',
        'documentId': customDocId, // Store the document ID in the document itself
      });

      // Create a record with UID as document ID that points to the main record
      // This allows easy lookup by UID without creating a separate collection
      await _firestore.collection('users').doc(user.uid).set({
        'mainDocumentId': customDocId,
        'isReference': true,
      });

      print('User successfully added to Firestore with custom ID: $customDocId');
    } catch (e) {
      print('Error adding user to Firestore: $e');
      throw e; // Re-throw to handle in the calling function
    }
  }

  // Modified Register function with improved error handling
  Future<void> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Check password strength
    if (password.length < 8 || !password.contains(RegExp(r'[A-Z]')) || 
        !password.contains(RegExp(r'[0-9]')) || !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters with uppercase, number, and special character')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Add user to Firestore
      await addUserToFirestore(userCredential.user!, email);

      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Please login.')),
      );
      
      // Navigate to login page
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The password provided is too weak.')),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The account already exists for that email.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration error: ${e.message}')),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  // Sign out function
  Future<void> signOutUser(BuildContext context) async {
    try {
      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      // Sign out from Firebase
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login'); // Replace with your login route
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out error: $e')),
      );
    }
  }

  // Handle Auth State Changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}