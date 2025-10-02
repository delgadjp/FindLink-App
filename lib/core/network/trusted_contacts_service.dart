import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/app_export.dart';

/// Result class for trusted contact operations
class TrustedContactResult {
  final bool success;
  final String? errorMessage;
  
  TrustedContactResult({required this.success, this.errorMessage});
}

class TrustedContactsService {
  static final TrustedContactsService _instance = TrustedContactsService._internal();
  factory TrustedContactsService() => _instance;
  TrustedContactsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  /// Generate a formal document ID format for trusted contacts: TC_YYYYMMDD_XXX_HHMMSS (where XXX is user prefix and HHMMSS is time)
  Future<String> _generateTrustedContactDocumentId(String userId) async {
    try {
      // Find the user document to get their custom document ID format
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final userDocId = userQuery.docs.first.id; // e.g., "USER_20250808_HOM_001"
        
        // Extract the prefix part (e.g., "HOM" from "USER_20250808_HOM_001")
        final parts = userDocId.split('_');
        final userPrefix = parts.length >= 3 ? parts[2] : 'USR';
        
        // Create trusted contact document ID with current date and time
        final now = DateTime.now();
        final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
        final timePart = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
        
        return "TC_${datePart}_${userPrefix}_${timePart}";
      } else {
        // Fallback to using UUID if user document not found
        return _uuid.v4();
      }
    } catch (e) {
      print('Error generating trusted contact document ID: $e');
      // Fallback to UUID
      return _uuid.v4();
    }
  }

  /// Add a trusted contact - returns a result with success status and error message
  Future<TrustedContactResult> addTrustedContactWithValidation({
    required String name,
    required String email,
    required String phone,
    required String relationship,
    bool canAccessLocation = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return TrustedContactResult(success: false, errorMessage: 'User not authenticated');
      }

      // Find current user for validation (we still need to ensure user exists)
      final currentUserQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (currentUserQuery.docs.isEmpty) {
        print('Current user document not found');
        return TrustedContactResult(success: false, errorMessage: 'Current user not found in database');
      }

      // Check if contact user exists and get their userId (auth UID)
      final contactUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      String contactUserId = '';
      if (contactUserQuery.docs.isNotEmpty) {
        final contactData = contactUserQuery.docs.first.data();
        contactUserId = contactData['userId'] ?? ''; // Get the auth UID from userId field
        
        // CRITICAL VALIDATION: Ensure we're not adding current user as their own trusted contact
        if (contactUserId == user.uid) {
          print('Error: Cannot add yourself as a trusted contact');
          return TrustedContactResult(success: false, errorMessage: 'You cannot add yourself as a trusted contact');
        }
        
        print('Found contact user: ${contactData['name'] ?? 'Unknown'} with userId: $contactUserId');
      } else {
        // VALIDATION: Contact user does not exist in Firebase
        print('Contact user not found for email: $email');
        return TrustedContactResult(success: false, errorMessage: 'No FindLink user found with this email address. Please ensure the person has a FindLink account.');
      }

      // Additional validation: Ensure contactUserId is not empty
      if (contactUserId.isEmpty) {
        print('Error: Invalid contact user data - missing userId');
        return TrustedContactResult(success: false, errorMessage: 'Invalid user data found. Please try again.');
      }

      // Check if this trusted contact already exists
      final existingContactQuery = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid)
          .where('contactUserId', isEqualTo: contactUserId)
          .get();

      if (existingContactQuery.docs.isNotEmpty) {
        return TrustedContactResult(success: false, errorMessage: 'This person is already in your trusted contacts list');
      }

      // Proceed with adding the contact
      final contactDocId = await _generateTrustedContactDocumentId(user.uid);

      final trustedContact = TrustedContact(
        id: contactDocId, // Use the custom document ID
        userId: user.uid, // Store the auth UID for identification
        contactUserId: contactUserId,
        name: name,
        email: email.toLowerCase(),
        phone: phone,
        relationship: relationship,
        isVerified: true, // Auto-verify since we confirmed user exists
        canAccessLocation: canAccessLocation,
        createdAt: DateTime.now(), // This will be converted to Firestore Timestamp
      );

      // Store in findMeTrustedContacts collection with custom document ID
      final contactData = trustedContact.toMap();
      // Override createdAt with server timestamp for consistency
      contactData['createdAt'] = FieldValue.serverTimestamp();
      
      print('Storing trusted contact:');
      print('  Document ID: $contactDocId');
      print('  UserId (owner): ${user.uid}');
      print('  ContactUserId (target): $contactUserId');
      print('  Name: $name');
      print('  Email: $email');
      print('  Can Access Location: $canAccessLocation');
      
      await _firestore
          .collection('findMeTrustedContacts')
          .doc(contactDocId)
          .set(contactData);

      print('Trusted contact stored successfully');
      return TrustedContactResult(success: true, errorMessage: null);
    } catch (e) {
      print('Error adding trusted contact: $e');
      return TrustedContactResult(success: false, errorMessage: 'An error occurred while adding the trusted contact. Please try again.');
    }
  }

  /// Add a trusted contact (backward compatibility)
  Future<bool> addTrustedContact({
    required String name,
    required String email,
    required String phone,
    required String relationship,
    bool canAccessLocation = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Find current user for validation (we still need to ensure user exists)
      final currentUserQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (currentUserQuery.docs.isEmpty) {
        print('Current user document not found');
        return false;
      }

      // Check if contact user exists and get their userId (auth UID)
      final contactUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      String contactUserId = '';
      if (contactUserQuery.docs.isNotEmpty) {
        final contactData = contactUserQuery.docs.first.data();
        contactUserId = contactData['userId'] ?? ''; // Get the auth UID from userId field
        
        // CRITICAL VALIDATION: Ensure we're not adding current user as their own trusted contact
        if (contactUserId == user.uid) {
          print('Error: Cannot add yourself as a trusted contact');
          return false;
        }
        
        print('Found contact user: ${contactData['name'] ?? 'Unknown'} with userId: $contactUserId');
      } else {
        // VALIDATION: Contact user does not exist in Firebase
        print('Contact user not found for email: $email');
        return false; // Fail the operation if user doesn't exist
      }

      // Additional validation: Ensure contactUserId is not empty
      if (contactUserId.isEmpty) {
        print('Error: Invalid contact user data - missing userId');
        return false;
      }

      // Generate custom document ID
      final contactDocId = await _generateTrustedContactDocumentId(user.uid);

      final trustedContact = TrustedContact(
        id: contactDocId, // Use the custom document ID
        userId: user.uid, // Store the auth UID for identification
        contactUserId: contactUserId,
        name: name,
        email: email.toLowerCase(),
        phone: phone,
        relationship: relationship,
        isVerified: true, // Auto-verify since we confirmed user exists
        canAccessLocation: canAccessLocation,
        createdAt: DateTime.now(), // This will be converted to Firestore Timestamp
      );

      // Store in findMeTrustedContacts collection with custom document ID
      final contactData = trustedContact.toMap();
      // Override createdAt with server timestamp for consistency
      contactData['createdAt'] = FieldValue.serverTimestamp();
      
      print('Storing trusted contact:');
      print('  Document ID: $contactDocId');
      print('  UserId (owner): ${user.uid}');
      print('  ContactUserId (target): $contactUserId');
      print('  Name: $name');
      print('  Email: $email');
      print('  Can Access Location: $canAccessLocation');
      
      await _firestore
          .collection('findMeTrustedContacts')
          .doc(contactDocId)
          .set(contactData);

      print('Trusted contact stored successfully');
      return true;
    } catch (e) {
      print('Error adding trusted contact: $e');
      return false;
    }
  }

  /// Get trusted contacts for current user
  Future<List<TrustedContact>> getTrustedContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Use simpler query without orderBy to avoid index requirement
      final querySnapshot = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid)
          .get();

      final contacts = querySnapshot.docs
          .map((doc) => TrustedContact.fromSnapshot(doc))
          .toList();

      // Sort by createdAt in the app (newest first)
      contacts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return contacts;
    } catch (e) {
      print('Error getting trusted contacts: $e');
      return [];
    }
  }

  /// Remove a trusted contact
  Future<bool> removeTrustedContact(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('findMeTrustedContacts')
          .doc(contactId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing trusted contact: $e');
      return false;
    }
  }

  /// Verify a trusted contact (admin function or OTP verification)
  Future<bool> verifyTrustedContact(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('findMeTrustedContacts')
          .doc(contactId)
          .update({'isVerified': true});

      return true;
    } catch (e) {
      print('Error verifying trusted contact: $e');
      return false;
    }
  }

  /// Update trusted contact permissions
  Future<bool> updateTrustedContactPermissions(
    String contactId, 
    bool canAccessLocation
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('findMeTrustedContacts')
          .doc(contactId)
          .update({
        'canAccessLocation': canAccessLocation,
        'lastUpdated': FieldValue.serverTimestamp(), // Use Firestore server timestamp
      });

      return true;
    } catch (e) {
      print('Error updating trusted contact permissions: $e');
      return false;
    }
  }

  /// Check if current user can access location data for a person (including family sharing)
  Future<bool> canAccessLocationData(String personUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Find current user's custom document ID
      final currentUserQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (currentUserQuery.docs.isEmpty) return false;

      final currentUserData = currentUserQuery.docs.first.data();
      
      // Check if user is admin
      if (currentUserData['role'] == 'admin') {
        return true;
      }

      // Check if this is the person's own data
      if (user.uid == personUserId) {
        return true;
      }

      // Find the person's document by their userId
      final personQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: personUserId)
          .limit(1)
          .get();
      
      if (personQuery.docs.isEmpty) return false;

      final personData = personQuery.docs.first.data();

      // Check if current user has this person as a trusted contact with location access
      // AND the person has family sharing enabled
      final trustedContactQuery = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid) // Current user owns this relationship
          .where('contactUserId', isEqualTo: personUserId) // Target person is the contact
          .where('isVerified', isEqualTo: true)
          .where('canAccessLocation', isEqualTo: true)
          .get();

      if (trustedContactQuery.docs.isNotEmpty) {
        // If current user has the person as trusted contact with location access,
        // and the person has FindMe enabled
        if (personData['findMeEnabled'] == true) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking access permissions: $e');
      return false;
    }
  }

  /// Get users that current user can track including family sharing
  Future<List<TrustedContact>> getFamilyMembers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      List<TrustedContact> familyMembers = [];

      // First, get all trusted contacts where current user is the owner (people who trust the current user)
      final myTrustedContacts = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid)
          .where('isVerified', isEqualTo: true)
          .where('canAccessLocation', isEqualTo: true)
          .get();

      // For each trusted contact, check if they have family sharing enabled
      for (var contactDoc in myTrustedContacts.docs) {
        final contactData = contactDoc.data();
        final contactUserId = contactData['contactUserId'];
        
        if (contactUserId != null && contactUserId.isNotEmpty) {
          // Find the user document for this trusted contact
          final userQuery = await _firestore
              .collection('users')
              .where('userId', isEqualTo: contactUserId)
              .limit(1)
              .get();
          
          if (userQuery.docs.isNotEmpty) {
            final userData = userQuery.docs.first.data();
            
            // Check if this user has FindMe enabled
            if (userData['findMeEnabled'] == true) {
              familyMembers.add(TrustedContact.fromMap({
                'id': contactDoc.id,
                'userId': user.uid, // Current user is the owner of this trusted contact relationship
                'contactUserId': contactUserId,
                'name': userData['displayName'] ?? userData['name'] ?? contactData['name'] ?? 'Unknown',
                'email': userData['email'] ?? contactData['email'] ?? '',
                'phone': contactData['phone'] ?? '',
                'relationship': contactData['relationship'] ?? 'Family',
                'isVerified': contactData['isVerified'] ?? false,
                'canAccessLocation': contactData['canAccessLocation'] ?? false,
                'createdAt': contactData['createdAt'] ?? 0,
              }));
            }
          }
        }
      }

      return familyMembers;
    } catch (e) {
      print('Error getting family members: $e');
      return [];
    }
  }

  /// Get users that current user can track (family members with sharing enabled)
  Future<List<Map<String, dynamic>>> getTrackableUsers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      List<Map<String, dynamic>> trackableUsers = [];

      // Get all trusted contacts where current user is the owner (people who trust the current user)
      final myTrustedContacts = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid)
          .where('isVerified', isEqualTo: true)
          .where('canAccessLocation', isEqualTo: true)
          .get();

      // For each trusted contact, check if they have family sharing enabled
      for (var contactDoc in myTrustedContacts.docs) {
        final contactData = contactDoc.data();
        final contactUserId = contactData['contactUserId'];
        
        if (contactUserId != null && contactUserId.isNotEmpty) {
          // Find the user document for this trusted contact
          final userQuery = await _firestore
              .collection('users')
              .where('userId', isEqualTo: contactUserId)
              .limit(1)
              .get();
          
          if (userQuery.docs.isNotEmpty) {
            final userData = userQuery.docs.first.data();
            
            // Check if this user has FindMe enabled
            if (userData['findMeEnabled'] == true) {
              trackableUsers.add({
                'userId': contactUserId, // Use the contact's userId
                'name': userData['displayName'] ?? userData['name'] ?? contactData['name'] ?? 'Unknown',
                'email': userData['email'] ?? contactData['email'] ?? '',
                'findMeEnabled': userData['findMeEnabled'] ?? false,
                'lastKnownLocation': userData['lastKnownLocation'],
              });
            }
          }
        }
      }

      return trackableUsers;
    } catch (e) {
      print('Error getting trackable users: $e');
      return [];
    }
  }
}
