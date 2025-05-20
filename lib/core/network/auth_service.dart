import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Modified Login function to update last sign-in time
  Future<void> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last sign-in time
      if (userCredential.user != null) {
        await updateLastSignIn(userCredential.user!.uid);
      }

      Navigator.pushReplacementNamed(context, '/home'); // Replace with your home route
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login error: ${e.message}';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled. Please contact support.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many login attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  // Modified Google Sign In to update last sign-in time
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

      // Check if user already exists in Firestore before adding
      final bool userExists = await checkIfUserExists(userCredential.user!.uid);

      // Only add the user to Firestore if they don't already exist
      if (!userExists) {
        await addUserToFirestore(userCredential.user!, userCredential.user!.email ?? '');
        
        // Redirect to ID validation for new users
        Navigator.pushReplacementNamed(context, '/id-validation');
      } else {
        // Update last sign-in time for existing users
        await updateLastSignIn(userCredential.user!.uid);
        
        // Redirect straight to home for existing users
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign In failed: $e')),
      );
    }
  }

  // New method to check if a user already exists in Firestore by UID
  Future<bool> checkIfUserExists(String uid) async {
    try {
      // Query Firestore for any documents with the user's UID
      final QuerySnapshot result = await _firestore
          .collection('users') // changed from 'users-app' to 'users'
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      // If we found any documents, the user exists
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Upload ID image to Firebase Storage
  Future<String?> uploadIDImage({
    required String uid, 
    required File idImage,
  }) async {
    try {
      final String imagePath = 'user_ids_app/$uid/id_image.jpg';
      final Reference imageRef = _storage.ref().child(imagePath);
      
      final UploadTask uploadTask = imageRef.putFile(
        idImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final TaskSnapshot snapshot = await uploadTask;
      final String imageURL = await snapshot.ref.getDownloadURL();
      
      return imageURL;
    } catch (e) {
      print('Error uploading ID image: $e');
      throw e;
    }
  }

  // Modified method with custom document ID format and additional user fields
  Future<void> addUserToFirestore(
    User user,
    String email, {
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? phoneNumber,
    String? selectedIDType,
    File? uploadedIDImage,
  }) async {
    try {
      // Create a formatted custom ID: USER_YYYYMMDD_XXX (sequential 3-digit number)
      final now = DateTime.now();
      final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      String emailPrefix = email.split('@')[0].substring(0, email.split('@')[0].length > 3 ? 3 : email.split('@')[0].length).toUpperCase();
      final idPrefix = "USER_${datePart}_${emailPrefix}_";

      // Query Firestore for existing users with the same date and prefix to find the highest number
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('documentId', isGreaterThanOrEqualTo: idPrefix)
          .where('documentId', isLessThan: idPrefix + '999')
          .get();
      int highestNumber = 0;
      for (final doc in querySnapshot.docs) {
        final String docId = doc.id;
        if (docId.startsWith(idPrefix) && docId.length > idPrefix.length) {
          final String seqPart = docId.substring(idPrefix.length);
          final int? seqNum = int.tryParse(seqPart);
          if (seqNum != null && seqNum > highestNumber) {
            highestNumber = seqNum;
          }
        }
      }
      final int nextNumber = highestNumber + 1;
      final String paddedNumber = nextNumber.toString().padLeft(3, '0');
      final customDocId = "${idPrefix}${paddedNumber}";
      
      // Upload ID image if provided
      String? idImageURL;
      if (uploadedIDImage != null) {
        idImageURL = await uploadIDImage(
          uid: user.uid,
          idImage: uploadedIDImage,
        );
      }

      // Store user data with the custom document ID
      await _firestore.collection('users').doc(customDocId).set({ // changed from 'users-app' to 'users'
        'userId': user.uid,
        'email': email,
        'firstName': firstName ?? '',
        'middleName': middleName ?? '',
        'lastName': lastName ?? '',
        'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
        'age': age ?? 0,
        'gender': gender ?? 'Not specified',
        'phoneNumber': phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': firstName != null ? '$firstName ${lastName ?? ''}' : (user.displayName ?? email.split('@')[0]),
        'role': 'user',
        'documentId': customDocId,
        'lastSignIn': FieldValue.serverTimestamp(),
        'privacyPolicyAccepted': false,
        'privacyPolicyAcceptedAt': null,
        'isValidated': false,
        'idSubmitted': uploadedIDImage != null,
        'selectedIDType': selectedIDType ?? '',
        'uploadedIDImageURL': idImageURL ?? '',
      });

      print('User successfully added to Firestore with custom ID: $customDocId');
    } catch (e) {
      print('Error adding user to Firestore: $e');
      throw e; // Re-throw to handle in the calling function
    }
  }

  // Add a method to update the user's last sign-in time
  Future<void> updateLastSignIn(String uid) async {
    try {
      // Find the user document that contains this uid
      QuerySnapshot userQuery = await _firestore
          .collection('users') // changed from 'users-app' to 'users'
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
        print('Updated last sign-in time for user: $uid');
      } else {
        print('User document not found for uid: $uid');
      }
    } catch (e) {
      print('Error updating last sign-in time: $e');
    }
  }

  // Method to get a user's privacy policy acceptance status
  Future<bool> getPrivacyPolicyAcceptance(String uid) async {
    try {
      // Find the user document by uid
      QuerySnapshot userQuery = await _firestore
          .collection('users') // changed from 'users-app' to 'users'
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data() as Map<String, dynamic>;
        return userData['privacyPolicyAccepted'] == true;
      }
      return false;
    } catch (e) {
      print('Error getting privacy policy acceptance status: $e');
      return false;
    }
  }
  
  // Method to update privacy policy acceptance status
  Future<bool> updatePrivacyPolicyAcceptance(String uid, bool accepted) async {
    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users') // changed from 'users-app' to 'users'
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'privacyPolicyAccepted': accepted,
          'privacyPolicyAcceptedAt': accepted ? FieldValue.serverTimestamp() : null,
        });
        print('Updated privacy policy acceptance for user: $uid to $accepted');
        return true;
      } else {
        print('User document not found for uid: $uid');
        return false;
      }
    } catch (e) {
      print('Error updating privacy policy acceptance: $e');
      return false;
    }
  }

  // Modified Register function with improved error handling and additional user fields
  Future<void> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
    required BuildContext context,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? phoneNumber,
    String? selectedIDType,
    File? uploadedIDImage,
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

      // Add user to Firestore with additional profile information
      await addUserToFirestore(
        userCredential.user!, 
        email,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        selectedIDType: selectedIDType,
        uploadedIDImage: uploadedIDImage,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful! Please complete ID verification.')),
      );

      // Navigate to ID validation page if ID image wasn't provided during registration
      if (uploadedIDImage == null) {
        Navigator.pushReplacementNamed(context, '/id-validation');
      } else {
        // Navigate directly to home if ID was already provided
        Navigator.pushReplacementNamed(context, '/home');
      }
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

  // Method to update user's ID verification status
  Future<void> updateIDVerificationStatus({
    required String uid,
    required bool submitted,
    bool? verified,
    String? idType,
    File? uploadedIDImage,
  }) async {
    try {
      // Find the user document
      QuerySnapshot userQuery = await _firestore
          .collection('users') // changed from 'users-app' to 'users'
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        Map<String, dynamic> updateData = {
          'idSubmitted': submitted,
        };

        // Upload ID image if provided
        if (uploadedIDImage != null) {
          String? idImageURL = await uploadIDImage(
            uid: uid,
            idImage: uploadedIDImage,
          );
          
          if (idImageURL != null) {
            updateData['uploadedIDImageURL'] = idImageURL;
          }
        }

        if (verified != null) updateData['isValidated'] = verified;
        if (idType != null) updateData['idType'] = idType;
        
        if (submitted) {
          updateData['idSubmittedAt'] = FieldValue.serverTimestamp();
        }

        await userQuery.docs.first.reference.update(updateData);
      }
    } catch (e) {
      print('Error updating ID verification status: $e');
      throw e;
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

  // Method to get compliance acceptance for a specific screen
  Future<bool> getScreenComplianceAccepted(String uid, String screenKey) async {
    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users') // changed from 'users-app' to 'users'
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data() as Map<String, dynamic>;
        return userData[screenKey] == true;
      }
      return false;
    } catch (e) {
      print('Error getting compliance acceptance for $screenKey: $e');
      return false;
    }
  }

  // Method to update compliance acceptance for a specific screen
  Future<void> updateScreenComplianceAccepted(String uid, String screenKey, bool accepted) async {
    try {
      QuerySnapshot userQuery = await _firestore
          .collection('users') // changed from 'users-app' to 'users'
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          screenKey: accepted,
          screenKey + 'At': accepted ? FieldValue.serverTimestamp() : null,
        });
      }
    } catch (e) {
      print('Error updating compliance acceptance for $screenKey: $e');
    }
  }
}