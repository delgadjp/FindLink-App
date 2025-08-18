import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '/core/app_export.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AutoLocationService _autoLocationService = AutoLocationService();

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
        
        // Auto-initialize location service if Find Me is enabled
        _autoLocationService.autoInitializeLocationService();
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

  // Upload ID image to Firebase Storage
  Future<String?> uploadIDImage({
    required String uid, 
    required File idImage,
  }) async {
    try {
      // Ensure user is authenticated before attempting upload
      if (_auth.currentUser == null) {
        await Future.delayed(Duration(seconds: 1));
        if (_auth.currentUser == null) {
          print('Error: User not authenticated during ID upload');
          throw FirebaseException(
            plugin: 'firebase_storage',
            message: 'User must be authenticated to upload ID images',
          );
        }
      }
      
      final String imagePath = 'user_ids_app/$uid/id_image.jpg';
      final Reference imageRef = _storage.ref().child(imagePath);
      
      final UploadTask uploadTask = imageRef.putFile(
        idImage,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Add error handling for the upload task
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      }, onError: (e) {
        print('Upload task error: $e');
      });
      
      final TaskSnapshot snapshot = await uploadTask;
      final String imageURL = await snapshot.ref.getDownloadURL();
      
      print('Successfully uploaded ID image to: $imagePath');
      return imageURL;
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized') {
        print('Error uploading ID image: Unauthorized access. Check Firebase Storage rules.');
        // You might want to show a more user-friendly error to the user
      } else {
        print('Firebase error uploading ID image: ${e.code} - ${e.message}');
      }
      throw e;
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
    DateTime? birthday,
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
      }      // Store user data with the custom document ID
      await _firestore.collection('users').doc(customDocId).set({
        'userId': user.uid,
        'email': email,
        'firstName': firstName ?? '',
        'middleName': middleName ?? '',
        'lastName': lastName ?? '',
        'birthday': birthday != null ? Timestamp.fromDate(birthday) : null,
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
          .collection('users')
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
          .collection('users')
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
          .collection('users')
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
    DateTime? birthday,
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
      );      // Add user to Firestore with additional profile information
      await addUserToFirestore(
        userCredential.user!, 
        email,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        birthday: birthday,
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
          .collection('users')
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
      // Reset auto location service state
      _autoLocationService.reset();
      
      // Sign out from Firebase only
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
          .collection('users')
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
          .collection('users')
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
    // Get user's cases from multiple collections
  Future<List<Map<String, dynamic>>> getUserCasesFromMultipleCollections() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final List<Map<String, dynamic>> allCases = [];
      
      // 1. Fetch from incidents collection
      final QuerySnapshot incidentsQuery = await _firestore
          .collection('incidents')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in incidentsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final incidentDetails = data['incidentDetails'] ?? {};
        final status = data['status'] ?? 'Reported';
        
        // Skip resolved cases as they are archived
        if (status == 'Resolved Case' || status == 'Resolved') {
          continue;
        }
        
        allCases.add({
          'id': doc.id,
          'caseNumber': incidentDetails['incidentId'] ?? doc.id,
          'name': _extractCaseName(data),
          'dateCreated': _formatTimestamp(incidentDetails['createdAt']),
          'status': status,
          'source': 'incidents',
          'pdfUrl': data['pdfUrl'],
          'rawData': data,
        });
      }
      
      // 2. Fetch from missingPersons collection
      final QuerySnapshot missingPersonsQuery = await _firestore
          .collection('missingPersons')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in missingPersonsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Reported';
        
        // Skip resolved cases as they are archived
        if (status == 'Resolved Case' || status == 'Resolved') {
          continue;
        }
        
        allCases.add({
          'id': doc.id,
          'caseNumber': data['case_id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown Person',
          'dateCreated': _formatTimestamp(data['datetime_reported']),
          'status': status,
          'source': 'missingPersons',
          'pdfUrl': data['pdfUrl'],
          'rawData': data,
        });
      }
      
      // Note: We don't fetch from archivedCases collection for active case tracking
      // as these are resolved cases that should not appear in the user's active case list
      
      // Sort all cases by date (newest first)
      allCases.sort((a, b) {
        final DateTime dateA = _parseTimestamp(a['dateCreated']);
        final DateTime dateB = _parseTimestamp(b['dateCreated']);
        return dateB.compareTo(dateA);
      });
      
      return allCases;
    } catch (e) {
      print('Error fetching user cases from multiple collections: $e');
      return [];
    }
  }
  
  // Helper method to extract name from different structures
  String _extractCaseName(Map<String, dynamic> data) {
    if (data['itemC'] != null) {
      final itemC = data['itemC'];
      return ((itemC['firstName'] ?? '') +
          (itemC['middleName'] != null ? ' ${itemC['middleName']}' : '') +
          (itemC['familyName'] != null ? ' ${itemC['familyName']}' : '')).trim();
    } else if (data['name'] != null) {
      return data['name'];
    } else {
      return 'Unknown Person';
    }
  }
  
  // Helper method to format timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is Map && timestamp['seconds'] != null) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '';
      }
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return '';
    }
  }
  
  // Helper method to parse date string or timestamp to DateTime
  DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        return DateFormat('dd MMM yyyy').parse(timestamp);
      } else if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is Map && timestamp['seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
  
  // Generate progress steps based on status (for case tracking)
  List<Map<String, String>> generateProgressSteps(String currentStatus) {
    // Map to convert status to step number (1-indexed)
    final Map<String, int> statusToStep = {
      'Reported': 1,
      'Under Review': 2,
      'Case Verified': 3,
      'In Progress': 4,
      'Resolved Case': 5,
      'Unresolved Case': 6,
      'Resolved': 5, // Map 'Resolved' to 'Resolved Case' step
    };
    
    final List<Map<String, String>> caseProgressSteps = [
      {'stage': 'Reported', 'status': 'Pending'},
      {'stage': 'Under Review', 'status': 'Pending'},
      {'stage': 'Case Verified', 'status': 'Pending'},
      {'stage': 'In Progress', 'status': 'Pending'},
      {'stage': 'Resolved Case', 'status': 'Pending'},
      {'stage': 'Unresolved Case', 'status': 'Pending'},
    ];
    
    final int currentStep = statusToStep[currentStatus] ?? 1;
    
    return caseProgressSteps.map((step) {
      final int stepNumber = caseProgressSteps.indexOf(step) + 1;
      String status;
      
      if (stepNumber < currentStep) {
        status = 'Completed';
      } else if (stepNumber == currentStep) {
        status = 'In Progress';
      } else {
        status = 'Pending';
      }
      
      return {
        'stage': step['stage'] ?? '',
        'status': status,
      };
    }).toList();
  }
}