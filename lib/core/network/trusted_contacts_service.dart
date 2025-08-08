import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '/core/app_export.dart';

class TrustedContactsService {
  static final TrustedContactsService _instance = TrustedContactsService._internal();
  factory TrustedContactsService() => _instance;
  TrustedContactsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  /// Add a trusted contact
  Future<bool> addTrustedContact({
    required String name,
    required String email,
    required String phone,
    required String relationship,
    bool canAccessLocation = false,
    bool canPerformRemoteActions = false,
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
      }

      final trustedContact = TrustedContact(
        id: _uuid.v4(),
        userId: user.uid, // Store the auth UID for identification
        contactUserId: contactUserId,
        name: name,
        email: email.toLowerCase(),
        phone: phone,
        relationship: relationship,
        isVerified: contactUserId.isNotEmpty, // Auto-verify if user exists
        canAccessLocation: canAccessLocation,
        canPerformRemoteActions: canPerformRemoteActions,
        createdAt: DateTime.now(),
      );

      // Store in findMeTrustedContacts collection (separate top-level collection)
      await _firestore
          .collection('findMeTrustedContacts')
          .doc(trustedContact.id)
          .set(trustedContact.toMap());

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

      final querySnapshot = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TrustedContact.fromSnapshot(doc))
          .toList();
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
    bool canAccessLocation, 
    bool canPerformRemoteActions
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('findMeTrustedContacts')
          .doc(contactId)
          .update({
        'canAccessLocation': canAccessLocation,
        'canPerformRemoteActions': canPerformRemoteActions,
        'lastUpdated': FieldValue.serverTimestamp(),
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

      // Check if user is a verified trusted contact with location access
      final trustedContactQuery = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: personUserId) // Target person's Auth UID
          .where('contactUserId', isEqualTo: user.uid)
          .where('isVerified', isEqualTo: true)
          .get();

      if (trustedContactQuery.docs.isNotEmpty) {
        final contactData = trustedContactQuery.docs.first.data();
        
        // If family sharing is enabled and contact has location permission
        if (personData['familySharingEnabled'] == true && 
            contactData['canAccessLocation'] == true) {
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

      // Get all users where current user is a trusted contact with location access
      final allUsers = await _firestore.collection('users').get();
      
      for (var userDoc in allUsers.docs) {
        final userData = userDoc.data();
        
        // Skip own account (compare userId field, not document ID)
        if (userData['userId'] == user.uid) continue;
        
        // Check if family sharing is enabled for this user
        if (userData['familySharingEnabled'] == true) {
          // Check if current user is a trusted contact with location access
          final trustedContactQuery = await _firestore
              .collection('findMeTrustedContacts')
              .where('userId', isEqualTo: userData['userId']) // Use userId field from user document
              .where('contactUserId', isEqualTo: user.uid)
              .where('isVerified', isEqualTo: true)
              .where('canAccessLocation', isEqualTo: true)
              .get();

          if (trustedContactQuery.docs.isNotEmpty) {
            final contactData = trustedContactQuery.docs.first.data();
            familyMembers.add(TrustedContact.fromMap({
              'id': trustedContactQuery.docs.first.id,
              'userId': userData['userId'], // Use userId field, not document ID
              'contactUserId': user.uid,
              'name': userData['displayName'] ?? userData['name'] ?? contactData['name'] ?? 'Unknown',
              'email': userData['email'] ?? contactData['email'] ?? '',
              'phone': contactData['phone'] ?? '',
              'relationship': contactData['relationship'] ?? 'Family',
              'isVerified': contactData['isVerified'] ?? false,
              'canAccessLocation': contactData['canAccessLocation'] ?? false,
              'canPerformRemoteActions': contactData['canPerformRemoteActions'] ?? false,
              'createdAt': contactData['createdAt'] ?? 0,
            }));
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

      // Get family members where current user is a trusted contact and family sharing is enabled
      final allUsers = await _firestore.collection('users').get();
      
      for (var userDoc in allUsers.docs) {
        final userData = userDoc.data();
        if (userData['familySharingEnabled'] == true) {
          // Check if current user is a trusted contact with location access
          final trustedContactQuery = await _firestore
              .collection('findMeTrustedContacts')
              .where('userId', isEqualTo: userData['userId']) // Use userId field from user document
              .where('contactUserId', isEqualTo: user.uid)
              .where('isVerified', isEqualTo: true)
              .where('canAccessLocation', isEqualTo: true)
              .get();

          if (trustedContactQuery.docs.isNotEmpty) {
            trackableUsers.add({
              'userId': userData['userId'], // Use userId field, not document ID
              'name': userData['name'] ?? 'Unknown',
              'email': userData['email'] ?? '',
              'familySharingEnabled': userData['familySharingEnabled'] ?? false,
              'lastKnownLocation': userData['lastKnownLocation'],
            });
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
